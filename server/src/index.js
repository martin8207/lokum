require("dotenv").config();

const express = require("express");

const healthRouter = require("./routes/health");

const app = express();

const PORT = process.env.PORT || 3000;

// Caddy проксира /api/* тук с пълния префикс запазен (handle, не handle_path),
// затова всички routes живеят под /api - виж root Caddyfile.
const apiRouter = express.Router();
apiRouter.use("/health", healthRouter);

app.use("/api", apiRouter);

app.listen(PORT, () => {
    console.log(`Lokum Server listening on port ${PORT}`);
});
