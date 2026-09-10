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
// При старт на всяка реплика (lokum-server/lokum-server-2 имат СВОЙ отделен
// Node процес) - за да се вижда веднага в docker compose logs, ако само
// едната реплика има/няма VAPID ключовете заредени.
console.log(`[webPush] configured=${configured} (hostname=${process.env.HOSTNAME || "?"})`);

// Общ helper за notifyStaff/notifyKitchen по-долу - известява ВСИЧКИ активни
// абонаменти на дадена роля (може да са няколко телефона едновременно,
// логнати със същия staff/kitchen акаунт - виж PushSubscription в schema.prisma).
async function notifyRole(role, title, body) {
    // Без VAPID ключове (все още негенерирани - виж .env.example) push-ът
    // просто мълчи, не хвърля - не бива да чупи самото създаване на поръчка.
    if (!configured) return;

    const subscriptions = await prisma.pushSubscription.findMany({
        where: { role }
    });
    console.log(
        `[webPush] notify ${role}: ${subscriptions.length} subscription(s)`
    );
    if (subscriptions.length === 0) return;

    const payload = JSON.stringify({ title, body });

    await Promise.all(
        subscriptions.map(async (sub) => {
            try {
                await webpush.sendNotification(
                    { endpoint: sub.endpoint, keys: sub.keys },
                    payload
                );
                console.log(
                    `[webPush] sent OK to ${sub.endpoint.slice(0, 60)}...`
                );
            } catch (err) {
                // Логваме ВИНАГИ - до сега мълчеше и на всяка грешка, различна
                // от 404/410, което правеше проблема невидим (виж разговора
                // за нотификациите, спрели без видима причина).
                console.error(
                    `[webPush] send failed (${err.statusCode ?? "?"}) to ${sub.endpoint.slice(0, 60)}...:`,
                    err.body || err.message || err
                );
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

// Извиква се от createOrder() в tableSession.js - единствената точка, през
// която минава ВСЯКА нова поръчка, независимо дали идва от бележника на
// персонала или директно от клиента (виж routes/customerOrders.js).
async function notifyStaff({ tableNumber }) {
    await notifyRole("staff", "Нова поръчка!", `Маса ${tableNumber}`);
}

// Само когато поръчката съдържа поне един артикул от кухнята (виж createOrder
// в tableSession.js) - иначе готвачката получава известие за поръчка, която
// изобщо не минава през кухненското табло (напр. само напитки).
async function notifyKitchen({ tableNumber }) {
    await notifyRole("kitchen", "Нова поръчка за кухнята!", `Маса ${tableNumber}`);
}

module.exports = { notifyStaff, notifyKitchen, pushConfigured: configured };
