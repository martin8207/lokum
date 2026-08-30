const express = require("express");

const prisma = require("../db");
const {
    MIN_TABLE,
    MAX_TABLE,
    parseTableNumber,
    findActiveSession,
    createOrder
} = require("../lib/tableSession");

const router = express.Router();

// Статус на плочката в таблото - виж бележника: "Сервиран" и "Потвърден в
// КА" са независими флагове, затова "чака внимание" е производно състояние,
// не отделен статус, който се пази в базата.
function tileState(session) {
    const activeOrders = session.orders.filter((o) => !o.cancelledAt);
    // Всички поръчки на масата са отказани (или сесията е празна) - нищо не
    // я заема реално, дори техническият TableSession ред да стои нефактуриран.
    if (activeOrders.length === 0) return "free";
    const hasUnservedOrder = activeOrders.some((o) => !o.servedAt);
    const hasPendingKa = activeOrders.some((o) =>
        o.items.some((it) => !it.removedAt && !it.kaConfirmedAt)
    );
    if (hasUnservedOrder) return "waiting";
    if (hasPendingKa) return "needsKa";
    return "served";
}

// GET /api/tables - табло с общ преглед на всички 1..14 маси.
router.get("/", async (req, res) => {
    const sessions = await prisma.tableSession.findMany({
        where: { invoicedAt: null },
        include: {
            orders: {
                include: { items: true }
            }
        }
    });

    const byTable = new Map(sessions.map((s) => [s.tableNumber, s]));

    const tables = [];
    for (let n = MIN_TABLE; n <= MAX_TABLE; n++) {
        const session = byTable.get(n);
        if (!session) {
            tables.push({ tableNumber: n, state: "free" });
            continue;
        }
        tables.push({
            tableNumber: n,
            state: tileState(session),
            sessionId: session.id,
            openedAt: session.openedAt
        });
    }

    res.json(tables);
});

// GET /api/tables/:number - пълен детайл за бележника/статус екраните.
router.get("/:number", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const session = await findActiveSession(tableNumber);
    res.json(session ?? { tableNumber, orders: [] });
});

// POST /api/tables/:number/orders - нов кръг поръчки от бележника.
// body: { items: [{ productId, quantity }] }
router.post("/:number/orders", async (req, res) => {
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

// PATCH /api/tables/:number/invoice - приключва цялата сесия на масата.
// body: { paymentMethod: "CASH" | "CARD" }
// Не пуска, докато не всички неотказани бройки в сесията са минали през КА
// (потвърдени или изтрити) - иначе сметката се затваря с непрекуцани артикули.
router.patch("/:number/invoice", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const { paymentMethod } = req.body;
    if (paymentMethod !== "CASH" && paymentMethod !== "CARD") {
        return res.status(400).json({ error: "invalid_payment_method" });
    }

    const session = await findActiveSession(tableNumber);
    if (!session) {
        return res.status(404).json({ error: "no_active_session" });
    }

    const hasUnresolvedItem = session.orders
        .filter((o) => !o.cancelledAt)
        .flatMap((o) => o.items)
        .some((it) => !it.removedAt && !it.kaConfirmedAt);

    if (hasUnresolvedItem) {
        return res.status(409).json({ error: "items_not_confirmed_in_ka" });
    }

    const updated = await prisma.tableSession.update({
        where: { id: session.id },
        data: { invoicedAt: new Date(), paymentMethod }
    });

    res.json(updated);
});

// PATCH /api/tables/:number/free - "Освободи маса", изрично действие на
// персонала, отделно от простото отказване/изтриване на артикули. Затваря
// текущата сесия БЕЗ плащане/КА проверка - за изоставена маса, тестова
// поръчка и т.н., не за реално платена сметка (за това си е /invoice).
router.patch("/:number/free", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const session = await prisma.tableSession.findFirst({
        where: { tableNumber, invoicedAt: null }
    });
    if (!session) {
        return res.status(404).json({ error: "no_active_session" });
    }

    const updated = await prisma.tableSession.update({
        where: { id: session.id },
        data: { invoicedAt: new Date(), paymentMethod: null }
    });

    res.json(updated);
});

module.exports = router;
