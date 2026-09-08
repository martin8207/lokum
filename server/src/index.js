require("dotenv").config();

const express = require("express");

const healthRouter = require("./routes/health");
const whoamiRouter = require("./routes/whoami");
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

// Реалният публичен трафик влиза през Tailscale Funnel директно към nginx-а
// на lokum-web/lokum-web-v2 (порт 8080/8081 на хоста) - Caddy НЕ участва,
// въпреки root Caddyfile-а (Funnel bypass-ва host-based routing-а му). Тази
// nginx проксира /api/* насам според env-а API_BACKEND (виж
// mobile/nginx.conf.template + docker-compose.yml) - upstream "api_production"
// (round-robin между това копие и lokum-server-2, stateless е безопасно) за
// lokum-web, upstream "api_test" (само lokum-server-v2) за lokum-web-v2.
// Затова всички routes живеят под /api с пълния префикс запазен.
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
apiRouter.use("/whoami", whoamiRouter);
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
