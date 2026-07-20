// server.js
require("dotenv").config();
const express = require("express");
const multer = require("multer");
const pool = require("./db/pool");
const { uploadProductImage, getPresignedUrl } = require("./s3");

const app = express();
const PORT = process.env.PORT || 3000;

app.set("view engine", "ejs");
app.set("views", __dirname + "/views");
app.use(express.static(__dirname + "/public"));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// Images are held in memory only (never written to local disk) and streamed
// straight to S3. This is what keeps the instance stateless.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});

// --- Health check for the Load Balancer ---
// Deliberately does NOT touch RDS or S3, so the ALB only marks an instance
// unhealthy when the app process itself is down, not on a transient DB/S3 blip.
app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

// --- Homepage: list products (RDS) + form to add a new one ---
app.get("/", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, description, price, image_url, created_at FROM products ORDER BY created_at DESC"
    );
    // Generate presigned URLs for product images (S3 bucket is not public)
    const products = await Promise.all(
      result.rows.map(async (p) => {
        if (p.image_url) {
          p.image_url = await getPresignedUrl(p.image_url);
        }
        return p;
      })
    );
    res.render("index", { products, error: null });
  } catch (err) {
    console.error(err);
    res.render("index", { products: [], error: "Could not load products from the database." });
  }
});

// --- Add a new product: text -> RDS, image -> S3 ---
app.post("/products", upload.single("image"), async (req, res) => {
  const { name, description, price } = req.body;

  if (!name || !price) {
    return res.status(400).send("Product name and price are required.");
  }

  try {
    const imageKey = await uploadProductImage(req.file);

    await pool.query(
      "INSERT INTO products (name, description, price, image_url) VALUES ($1, $2, $3, $4)",
      [name, description || "", price, imageKey]
    );

    res.redirect("/");
  } catch (err) {
    console.error(err);
    res.status(500).send("Failed to save product. Check RDS/S3 configuration.");
  }
});

// Simple JSON API too, in case a client wants it instead of the HTML form.
app.get("/api/products", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, description, price, image_url, created_at FROM products ORDER BY created_at DESC"
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Could not load products." });
  }
});

app.listen(PORT, () => {
  console.log(`Company Inventory Control System listening on port ${PORT}`);
});
