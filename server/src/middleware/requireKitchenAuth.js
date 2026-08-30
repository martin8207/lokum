const jwt = require("jsonwebtoken");

// Пази routes/kitchen.js - отделна роля от requireStaffAuth, за да не може
// кухненски токен да достигне бележника/сметките, и обратно.
function requireKitchenAuth(req, res, next) {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;

    if (!token) {
        return res.status(401).json({ error: "missing_token" });
    }

    try {
        const payload = jwt.verify(token, process.env.JWT_SECRET);
        if (payload.role !== "kitchen") {
            return res.status(403).json({ error: "wrong_role" });
        }
        next();
    } catch {
        res.status(401).json({ error: "invalid_token" });
    }
}

module.exports = requireKitchenAuth;
