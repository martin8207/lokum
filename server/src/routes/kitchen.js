const express = require("express");

const prisma = require("../db");

const router = express.Router();

// GET /api/kitchen/items - плосък списък от чакащи артикули (категория
// "храна"), сортиран възходящо по час на подаване (най-старата заявка
// първо - FIFO). Бройките от едно и също ястие в един и същ кръг поръчки се
// групират в един ред с количество (виж lokum-kitchen-view-task.md) -
// "индивидуални артикули" означава не групирани по поръчка/маса, не един
// ред на физическа бройка.
//
// Ред изчезва само когато е И сервиран, И всяка негова бройка е минала през
// КА - нарочно двойно условие (не само "сервиран"), за да остане като
// напомняне на сервитьора да го чекне в касата, дори ако вече физически е
// занесъл ястието на масата (иначе бройката така и не влиза в сметката,
// виж readyToInvoice в бележника).
router.get("/items", async (req, res) => {
    const sessions = await prisma.tableSession.findMany({
        where: { invoicedAt: null },
        include: {
            orders: {
                where: { cancelledAt: null },
                include: {
                    items: {
                        where: { removedAt: null, product: { categoryId: "food" } },
                        orderBy: { createdAt: "asc" },
                        include: {
                            product: { select: { nameBg: true, nameEn: true } }
                        }
                    }
                }
            }
        }
    });

    const rows = [];
    for (const session of sessions) {
        for (const order of session.orders) {
            const byProduct = new Map();
            for (const item of order.items) {
                let row = byProduct.get(item.productId);
                if (!row) {
                    row = {
                        id: `${order.id}:${item.productId}`,
                        productId: item.productId,
                        nameBg: item.product.nameBg,
                        nameEn: item.product.nameEn,
                        tableNumber: session.tableNumber,
                        submittedAt: order.submittedAt,
                        served: order.servedAt !== null,
                        // Индивидуални бройки, не само общ брой - кухнята
                        // маркира "издадено" по бройка (виж PATCH /items/:id/issue),
                        // затова UI-ят трябва да вижда истинските OrderItem id-та.
                        units: []
                    };
                    byProduct.set(item.productId, row);
                }
                row.units.push({
                    itemId: item.id,
                    confirmed: item.kaConfirmedAt !== null,
                    issued: item.issuedAt !== null
                });
            }

            for (const row of byProduct.values()) {
                const confirmed = row.units.every((u) => u.confirmed);
                if (row.served && confirmed) continue;
                row.quantity = row.units.length;
                row.confirmed = confirmed;
                rows.push(row);
            }
        }
    }

    rows.sort((a, b) => new Date(a.submittedAt) - new Date(b.submittedAt));
    res.json(rows);
});

// PATCH /api/kitchen/items/:itemId/issue - маркира ЕДНА бройка като издадена
// от кухнята (приготвена/предадена) - независимо от kaConfirmedAt (касата) и
// от Order.servedAt (сервитьорът още не я е занесъл непременно на масата).
router.patch("/items/:itemId/issue", async (req, res) => {
    const item = await prisma.orderItem.findUnique({
        where: { id: req.params.itemId }
    });
    if (!item) return res.status(404).json({ error: "item_not_found" });

    const updated = await prisma.orderItem.update({
        where: { id: item.id },
        data: { issuedAt: new Date() }
    });
    res.json(updated);
});

// PATCH /api/kitchen/items/:itemId/unissue - обратното, за поправка на
// грешно тапнато "Издадено".
router.patch("/items/:itemId/unissue", async (req, res) => {
    const item = await prisma.orderItem.findUnique({
        where: { id: req.params.itemId }
    });
    if (!item) return res.status(404).json({ error: "item_not_found" });

    const updated = await prisma.orderItem.update({
        where: { id: item.id },
        data: { issuedAt: null }
    });
    res.json(updated);
});

module.exports = router;
