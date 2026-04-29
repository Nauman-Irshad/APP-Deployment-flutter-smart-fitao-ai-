-- ============================================================
-- Marketplace database tables (schema only, no implementation)
-- Aligned with: product page, seller profile, standard sizes,
-- final size chart, checkout/order summary.
-- ============================================================

-- ------------------------------------------------------------
-- 1. SELLERS (seller profile: id, name, address, message/shop)
-- ------------------------------------------------------------
CREATE TABLE sellers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  shop_image_path TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);

-- ------------------------------------------------------------
-- 2. PRODUCTS (product page: id, title, price, about, category, seller)
-- ------------------------------------------------------------
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  price INTEGER NOT NULL,
  original_price INTEGER,
  category_name TEXT NOT NULL,
  about TEXT,
  model_path TEXT,
  rating REAL,
  reviews INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);

-- ------------------------------------------------------------
-- 3. MESSAGES (between customer and seller; product optional)
-- ------------------------------------------------------------
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  customer_id INTEGER NOT NULL,
  product_id INTEGER,
  message_text TEXT NOT NULL,
  is_from_customer INTEGER NOT NULL DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

-- ------------------------------------------------------------
-- 4. KURTA SIZES (standard size page – one row per brand size)
-- Chest, waist, hip, shoulder, front_length, sleeve_length in sequence
-- ------------------------------------------------------------
CREATE TABLE kurta_sizes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand_size TEXT NOT NULL UNIQUE,
  chest TEXT NOT NULL,
  waist TEXT NOT NULL,
  hip TEXT NOT NULL,
  shoulder TEXT NOT NULL,
  front_length TEXT NOT NULL,
  sleeve_length TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

-- ------------------------------------------------------------
-- 5. PYJAMA SIZES (standard size page – one row per brand size)
-- ------------------------------------------------------------
CREATE TABLE pyjama_sizes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand_size TEXT NOT NULL UNIQUE,
  length TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

-- ------------------------------------------------------------
-- 6. FINAL SIZE CHART (all data on final size chart page)
-- Product id, name, price + kurta/pyjama sizes and measurements
-- ------------------------------------------------------------
CREATE TABLE final_size_chart (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  product_price INTEGER NOT NULL,
  kurta_size TEXT NOT NULL,
  pyjama_size TEXT NOT NULL,
  chest TEXT NOT NULL,
  waist TEXT NOT NULL,
  hip TEXT NOT NULL,
  shoulder TEXT NOT NULL,
  front_length TEXT NOT NULL,
  sleeve_length TEXT NOT NULL,
  pyjama_length TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (product_id) REFERENCES products(id)
);

-- ------------------------------------------------------------
-- 7. CHECKOUT / ORDERS (order summary: product, seller, customer, size chart, total, payment)
-- ------------------------------------------------------------
CREATE TABLE checkout_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  seller_id INTEGER NOT NULL,
  seller_name TEXT NOT NULL,
  customer_id INTEGER,
  customer_name TEXT NOT NULL,
  customer_address TEXT NOT NULL,
  kurta_size TEXT NOT NULL,
  pyjama_size TEXT NOT NULL,
  kurta_chest TEXT NOT NULL,
  kurta_waist TEXT NOT NULL,
  kurta_hip TEXT NOT NULL,
  kurta_shoulder TEXT NOT NULL,
  kurta_front_length TEXT NOT NULL,
  kurta_sleeve_length TEXT NOT NULL,
  pyjama_length TEXT NOT NULL,
  price_total INTEGER NOT NULL,
  payment_method TEXT NOT NULL,
  payment_method_name TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);

-- ------------------------------------------------------------
-- Payment method names (as used in app)
-- payment_method: cod | jazzcash | debitcard | mastercard
-- payment_method_name: Cash on Delivery (COD) | JazzCash | Debit Card | Mastercard
-- ------------------------------------------------------------
