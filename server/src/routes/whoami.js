const os = require("os");

const express = require("express");

const router = express.Router();

// Диагностичен, публичен route - за проверка че nginx реално редува
// lokum-server/lokum-server-2 (виж upstream api_production в
// mobile/nginx.conf.template). process.env.HOSTNAME пада на случаен
// container id, ако docker-compose.yml няма изричен "hostname:" за услугата
// - виж коментара там.
router.get("/", (req, res) => {
    res.json({ hostname: process.env.HOSTNAME || os.hostname() });
});

module.exports = router;
