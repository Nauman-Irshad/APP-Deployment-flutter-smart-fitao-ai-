-- PostgreSQL schema for SmartFitao
-- Use one of the following to enable UUID generation:
-- Option A (pgcrypto):
--   CREATE EXTENSION IF NOT EXISTS pgcrypto;
--   SELECT gen_random_uuid();
-- Option B (uuid-ossp):
--   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
--   SELECT uuid_generate_v4();

-- USERS
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  profile_image TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SELLERS
CREATE TABLE IF NOT EXISTS sellers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  shop_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- PRODUCTS
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  price NUMERIC(12,2) NOT NULL,
  original_price NUMERIC(12,2),
  category TEXT,
  image TEXT,
  rating NUMERIC(3,2) DEFAULT 0,
  reviews INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ORDERS
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  seller_id UUID REFERENCES sellers(id) ON DELETE SET NULL,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  product_title TEXT,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(12,2) NOT NULL,
  total_price NUMERIC(12,2) NOT NULL,
  category TEXT,
  product_image TEXT,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, sent, shipped, delivered, cancelled
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_seller_id ON orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- SAMPLE DATA
-- Add a test user
INSERT INTO users (id, name, email)
VALUES (gen_random_uuid(), 'Test User', 'testuser@example.com')
ON CONFLICT (email) DO NOTHING;

-- Add a test seller
INSERT INTO sellers (id, name, email, shop_name)
VALUES (gen_random_uuid(), 'Test Seller', 'seller@example.com', 'Nauman Tailors')
ON CONFLICT (email) DO NOTHING;

-- Add sample products
INSERT INTO products (id, title, price, original_price, category, image, rating, reviews)
VALUES
  (gen_random_uuid(), 'Classic White Shalwar Kameez', 2000, 2300, 'Shalwar Kameez', 'assets/6.webp', 4.9, 124),
  (gen_random_uuid(), 'Embroidered Kurta Pajama', 1800, 2500, 'Kurtaz Pajama', 'assets/2.webp', 4.8, 98)
ON CONFLICT DO NOTHING;

-- PLACE AN ORDER (sample query)
-- Begin a transaction and insert an order, associating it with a user and product
BEGIN;
-- Find a user and product ids (replace with actual ids if known)
-- Example selecting first user and product
WITH u AS (SELECT id as user_id FROM users LIMIT 1),
     p AS (SELECT id as product_id, title, price, image, category FROM products LIMIT 1),
     s AS (SELECT id as seller_id FROM sellers LIMIT 1)
INSERT INTO orders (user_id, seller_id, product_id, product_title, quantity, unit_price, total_price, category, product_image, status)
SELECT u.user_id, s.seller_id, p.product_id, p.title, 1, p.price, p.price * 1, p.category, p.image, 'sent'
FROM u, p, s
RETURNING id;
COMMIT;

-- QUERIES
-- Get all orders
SELECT * FROM orders ORDER BY created_at DESC;

-- Get orders for a specific user (replace :user_id)
SELECT * FROM orders WHERE user_id = :user_id ORDER BY created_at DESC;

-- Update order status to 'shipped'
UPDATE orders SET status = 'shipped', updated_at = now() WHERE id = :order_id;

-- Count orders by status
SELECT status, COUNT(*) FROM orders GROUP BY status;

-- Seller view: get recent orders for a seller
SELECT * FROM orders WHERE seller_id = :seller_id ORDER BY created_at DESC LIMIT 20;

-- Transactional example for placing an order and decrementing stock (if stock column exists)
-- BEGIN;
-- UPDATE products SET stock = stock - 1 WHERE id = :product_id AND stock > 0;
-- INSERT INTO orders (...) VALUES (...);
-- COMMIT;
