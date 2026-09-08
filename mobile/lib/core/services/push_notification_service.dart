/// Свързва `window.LokumPush` (виж web/push.js + web/push-sw.js) с бекенда
/// - вика се веднъж след успешен login (виж staff_login_page.dart). Тих
/// fail навсякъде тук е нарочно: липсваща поддръжка на браузъра, отказано
/// разрешение или още негенерирани VAPID ключове (виж .env.example) НЕ
/// бива да пречат на нормалната работа с бележника/кухнята - push-ът е
/// добавка отгоре, не изискване. Само test средата (lokum-server-v2) има
/// VAPID ключове засега.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'staff_api.dart';

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  Future<void> trySubscribe() async {
    if (!kIsWeb) return;
    try {
      final lokumPush = globalContext.getProperty<JSObject?>('LokumPush'.toJS);
      if (lokumPush == null) return;

      final supported = lokumPush.callMethod<JSBoolean>('isSupported'.toJS);
      if (!supported.toDart) return;

      final publicKey = await StaffApi.instance.fetchPushPublicKey();
      if (publicKey == null) return;

      final promise = lokumPush.callMethod<JSPromise<JSAny?>>(
        'subscribe'.toJS,
        publicKey.toJS,
      );
      final result = await promise.toDart;
      if (result == null) return; // разрешението е отказано в браузъра

      final subscriptionJson =
          jsonDecode((result as JSString).toDart) as Map<String, dynamic>;
      await StaffApi.instance.registerPushSubscription(subscriptionJson);
    } catch (_) {
      // Виж бележката горе - push-ът е best-effort добавка.
    }
  }
}
