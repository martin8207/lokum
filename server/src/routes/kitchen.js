const express = require("express");

const prisma = require("../db");

const router = express.Router();

// GET /api/kitchen/tables - само каквото трябва на кухнята: активни (не
// сервирани, не отказани) артикули от категория "храна", по маси. Чисто за
// гледане (виж разговора) - без КА потвърждение, без "готово" маркиране за
// v1. Веднъж сервирана поръчката изчезва оттук - кухнята вече я е дала.
router.get("/tables", async (req, res) => {
    const sessions = await prisma.tableSession.findMany({
        where: { invoicedAt: null },
        orderBy: { tableNumber: "asc" },
        include: {
            orders: {
                where: { cancelledAt: null, servedAt: null },
                orderBy: { submittedAt: "asc" },
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

    const tables = sessions
        .map((session) => ({
            tableNumber: session.tableNumber,
            orders: session.orders
                .filter((order) => order.items.length > 0)
                .map((order) => ({
                    orderId: order.id,
                    submittedAt: order.submittedAt,
                    items: order.items.map((item) => ({
                        id: item.id,
                        productId: item.productId,
                        nameBg: item.product.nameBg,
                        nameEn: item.product.nameEn
                    }))
                }))
        }))
        .filter((table) => table.orders.length > 0);

    res.json(tables);
});

module.exports = router;
