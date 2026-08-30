-- AlterTable
ALTER TABLE "TableSession" ADD COLUMN "billRequestedAt" TIMESTAMP(3),
ADD COLUMN "requestedPaymentMethod" "PaymentMethod";
