const webpush = require("web-push");

const prisma = require("../db");

const configured = Boolean(
    process.env.VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY
);

if (configured) {
    webpush.setVapidDetails(
        "mailto:lokum@example.com",
        process.env.VAPID_PUBLIC_KEY,
        process.env.VAPID_PRIVATE_KEY
    );
}

// Известява ВСИЧКИ активни staff абонаменти (може да са няколко телефона
// едновременно, логнати със същия staff акаунт - виж PushSubscription в
// schema.prisma) за нова поръчка. Извиква се от createOrder() в
// tableSession.js - единствената точка, през която минава ВСЯКА нова
// поръчка, независимо дали идва от бележника на персонала или директно от
// клиента (виж routes/customerOrders.js).
async function notifyStaff({ tableNumber }) {
    // Без VAPID ключове (все още негенерирани - виж .env.example) push-ът
    // просто мълчи, не хвърля - не бива да чупи самото създаване на поръчка.
    if (!configured) return;

    const subscriptions = await prisma.pushSubscription.findMany({
        where: { role: "staff" }
    });
    if (subscriptions.length === 0) return;

    const payload = JSON.stringify({
        title: "Нова поръчка!",
        body: `Маса ${tableNumber}`
    });

    await Promise.all(
        subscriptions.map(async (sub) => {
            try {
                await webpush.sendNotification(
                    { endpoint: sub.endpoint, keys: sub.keys },
                    payload
                );
            } catch (err) {
                // 404/410 = браузърът е прекратил абонамента (десинсталирано,
                // изтекло, потребителят е забранил известията) - изтриваме го,
                // за да не се опитваме отново на всяка следваща поръчка.
                if (err.statusCode === 404 || err.statusCode === 410) {
                    await prisma.pushSubscription
                        .delete({ where: { endpoint: sub.endpoint } })
                        .catch(() => {});
                }
            }
        })
    );
}

module.exports = { notifyStaff, pushConfigured: configured };
