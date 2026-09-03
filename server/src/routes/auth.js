const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const router = express.Router();

// POST /api/auth/login - body: { password, role }. Ролята се избира изрично
// в UI-я (combo box до зъбчатката) и паролата се проверява САМО срещу
// избраната роля - ако избереш "персонал" и въведеш паролата на кухнята,
// не влиза (виж разговора: изрично, не auto-detect по коя парола съвпада).
router.post("/login", async (req, res) => {
    const { password, role } = req.body;
    if (typeof password !== "string" || password.length === 0) {
        return res.status(400).json({ error: "missing_password" });
    }
    if (role !== "staff" && role !== "kitchen") {
        return res.status(400).json({ error: "invalid_role" });
    }

    const hash =
        role === "staff"
            ? process.env.STAFF_PASSWORD_HASH
            : process.env.KITCHEN_PASSWORD_HASH;
    const matches = await bcrypt.compare(password, hash || "");
    if (!matches) {
        return res.status(401).json({ error: "invalid_password" });
    }

    const token = jwt.sign({ role }, process.env.JWT_SECRET, {
        expiresIn: "30d"
    });
    res.json({ token, role });
});

module.exports = router;
