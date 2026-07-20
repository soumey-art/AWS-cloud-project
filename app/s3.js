// s3.js
// Uploads a product image straight from memory (multer memory storage) to S3
// and returns the public URL. Nothing is ever written to the EC2 instance's disk,
// which keeps the app tier stateless.
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const crypto = require("crypto");
const path = require("path");

const region = process.env.AWS_REGION || "us-east-1";
const s3 = new S3Client({ region });
const BUCKET = process.env.S3_BUCKET_NAME;
const BUCKET_URL_PREFIX = `https://${BUCKET}.s3.${region}.amazonaws.com/`;

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

  // Return just the S3 object key
  return key;
}

function extractKey(storedUrl) {
  if (!storedUrl) return null;
  // If it's a direct URL (old format), extract the key part
  if (storedUrl.startsWith(BUCKET_URL_PREFIX)) {
    return storedUrl.slice(BUCKET_URL_PREFIX.length);
  }
  // Otherwise assume it's already a key
  return storedUrl;
}

async function getPresignedUrl(storedUrl) {
  const key = extractKey(storedUrl);
  if (!key) return null;

  const command = new GetObjectCommand({
    Bucket: BUCKET,
    Key: key,
  });

  // URL expires in 1 hour
  return getSignedUrl(s3, command, { expiresIn: 3600 });
}

module.exports = { s3, BUCKET, uploadProductImage, getPresignedUrl };