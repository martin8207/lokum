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

// Известява ВСИЧКИ активни staff абонаменти (може да са няколко телефона
// едновременно, логнати със същия staff акаунт - виж PushSubscription в
// schema.prisma) за нова поръчка. Извиква се от createOrder() в
// tableSession.js - единствената точка, през която минава ВСЯКА нова
// поръчка, независимо дали идва от бележника на персонала или директно от
// клиента (виж routes/customerOrders.js). Само staff, нарочно не и kitchen -
// кухнята вече вижда новите артикули в реално време на собствения си екран.
async function notifyStaff({ tableNumber }) {
    // Без VAPID ключове (все още негенерирани - виж .env.example) push-ът
    // просто мълчи, не хвърля - не бива да чупи самото създаване на поръчка.
    if (!configured) return;

    const subscriptions = await prisma.pushSubscription.findMany({
        where: { role: "staff" }
    });
    console.log(
        `[webPush] notifyStaff: table ${tableNumber}, ${subscriptions.length} staff subscription(s)`
    );
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

module.exports = { notifyStaff, pushConfigured: configured };
