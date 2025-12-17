-- ============================================================
-- E-COMMERCE DATABASE SCHEMA
-- High-Quality Example with Best Practices
-- ============================================================
-- This schema demonstrates:
-- - Proper normalization (3NF)
-- - Foreign key relationships
-- - Data integrity constraints
-- - Indexes for performance
-- - Audit trails
-- ============================================================

-- Enable foreign key constraints (SQLite specific)
PRAGMA foreign_keys = ON;

-- ============================================================
-- USERS AND AUTHENTICATION
-- ============================================================

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,  -- Always hash passwords!
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- ============================================================
-- ADDRESSES
-- ============================================================

CREATE TABLE addresses (
    address_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    address_type TEXT NOT NULL CHECK(address_type IN ('billing', 'shipping')),
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL DEFAULT 'USA',
    is_default INTEGER DEFAULT 0 CHECK(is_default IN (0, 1)),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_addresses_user ON addresses(user_id);

-- ============================================================
-- PRODUCT CATALOG
-- ============================================================

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name TEXT NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sku TEXT NOT NULL UNIQUE,  -- Stock Keeping Unit
    product_name TEXT NOT NULL,
    description TEXT,
    category_id INTEGER NOT NULL,
    price REAL NOT NULL CHECK(price >= 0),
    cost REAL CHECK(cost >= 0),  -- For profit calculations
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
    is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE UNIQUE INDEX idx_products_sku_unique ON products(sku);

-- Product images
CREATE TABLE product_images (
    image_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    image_url TEXT NOT NULL,
    is_primary INTEGER DEFAULT 0 CHECK(is_primary IN (0, 1)),
    display_order INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- ============================================================
-- SHOPPING CART
-- ============================================================

CREATE TABLE shopping_carts (
    cart_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE cart_items (
    cart_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    cart_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    price_at_addition REAL NOT NULL,  -- Store price when added (for price changes)
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================
-- ORDERS
-- ============================================================

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    order_number TEXT NOT NULL UNIQUE,  -- Human-readable order number
    order_status TEXT NOT NULL DEFAULT 'pending' 
        CHECK(order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    subtotal REAL NOT NULL CHECK(subtotal >= 0),
    tax_amount REAL NOT NULL DEFAULT 0 CHECK(tax_amount >= 0),
    shipping_cost REAL NOT NULL DEFAULT 0 CHECK(shipping_cost >= 0),
    total_amount REAL NOT NULL CHECK(total_amount >= 0),
    shipping_address_id INTEGER NOT NULL,
    billing_address_id INTEGER NOT NULL,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'unpaid' 
        CHECK(payment_status IN ('unpaid', 'paid', 'refunded', 'failed')),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id),
    FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_date ON orders(created_at);

-- Order items (products in an order)
CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    price_per_unit REAL NOT NULL CHECK(price_per_unit >= 0),  -- Price at time of order
    subtotal REAL NOT NULL CHECK(subtotal >= 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);

-- ============================================================
-- REVIEWS AND RATINGS
-- ============================================================

CREATE TABLE product_reviews (
    review_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
    title TEXT NOT NULL,
    review_text TEXT,
    is_verified_purchase INTEGER DEFAULT 0 CHECK(is_verified_purchase IN (0, 1)),
    helpful_count INTEGER DEFAULT 0 CHECK(helpful_count >= 0),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE(product_id, user_id)  -- One review per user per product
);

CREATE INDEX idx_reviews_product ON product_reviews(product_id);
CREATE INDEX idx_reviews_rating ON product_reviews(rating);

-- ============================================================
-- INVENTORY TRACKING
-- ============================================================

CREATE TABLE inventory_transactions (
    transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    transaction_type TEXT NOT NULL CHECK(transaction_type IN ('restock', 'sale', 'return', 'adjustment')),
    quantity_change INTEGER NOT NULL,  -- Positive for additions, negative for removals
    previous_quantity INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
    reference_id INTEGER,  -- Order ID if type is 'sale'
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE INDEX idx_inventory_product ON inventory_transactions(product_id);
CREATE INDEX idx_inventory_date ON inventory_transactions(created_at);

-- ============================================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================================

-- Update product updated_at timestamp
CREATE TRIGGER update_product_timestamp 
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    UPDATE products SET updated_at = CURRENT_TIMESTAMP 
    WHERE product_id = NEW.product_id;
END;

-- Update order updated_at timestamp
CREATE TRIGGER update_order_timestamp 
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    UPDATE orders SET updated_at = CURRENT_TIMESTAMP 
    WHERE order_id = NEW.order_id;
END;

-- ============================================================
-- SAMPLE QUERIES
-- ============================================================

-- Get all products with their category names
-- SELECT p.product_name, p.price, c.category_name 
-- FROM products p 
-- JOIN categories c ON p.category_id = c.category_id 
-- WHERE p.is_active = 1;

-- Get user's order history with total amounts
-- SELECT o.order_number, o.order_status, o.total_amount, o.created_at 
-- FROM orders o 
-- WHERE o.user_id = ? 
-- ORDER BY o.created_at DESC;

-- Get product average rating
-- SELECT p.product_name, AVG(pr.rating) as avg_rating, COUNT(pr.review_id) as review_count
-- FROM products p
-- LEFT JOIN product_reviews pr ON p.product_id = pr.product_id
-- GROUP BY p.product_id;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
