const express = require("express");

const prisma = require("../db");

const router = express.Router();

// GET /api/kitchen/items - плосък списък от чакащи артикули (категория
// "храна"), сортиран възходящо по час на подаване (най-старата заявка
// първо - FIFO, за да не се пропускат чакащи артикули). Бройките от едно и
// също ястие в един и същ кръг поръчки се групират в един ред с количество
// (виж lokum-kitchen-view-task.md) - "индивидуални артикули" означава не
// групирани по поръчка/маса, не един ред на физическа бройка.
//
// Чисто за гледане - без КА потвърждение, без "готово" маркиране (виж
// разговора). Веднъж сервирана поръчката (от изгледа на масата в
// бележника), изчезва оттук автоматично - един и същ запис за двата
// изгледа, затова "готово" в кухнята няма собствено действие.
router.get("/items", async (req, res) => {
    const sessions = await prisma.tableSession.findMany({
        where: { invoicedAt: null },
        include: {
            orders: {
                where: { cancelledAt: null, servedAt: null },
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
                        tableNumber: session.tableNumber,
                        submittedAt: order.submittedAt
                    };
                    byProduct.set(item.productId, row);
                    rows.push(row);
                }
                row.quantity += 1;
            }
        }
    }

    rows.sort((a, b) => new Date(a.submittedAt) - new Date(b.submittedAt));
    res.json(rows);
});

module.exports = router;
