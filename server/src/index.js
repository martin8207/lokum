require("dotenv").config();

const express = require("express");

const healthRouter = require("./routes/health");

const app = express();

const PORT = process.env.PORT || 3000;

app.use("/health", healthRouter);

app.listen(PORT, () => {
    console.log(`Lokum Server listening on port ${PORT}`);
});
