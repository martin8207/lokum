const prisma = require("../db");

const MIN_TABLE = 1;
const MAX_TABLE = 14;

function parseTableNumber(raw) {
    const n = Number(raw);
    if (!Number.isInteger(n) || n < MIN_TABLE || n > MAX_TABLE) return null;
    return n;
}

// Активната (нефактурирана) сесия на маса, с всичко нужно за бележника/статус
// екраните - поръчки + бройки на всеки артикул в тях. Ползва се както от
// staff бележника, така и от клиентския статус екран (виж routes/customerOrders.js) -
// клиентът вижда точно същата форма на данните за собствената си маса.
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

// Нов кръг поръчки - от бележника на персонала ИЛИ директно от клиента (виж
// routes/tables.js и routes/customerOrders.js). Всяка бройка от количеството
// става ОТДЕЛЕН OrderItem ред (не quantity поле), защото бройките от едно и
// също количество могат да имат различна съдба (1 налята в КА, другата -
// изтрита, защото е свършила). Връща { error } вместо да хвърля, за да могат
// двата route файла да мапнат кода към подходящ HTTP статус.
async function createOrder(tableNumber, items) {
    if (!Array.isArray(items) || items.length === 0) {
        return { error: "empty_order" };
    }

    const productIds = [...new Set(items.map((it) => it.productId))];
    const products = await prisma.product.findMany({
        where: { id: { in: productIds } }
    });
    const productById = new Map(products.map((p) => [p.id, p]));

    for (const it of items) {
        if (!productById.has(it.productId)) {
            return { error: "unknown_product", productId: it.productId };
        }
        if (!Number.isInteger(it.quantity) || it.quantity < 1) {
            return { error: "invalid_quantity", productId: it.productId };
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

    return { order };
}

module.exports = { MIN_TABLE, MAX_TABLE, parseTableNumber, findActiveSession, createOrder };
