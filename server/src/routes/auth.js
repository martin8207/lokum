const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const router = express.Router();

// POST /api/auth/login - споделена парола за целия персонал (не индивидуален
// login, виж lokum-version2-planning.md - двамата с колежката работят на
// обща сметка). Успешен вход връща JWT, който бележникът праща на всяка
// следваща заявка (виж requireStaffAuth).
router.post("/login", async (req, res) => {
    const { password } = req.body;
    if (typeof password !== "string" || password.length === 0) {
        return res.status(400).json({ error: "missing_password" });
    }

    const matches = await bcrypt.compare(
        password,
        process.env.STAFF_PASSWORD_HASH || ""
    );
    if (!matches) {
        return res.status(401).json({ error: "invalid_password" });
    }

    const token = jwt.sign({ role: "staff" }, process.env.JWT_SECRET, {
        expiresIn: "30d"
    });
    res.json({ token });
});

// POST /api/auth/kitchen-login - отделна споделена парола за кухнята - вижда
// само какви ястия влизат по маси (routes/kitchen.js), не бележника/сметките.
router.post("/kitchen-login", async (req, res) => {
    const { password } = req.body;
    if (typeof password !== "string" || password.length === 0) {
        return res.status(400).json({ error: "missing_password" });
    }

    const matches = await bcrypt.compare(
        password,
        process.env.KITCHEN_PASSWORD_HASH || ""
    );
    if (!matches) {
        return res.status(401).json({ error: "invalid_password" });
    }

    const token = jwt.sign({ role: "kitchen" }, process.env.JWT_SECRET, {
        expiresIn: "30d"
    });
    res.json({ token });
});

module.exports = router;
