const express = require("express");

const prisma = require("../db");
const {
    parseTableNumber,
    findActiveSession,
    createOrder
} = require("../lib/tableSession");

// ПУБЛИЧЕН router - директно поръчване от масата, без staff логин (виж
// index.js: не минава през requireStaffAuth). Само каквото трябва на
// клиента: статус на собствената маса + подаване на нов кръг поръчки +
// отказ на поръчка, докато персоналът още не я е докоснал. Сервиране,
// потвърждение в КА, фактуриране и освобождаване на маса остават изцяло
// staff-only действия (routes/tables.js, routes/orders.js).
const router = express.Router();

// GET /api/customer/tables/:number - статус на собствената маса, за да вижда
// клиентът кои бройки чакат, кои са потвърдени в КА и кои са отказани от
// персонала като неналични (виж StaffOrderItem.isRemoved на клиента).
router.get("/tables/:number", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const session = await findActiveSession(tableNumber);
    res.json(session ?? { tableNumber, orders: [] });
});

// POST /api/customer/tables/:number/orders - нов кръг поръчки директно от
// клиента. Същата логика като бележника на персонала (routes/tables.js) -
// виж lib/tableSession.js.
router.post("/tables/:number/orders", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const result = await createOrder(tableNumber, req.body.items);
    if (result.error) {
        return res.status(400).json(result);
    }

    res.status(201).json(result.order);
});

// PATCH /api/customer/tables/:number/orders/:orderId/cancel - клиентът може
// да откаже СОБСТВЕНА поръчка, но само докато персоналът не я е докоснал -
// нито сервирана, нито поне една бройка потвърдена в КА. Иначе би могъл да
// анулира вече наляно/сервирано, за да не плати - затова 409, не тихо
// изпълнение (виж разговора за измами по бележника).
router.patch("/tables/:number/orders/:orderId/cancel", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const order = await prisma.order.findUnique({
        where: { id: req.params.orderId },
        include: { items: true, tableSession: true }
    });

    if (
        !order ||
        order.tableSession.tableNumber !== tableNumber ||
        order.tableSession.invoicedAt !== null
    ) {
        return res.status(404).json({ error: "order_not_found" });
    }
    if (order.cancelledAt) {
        return res.json(order);
    }
    if (order.servedAt) {
        return res.status(409).json({ error: "already_served" });
    }
    if (order.items.some((it) => it.kaConfirmedAt)) {
        return res.status(409).json({ error: "already_confirmed" });
    }

    const updated = await prisma.order.update({
        where: { id: order.id },
        data: { cancelledAt: new Date() }
    });

    res.json(updated);
});

module.exports = router;
