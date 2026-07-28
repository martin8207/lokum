/**
 * Зарежда mobile/assets/data/menu.json (генериран от tools/excel_to_json.py -
 * същия файл, който храни и мобилното приложение) и го upsert-ва в Postgres
 * през Prisma: Category -> Subcategory -> Product, в този ред заради
 * foreign key ограниченията.
 *
 * Пускане:
 *   node prisma/seed.js
 * (или "npm run seed", виж package.json)
 */

require("dotenv").config();

const fs = require("fs");
const path = require("path");
const { PrismaClient } = require("../src/generated/prisma");

const prisma = new PrismaClient();

function resolveMenuJsonPath() {
  // В Docker: mobile/assets/data е mount-нат на /app/data (виж docker-compose.yml).
  const dockerMountPath = path.join(__dirname, "..", "data", "menu.json");
  if (fs.existsSync(dockerMountPath)) return dockerMountPath;

  // Локално изпълнение извън Docker (mobile/ като съседна папка на server/).
  const localDevPath = path.join(
    __dirname,
    "..",
    "..",
    "mobile",
    "assets",
    "data",
    "menu.json",
  );
  if (fs.existsSync(localDevPath)) return localDevPath;

  throw new Error(
    `Не намирам menu.json нито на ${dockerMountPath}, нито на ${localDevPath}`,
  );
}

function toStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.map((v) => String(v));
}

function loadMenu() {
  const raw = fs.readFileSync(resolveMenuJsonPath(), "utf-8");
  return JSON.parse(raw);
}

async function upsertCategory(category, sortOrder) {
  return prisma.category.upsert({
    where: { id: category.id },
    update: {
      nameBg: category.nameBg,
      nameEn: category.nameEn,
      sortOrder,
    },
    create: {
      id: category.id,
      nameBg: category.nameBg,
      nameEn: category.nameEn,
      sortOrder,
    },
  });
}

async function upsertSubcategory(subcategory, categoryId, sortOrder) {
  return prisma.subcategory.upsert({
    where: { id: subcategory.id },
    update: {
      categoryId,
      nameBg: subcategory.nameBg,
      nameEn: subcategory.nameEn,
      sortOrder,
    },
    create: {
      id: subcategory.id,
      categoryId,
      nameBg: subcategory.nameBg,
      nameEn: subcategory.nameEn,
      sortOrder,
    },
  });
}

async function upsertProduct(product, categoryId, subcategoryId) {
  const data = {
    categoryId,
    subcategoryId,
    brand: product.brand ?? null,
    variant: product.variant ?? null,
    nameBg: product.nameBg,
    nameEn: product.nameEn || null,
    descriptionBg: product.descriptionBg ?? null,
    descriptionEn: product.descriptionEn ?? null,
    priceEur: product.priceEur ?? 0,
    quantity: product.quantity ?? null,
    unit: product.unit ?? null,
    image: product.image ?? null,
    featured: Boolean(product.featured),
    isNew: Boolean(product.isNew),
    isRecommended: Boolean(product.isRecommended),
    available: product.available !== false,
    tags: toStringArray(product.tags),
    allergens: toStringArray(product.allergens),
  };

  return prisma.product.upsert({
    where: { id: product.id },
    update: data,
    create: { id: product.id, ...data },
  });
}

async function main() {
  const menu = loadMenu();

  let categoryCount = 0;
  let subcategoryCount = 0;
  let productCount = 0;

  for (let ci = 0; ci < menu.categories.length; ci++) {
    const category = menu.categories[ci];
    await upsertCategory(category, ci);
    categoryCount++;

    for (let si = 0; si < category.subcategories.length; si++) {
      const subcategory = category.subcategories[si];
      await upsertSubcategory(subcategory, category.id, si);
      subcategoryCount++;

      for (const product of subcategory.products) {
        await upsertProduct(product, category.id, subcategory.id);
        productCount++;
      }
    }
  }

  console.log(
    `✅ Seed готов: ${categoryCount} категории, ${subcategoryCount} подкатегории, ${productCount} продукта.`,
  );
}

main()
  .catch((error) => {
    console.error("❌ Seed се провали:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
