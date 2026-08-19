require("dotenv").config();

const express = require("express");

const healthRouter = require("./routes/health");
const productsRouter = require("./routes/products");
const tablesRouter = require("./routes/tables");
const ordersRouter = require("./routes/orders");

const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3000;

// Caddy проксира /api/* тук с пълния префикс запазен (handle, не handle_path),
// затова всички routes живеят под /api - виж root Caddyfile. Същият префикс
// го проксира и nginx-ът на lokum-web-v2 (виж mobile/nginx.conf), за да може
// бележникът на персонала да стигне дотук по tailnet-а.
const apiRouter = express.Router();
apiRouter.use("/health", healthRouter);
apiRouter.use("/products", productsRouter);
apiRouter.use("/tables", tablesRouter);
apiRouter.use("/orders", ordersRouter);

app.use("/api", apiRouter);

app.listen(PORT, () => {
    console.log(`Lokum Server listening on port ${PORT}`);
});
