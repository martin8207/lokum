require("dotenv").config();

const express = require("express");

const healthRouter = require("./routes/health");
const authRouter = require("./routes/auth");
const productsRouter = require("./routes/products");
const tablesRouter = require("./routes/tables");
const ordersRouter = require("./routes/orders");
const customerOrdersRouter = require("./routes/customerOrders");
const requireStaffAuth = require("./middleware/requireStaffAuth");

const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3000;

// Caddy проксира /api/* тук с пълния префикс запазен (handle, не handle_path),
// затова всички routes живеят под /api - виж root Caddyfile. Същият префикс
// го проксира и nginx-ът на lokum-web-v2 (виж mobile/nginx.conf), за да може
// бележникът на персонала да стигне дотук по tailnet-а.
//
// /health, /auth/login и /customer/* са публични - /customer/* е клиентското
// поръчване от масата (без login, виж routes/customerOrders.js), останалото
// (продукти/маси/поръчки от бележника) е staff-only и изисква JWT от
// /auth/login - виж requireStaffAuth. Клиентското меню само по себе си НЕ
// минава оттук (чете локален bundled menu.json) - само поръчването го прави.
const apiRouter = express.Router();
apiRouter.use("/health", healthRouter);
apiRouter.use("/auth", authRouter);
apiRouter.use("/customer", customerOrdersRouter);
apiRouter.use("/products", requireStaffAuth, productsRouter);
apiRouter.use("/tables", requireStaffAuth, tablesRouter);
apiRouter.use("/orders", requireStaffAuth, ordersRouter);

app.use("/api", apiRouter);

app.listen(PORT, () => {
    console.log(`Lokum Server listening on port ${PORT}`);
});
