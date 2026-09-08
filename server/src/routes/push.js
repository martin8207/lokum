const express = require("express");

const prisma = require("../db");

// Factory, не единичен router - staff и kitchen се абонират през ЕДИН и
// същ handler, но с различен role, определен от КОЙ auth middleware е
// минала заявката (виж index.js) - самите routes/тела не разкриват ролята,
// за да не разчитаме на клиента да я каже коректно.
function createPushRouter(role) {
    const router = express.Router();

    // body: { endpoint, keys: { p256dh, auth } } - точно обектът, който
    // PushManager.subscribe() връща в браузъра (виж web/push.js).
    router.post("/subscribe", async (req, res) => {
        const { endpoint, keys } = req.body || {};
        if (typeof endpoint !== "string" || !keys || typeof keys !== "object") {
            return res.status(400).json({ error: "invalid_subscription" });
        }

        await prisma.pushSubscription.upsert({
            where: { endpoint },
            update: { role, keys },
            create: { endpoint, role, keys }
        });

        res.status(201).json({ ok: true });
    });

    // Извиква се при логаут/деактивиране на известията от самия екран -
    // без това, изтрит от браузъра абонамент виси в базата до следващия
    // неуспешен push (виж webPush.js), който го чисти лениво.
    router.delete("/subscribe", async (req, res) => {
        const { endpoint } = req.body || {};
        if (typeof endpoint !== "string") {
            return res.status(400).json({ error: "invalid_endpoint" });
        }
        await prisma.pushSubscription
            .delete({ where: { endpoint } })
            .catch(() => {});
        res.json({ ok: true });
    });

    return router;
}

module.exports = createPushRouter;
