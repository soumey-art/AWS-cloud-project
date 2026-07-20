# Company Inventory Control System

A minimal digital product catalog built for a three-tier AWS setup:

```
Users -> ALB -> EC2 (this app, stateless) -> RDS (product text) 
                                          -> S3  (product images)
```

## What it does

- **Homepage** — title page "Company Inventory Control System" with a form to add a
  product (name, description, price) and a listing of everything logged so far.
- **RDS** — product name/description/price are saved to and read from a `products`
  table in a PostgreSQL RDS instance (`db/pool.js`, `db/schema.sql`).
- **S3** — the product preview image is uploaded straight to an S3 bucket from memory
  (never written to local disk) and its URL is stored alongside the RDS row, so the
  listing shows text (RDS) and image (S3) side by side (`s3.js`).
- **Stateless EC2** — no uploaded files or session data ever touch local disk, so any
  instance behind the load balancer can serve any request. Safe to scale out/in or
  replace instances at will.
- **`/health`** — returns `200 {"status":"ok"}` without touching RDS or S3, so the ALB
  target group health check reflects "is the app process up," not transient DB blips.

## Project layout

```
server.js         Express app: routes, health check, upload handling
s3.js              S3 upload helper (in-memory buffer -> S3, returns URL)
db/pool.js         PostgreSQL connection pool (RDS)
db/schema.sql       products table definition
db/init.js          one-time script to create the table
views/index.ejs     homepage template
public/style.css    styling
.env.example        required environment variables
```

## Local setup

```bash
npm install
cp .env.example .env      # fill in your RDS + S3 details
npm run init-db           # creates the products table on RDS
npm start                 # http://localhost:3000
```

## AWS deployment notes

1. **RDS**: create a PostgreSQL instance, open its security group to your EC2
   instances' security group on port 5432, then run `npm run init-db` once (from an
   EC2 instance or a bastion with connectivity) to create the `products` table.
2. **S3**: create a bucket for product images. Grant your EC2 instance role
   `s3:PutObject` (and `s3:GetObject` if you want the bucket private with signed
   reads instead of public URLs).
3. **EC2**: deploy this app (e.g. via an Auto Scaling Group + launch template),
   set the environment variables from `.env.example` (via instance user-data,
   SSM Parameter Store, or Secrets Manager — avoid baking real credentials into
   the AMI). Prefer an **IAM instance role** over static AWS keys so the app
   doesn't need `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` at all.
4. **Load Balancer**: point the ALB target group health check at `/health` on
   the app's port. Since instances hold no local state, the ASG can freely
   add/remove/replace instances without any data loss.

## Notes

- Images are capped at 5MB in `server.js` (`multer` limits) — adjust as needed.
- The S3 URL format assumes a public bucket for simplicity ("keep it simple").
  For a private bucket, swap `uploadProductImage`'s return value for a
  presigned GET URL instead.
