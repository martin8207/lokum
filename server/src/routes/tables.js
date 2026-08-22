const express = require("express");

const prisma = require("../db");

const router = express.Router();

const MIN_TABLE = 1;
const MAX_TABLE = 14;

function parseTableNumber(raw) {
    const n = Number(raw);
    if (!Number.isInteger(n) || n < MIN_TABLE || n > MAX_TABLE) return null;
    return n;
}

// Активната (нефактурирана) сесия на маса, с всичко нужно за бележника/статус
// екраните - поръчки + бройки на всеки артикул в тях.
async function findActiveSession(tableNumber) {
    return prisma.tableSession.findFirst({
        where: { tableNumber, invoicedAt: null },
        orderBy: { openedAt: "desc" },
        include: {
            orders: {
                orderBy: { submittedAt: "asc" },
                include: {
                    items: {
                        orderBy: { createdAt: "asc" },
                        include: {
                            product: { select: { nameBg: true, nameEn: true } }
                        }
                    }
                }
            }
        }
    });
}

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
// Всяка бройка от количеството става ОТДЕЛЕН OrderItem ред (не quantity поле),
// защото бройките от едно и също количество могат да имат различна съдба
// (1 налята в КА, другата - изтрита, защото е свършила).
router.post("/:number/orders", async (req, res) => {
    const tableNumber = parseTableNumber(req.params.number);
    if (tableNumber === null) {
        return res.status(400).json({ error: "invalid_table_number" });
    }

    const items = Array.isArray(req.body.items) ? req.body.items : [];
    if (items.length === 0) {
        return res.status(400).json({ error: "empty_order" });
    }

    const productIds = [...new Set(items.map((it) => it.productId))];
    const products = await prisma.product.findMany({
        where: { id: { in: productIds } }
    });
    const productById = new Map(products.map((p) => [p.id, p]));

    for (const it of items) {
        if (!productById.has(it.productId)) {
            return res
                .status(400)
                .json({ error: "unknown_product", productId: it.productId });
        }
        if (!Number.isInteger(it.quantity) || it.quantity < 1) {
            return res
                .status(400)
                .json({ error: "invalid_quantity", productId: it.productId });
        }
    }

    const order = await prisma.$transaction(async (tx) => {
        let session = await tx.tableSession.findFirst({
            where: { tableNumber, invoicedAt: null }
        });
        if (!session) {
            session = await tx.tableSession.create({ data: { tableNumber } });
        }

        const unitRows = items.flatMap((it) => {
            const product = productById.get(it.productId);
            return Array.from({ length: it.quantity }, () => ({
                productId: it.productId,
                priceEur: product.priceEur ?? 0
            }));
        });

        return tx.order.create({
            data: {
                tableSessionId: session.id,
                items: { create: unitRows }
            },
            include: { items: true }
        });
    });

    res.status(201).json(order);
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
