const express = require("express");

const prisma = require("../db");

const router = express.Router();

// GET /api/products?q=нач&category=cocktails - търсене за бележника на персонала.
router.get("/", async (req, res) => {
    const q = (req.query.q || "").trim();
    const category = req.query.category;

    const where = {
        available: true,
        ...(category ? { categoryId: category } : {}),
        ...(q
            ? {
                  OR: [
                      { nameBg: { contains: q, mode: "insensitive" } },
                      { nameEn: { contains: q, mode: "insensitive" } }
                  ]
              }
            : {})
    };

    const products = await prisma.product.findMany({
        where,
        orderBy: { nameBg: "asc" },
        take: 50,
        select: {
            id: true,
            nameBg: true,
            nameEn: true,
            priceEur: true,
            categoryId: true,
            subcategoryId: true
        }
    });

    res.json(products);
});

module.exports = router;
