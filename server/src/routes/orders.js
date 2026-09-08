const express = require("express");

const prisma = require("../db");

const router = express.Router();

// PATCH /api/orders/:orderId/serve - маркира целия кръг поръчки като занесен
// на масата. Заключено зад КА, огледално на /invoice в tables.js - не пускай
// сервитьора да отнесе нещо на масата, преди да е минало през касата, иначе
// бройката така и не влиза в сметката (виж readyToInvoice в бележника).
router.patch("/:orderId/serve", async (req, res) => {
    const order = await prisma.order.findUnique({
        where: { id: req.params.orderId },
        include: { items: true }
    });
    if (!order) return res.status(404).json({ error: "order_not_found" });

    const hasUnresolvedItem = order.items
        .filter((it) => !it.removedAt)
        .some((it) => !it.kaConfirmedAt);
    if (hasUnresolvedItem) {
        return res.status(409).json({ error: "items_not_confirmed_in_ka" });
    }

    const updated = await prisma.order.update({
        where: { id: req.params.orderId },
        data: { servedAt: new Date() }
    });
    res.json(updated);
});

// PATCH /api/orders/:orderId/cancel - отказва цялата поръчка. Двойното/
// тройното потвърждение е UI-side (Flutter) - тук просто маркираме.
router.patch("/:orderId/cancel", async (req, res) => {
    const order = await prisma.order.update({
        where: { id: req.params.orderId },
        data: { cancelledAt: new Date() }
    });
    res.json(order);
});

// PATCH /api/orders/:orderId/items/:itemId/confirm - потвърждава ЕДНА бройка
// като наляна/прекуцана в касовия апарат.
router.patch("/:orderId/items/:itemId/confirm", async (req, res) => {
    const item = await prisma.orderItem.update({
        where: { id: req.params.itemId },
        data: { kaConfirmedAt: new Date() }
    });
    res.json(item);
});

// PATCH /api/orders/:orderId/items/:itemId/unconfirm - връща бройка обратно
// в "чака" - за поправка на грешно тапнато потвърждение в КА.
router.patch("/:orderId/items/:itemId/unconfirm", async (req, res) => {
    const item = await prisma.orderItem.update({
        where: { id: req.params.itemId },
        data: { kaConfirmedAt: null }
    });
    res.json(item);
});

// DELETE /api/orders/:orderId/items/:itemId - маха ЕДНА бройка (не е налична,
// свършила е и т.н.). Меко изтриване (removedAt), не истинско DELETE - пази
// се историята защо сметката не съвпада 1:1 с първоначално подадената поръчка.
router.delete("/:orderId/items/:itemId", async (req, res) => {
    const item = await prisma.orderItem.update({
        where: { id: req.params.itemId },
        data: { removedAt: new Date() }
    });
    res.json(item);
});

module.exports = router;
