const express = require("express");

const router = express.Router();

// Публичен - VAPID публичният ключ не е тайна (върви във всеки push
// subscription по дизайн на протокола), само частният пази в .env. Frontend-ът
// го чете оттук вместо да го харкодва в Dart кода, за да не зависи build-ът
// от кой VAPID keypair е активен в дадената среда (виж lib/webPush.js).
router.get("/", (req, res) => {
    res.json({ publicKey: process.env.VAPID_PUBLIC_KEY || null });
});

module.exports = router;
