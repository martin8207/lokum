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
                        quantity: 0,
                        confirmedCount: 0,
                        tableNumber: session.tableNumber,
                        submittedAt: order.submittedAt,
                        served: order.servedAt !== null
                    };
                    byProduct.set(item.productId, row);
                }
                row.quantity += 1;
                if (item.kaConfirmedAt) row.confirmedCount += 1;
            }

            for (const row of byProduct.values()) {
                const confirmed = row.confirmedCount === row.quantity;
                if (row.served && confirmed) continue;
                delete row.confirmedCount;
                row.confirmed = confirmed;
                rows.push(row);
            }
        }
    }

    rows.sort((a, b) => new Date(a.submittedAt) - new Date(b.submittedAt));
    res.json(rows);
});

module.exports = router;
