// s3.js
// Uploads a product image straight from memory (multer memory storage) to S3
// and returns the public URL. Nothing is ever written to the EC2 instance's disk,
// which keeps the app tier stateless.
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const crypto = require("crypto");
const path = require("path");

const region = process.env.AWS_REGION || "us-east-1";
const s3 = new S3Client({ region });
const BUCKET = process.env.S3_BUCKET_NAME;

async function uploadProductImage(file) {
  if (!file) return null;

  if (!BUCKET) {
    throw new Error("S3_BUCKET_NAME environment variable is not defined.");
  }

  const ext = path.extname(file.originalname) || "";
  const key = `products/${Date.now()}-${crypto.randomBytes(6).toString("hex")}${ext}`;

  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: file.buffer,
      ContentType: file.mimetype,
    })
  );

  // Return formatted public S3 URL
  return `https://${BUCKET}.s3.${region}.amazonaws.com/${key}`;
}

module.exports = { s3, BUCKET, uploadProductImage };