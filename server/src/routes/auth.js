const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const router = express.Router();

// POST /api/auth/login - едно поле за парола, за всичкия персонал (не
// индивидуален login). Ролята (staff/kitchen) се определя от това КОЯ
// споделена парола е въведена, не от отделен избор в UI-я - виж
// разговора: една зъбчатка, паролата решава накъде отива човекът.
router.post("/login", async (req, res) => {
    const { password } = req.body;
    if (typeof password !== "string" || password.length === 0) {
        return res.status(400).json({ error: "missing_password" });
    }

    const isStaff = await bcrypt.compare(
        password,
        process.env.STAFF_PASSWORD_HASH || ""
    );
    if (isStaff) {
        const token = jwt.sign({ role: "staff" }, process.env.JWT_SECRET, {
            expiresIn: "30d"
        });
        return res.json({ token, role: "staff" });
    }

    const isKitchen = await bcrypt.compare(
        password,
        process.env.KITCHEN_PASSWORD_HASH || ""
    );
    if (isKitchen) {
        const token = jwt.sign({ role: "kitchen" }, process.env.JWT_SECRET, {
            expiresIn: "30d"
        });
        return res.json({ token, role: "kitchen" });
    }

    res.status(401).json({ error: "invalid_password" });
});

module.exports = router;
