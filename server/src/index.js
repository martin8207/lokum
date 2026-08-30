require("dotenv").config();

const express = require("express");

const healthRouter = require("./routes/health");
const authRouter = require("./routes/auth");
const productsRouter = require("./routes/products");
const tablesRouter = require("./routes/tables");
const ordersRouter = require("./routes/orders");
const customerOrdersRouter = require("./routes/customerOrders");
const kitchenRouter = require("./routes/kitchen");
const requireStaffAuth = require("./middleware/requireStaffAuth");
const requireKitchenAuth = require("./middleware/requireKitchenAuth");

const app = express();

app.use(express.json());

const PORT = process.env.PORT || 3000;

// Caddy проксира /api/* тук с пълния префикс запазен (handle, не handle_path),
// затова всички routes живеят под /api - виж root Caddyfile. Същият префикс
// го проксира и nginx-ът на lokum-web-v2 (виж mobile/nginx.conf), за да може
// бележникът на персонала да стигне дотук по tailnet-а.
//
// /health, /auth/login и /customer/* са публични - /customer/* е клиентското
// поръчване от масата (без login, виж routes/customerOrders.js). Останалото
// изисква JWT с точна роля: /products, /tables, /orders са staff-only (виж
// requireStaffAuth), /kitchen е kitchen-only (виж requireKitchenAuth) - и
// двете роли идват от ЕДНО и също /auth/login (коя парола въведеш решава
// коя роля получаваш, виж routes/auth.js), всяка заключена само до
// собствената си група routes. Клиентското меню само по себе си НЕ минава
// оттук (чете локален bundled menu.json) - само поръчването/кухнята го правят.
const apiRouter = express.Router();
apiRouter.use("/health", healthRouter);
apiRouter.use("/auth", authRouter);
apiRouter.use("/customer", customerOrdersRouter);
apiRouter.use("/products", requireStaffAuth, productsRouter);
apiRouter.use("/tables", requireStaffAuth, tablesRouter);
apiRouter.use("/orders", requireStaffAuth, ordersRouter);
apiRouter.use("/kitchen", requireKitchenAuth, kitchenRouter);

app.use("/api", apiRouter);

app.listen(PORT, () => {
    console.log(`Lokum Server listening on port ${PORT}`);
});
