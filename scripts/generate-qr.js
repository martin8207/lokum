/**
 * Генерира QR код (PNG) към текущия публичен адрес на апа, като статичен
 * Flutter asset - mobile/assets/qr/menu-qr.png.
 *
 * Адресът се чете от PUBLIC_APP_URL в root .env. При смяна на домейн
 * (напр. нов Tailscale Funnel адрес) - update-ни PUBLIC_APP_URL и пусни
 * скрипта пак:
 *   npm run generate-qr
 */

require("dotenv").config();

const fs = require("fs");
const path = require("path");
const QRCode = require("qrcode");

const url = process.env.PUBLIC_APP_URL;

if (!url) {
  console.error(
    "❌ PUBLIC_APP_URL липсва в .env - сложи текущия публичен адрес на апа (напр. https://lokum.tail9667e2.ts.net) и опитай пак.",
  );
  process.exit(1);
}

const outDir = path.join(__dirname, "..", "mobile", "assets", "qr");
const outPath = path.join(outDir, "menu-qr.png");

fs.mkdirSync(outDir, { recursive: true });

QRCode.toFile(
  outPath,
  url,
  {
    type: "png",
    errorCorrectionLevel: "H",
    margin: 2,
    width: 800,
  },
  (error) => {
    if (error) {
      console.error("❌ Генерирането на QR кода се провали:", error);
      process.exit(1);
    }
    console.log(`✅ QR код генериран за ${url}`);
    console.log(`   -> ${outPath}`);
  },
);
