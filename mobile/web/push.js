// Тънък JS слой за Web Push - извикван от Dart през js interop (виж
// mobile/lib/core/services/push_notification_service.dart). Държим цялата
// ServiceWorker/PushManager/base64 логика тук в обикновен JS вместо dart:js_interop
// ceremony за всяко извикване - Dart страната само вика window.LokumPush.subscribe(...)
// и получава обикновен JSON-съвместим обект/null обратно.
window.LokumPush = (() => {
  function isSupported() {
    return "serviceWorker" in navigator && "PushManager" in window;
  }

  // Стандартен begin snippet - VAPID публичният ключ идва base64url от
  // сървъра (виж /api/push/config), а PushManager.subscribe() очаква
  // суров Uint8Array.
  function urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
    const rawData = atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; i++) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  // Изкуствен scope, който НИКОГА не се навигира реално - push-sw.js не
  // бива да контролира главната страница (виж коментара в push-sw.js за
  // защо). navigator.serviceWorker.ready НЕ е ползваем тук, защото той
  // резолва за worker-а, който КОНТРОЛИРА текущата страница (Flutter-ският),
  // не за нашия - затова чакаме директно registration обекта.
  const PUSH_SCOPE = "/push-scope/";

  async function subscribe(vapidPublicKeyB64) {
    if (!isSupported()) return null;

    const permission = await Notification.requestPermission();
    if (permission !== "granted") return null;

    const registration = await navigator.serviceWorker.register("push-sw.js", {
      scope: PUSH_SCOPE,
    });

    const existing = await registration.pushManager.getSubscription();
    const subscription =
      existing ||
      (await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidPublicKeyB64),
      }));

    // JSON string, не суров обект - по-прост мост към Dart (виж
    // push_notification_service.dart), без нужда от типизиран js_interop
    // за формата на PushSubscription.
    return JSON.stringify(subscription);
  }

  async function unsubscribe() {
    if (!isSupported()) return null;
    const registration = await navigator.serviceWorker.getRegistration(PUSH_SCOPE);
    if (!registration) return null;
    const subscription = await registration.pushManager.getSubscription();
    if (!subscription) return null;
    const endpoint = subscription.endpoint;
    await subscription.unsubscribe();
    return endpoint;
  }

  return { isSupported, subscribe, unsubscribe };
})();
