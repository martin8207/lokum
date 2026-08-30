const jwt = require("jsonwebtoken");

// Пази всички staff endpoint-и (табло, поръчки, търсене) - без това, логин
// екранът във Flutter е чисто декоративен: всеки може да вика API-то
// директно (curl, dev tools) в момента, в който бъде публично достъпно.
function requireStaffAuth(req, res, next) {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;

    if (!token) {
        return res.status(401).json({ error: "missing_token" });
    }

    try {
        jwt.verify(token, process.env.JWT_SECRET);
        next();
    } catch {
        res.status(401).json({ error: "invalid_token" });
    }
}

module.exports = requireStaffAuth;
