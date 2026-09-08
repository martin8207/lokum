// Отделен service worker, САМО за push нотификации - регистриран от push.js
// с изкуствен scope ("/push-scope/", виж там), който никога не се навигира
// реално. Затова НЕ контролира главната страница и не пипа fetch/кеширане -
// Flutter-ският собствен flutter_service_worker.js върши това, необезпокоен.
// Push доставката работи независимо от "контролира ли текущата страница":
// браузърът буди точно тази регистрация, докато е активна, дори табът/
// телефонът да е заключен (виж lokum-push-notifications-task.md).

self.addEventListener("push", (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch {
    data = { title: "Lokum", body: event.data ? event.data.text() : "" };
  }

  const title = data.title || "Lokum";
  const options = {
    body: data.body || "",
    icon: "icons/Icon-192.png",
    badge: "icons/Icon-192.png",
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

// Тап върху известието - фокусира вече отворен таб с апа, ако има такъв,
// иначе отваря нов на бележника. clients.openWindow изисква абсолютен или
// root-relative път, не относителен на scope-а на този SW.
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ("focus" in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow("/");
    })
  );
});
