# SQL Database Design Tutorial - Creating High-Quality Databases

Welcome to the SQL Database Design Tutorial! This guide will teach you how to create top-notch, high-quality SQL databases with precision and best practices.

## Table of Contents

1. [Introduction to Database Design](#introduction-to-database-design)
2. [Database Design Principles](#database-design-principles)
3. [Normalization](#normalization)
4. [Data Types and Constraints](#data-types-and-constraints)
5. [Indexes and Performance](#indexes-and-performance)
6. [Best Practices](#best-practices)
7. [Common Patterns](#common-patterns)
8. [Examples](#examples)

---

## Introduction to Database Design

A well-designed database is:
- **Efficient**: Fast queries and minimal storage waste
- **Maintainable**: Easy to update and modify
- **Accurate**: Data integrity through constraints
- **Scalable**: Can grow with your needs

### Key Concepts

1. **Tables**: Store data in rows and columns
2. **Primary Keys**: Unique identifier for each row
3. **Foreign Keys**: Link tables together
4. **Constraints**: Rules that ensure data quality
5. **Indexes**: Speed up data retrieval

---

## Database Design Principles

### 1. Plan Before You Code

Always start with:
- **Requirements Analysis**: What data do you need to store?
- **Entity Relationship Diagram (ERD)**: Visual representation of your data
- **Naming Conventions**: Consistent, clear names

### 2. ACID Properties

High-quality databases follow ACID:
- **Atomicity**: Transactions are all-or-nothing
- **Consistency**: Data follows all rules
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed data persists

### 3. Data Integrity

Ensure data quality with:
- Primary keys (uniqueness)
- Foreign keys (relationships)
- NOT NULL constraints (required fields)
- CHECK constraints (valid values)
- UNIQUE constraints (no duplicates)

---

## Normalization

Normalization eliminates redundancy and improves data integrity.

### First Normal Form (1NF)
- Each column contains atomic (indivisible) values
- Each row is unique
- No repeating groups

**Bad Example:**
```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT,
    courses TEXT  -- "Math, Science, English" - NOT ATOMIC!
);
```

**Good Example:**
```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE courses (
    id INTEGER PRIMARY KEY,
    course_name TEXT NOT NULL
);

CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);
```

### Second Normal Form (2NF)
- Must be in 1NF
- All non-key attributes depend on the entire primary key

### Third Normal Form (3NF)
- Must be in 2NF
- No transitive dependencies (non-key attributes don't depend on other non-key attributes)

**Bad Example:**
```sql
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    customer_name TEXT,  -- Depends on customer_id, not order_id!
    customer_address TEXT  -- Same issue!
);
```

**Good Example:**
```sql
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    customer_address TEXT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

---

## Data Types and Constraints

### Choosing the Right Data Type

**SQLite Data Types:**
- `INTEGER`: Whole numbers (use for IDs, counts)
- `REAL`: Floating-point numbers
- `TEXT`: Text strings
- `BLOB`: Binary data (images, files)
- `DATE/DATETIME`: Dates and times

**Precision Tips:**
```sql
-- Good: Specific and efficient
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL CHECK(price >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK(stock >= 0),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Essential Constraints

```sql
CREATE TABLE users (
    -- PRIMARY KEY: Unique identifier
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- NOT NULL: Required field
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    
    -- UNIQUE: No duplicates allowed
    UNIQUE(username),
    UNIQUE(email),
    
    -- CHECK: Validate values
    age INTEGER CHECK(age >= 18),
    
    -- DEFAULT: Set default value
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## Indexes and Performance

Indexes speed up queries but slow down inserts. Use them wisely!

### When to Use Indexes

✅ **Good candidates:**
- Primary keys (automatic in SQLite)
- Foreign keys
- Columns used in WHERE clauses
- Columns used in JOIN operations
- Columns used in ORDER BY

❌ **Avoid indexes on:**
- Small tables
- Columns with many duplicate values
- Columns rarely used in queries

### Creating Indexes

```sql
-- Single column index
CREATE INDEX idx_users_email ON users(email);

-- Multi-column index (order matters!)
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Unique index
CREATE UNIQUE INDEX idx_products_sku ON products(sku);
```

---

## Best Practices

### 1. Naming Conventions

```sql
-- ✅ Good: Clear, consistent names
CREATE TABLE customer_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date DATE
);

-- ❌ Bad: Unclear, inconsistent
CREATE TABLE tbl1 (
    id INTEGER,
    cid INTEGER,
    dt DATE
);
```

### 2. Always Use Transactions

```sql
-- Ensures data consistency
BEGIN TRANSACTION;
    INSERT INTO accounts (user_id, balance) VALUES (1, 100);
    UPDATE accounts SET balance = balance - 50 WHERE user_id = 1;
COMMIT;
```

### 3. Enable Foreign Key Constraints

```sql
-- SQLite requires this to be enabled
PRAGMA foreign_keys = ON;
```

### 4. Use Parameterized Queries (Prevents SQL Injection!)

```python
# ❌ DANGEROUS: SQL Injection risk
user_input = "admin' OR '1'='1"
cursor.execute(f"SELECT * FROM users WHERE username = '{user_input}'")

# ✅ SAFE: Parameterized query
cursor.execute("SELECT * FROM users WHERE username = ?", (user_input,))
```

### 5. Add Comments and Documentation

```sql
-- User authentication and profile table
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,  -- Login identifier
    password_hash TEXT NOT NULL,     -- Hashed password (never store plain text!)
    email TEXT NOT NULL UNIQUE,      -- Contact email
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## Common Patterns

### Pattern 1: One-to-Many Relationship

```sql
-- One author can write many books
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    author_id INTEGER NOT NULL,
    published_year INTEGER,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);
```

### Pattern 2: Many-to-Many Relationship

```sql
-- Students can enroll in many courses, courses have many students
CREATE TABLE students (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE courses (
    course_id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_name TEXT NOT NULL
);

-- Junction table
CREATE TABLE enrollments (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);
```

### Pattern 3: Audit Trail

```sql
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    updated_by INTEGER
);

-- Trigger to update timestamp
CREATE TRIGGER update_product_timestamp 
AFTER UPDATE ON products
BEGIN
    UPDATE products SET updated_at = CURRENT_TIMESTAMP 
    WHERE product_id = NEW.product_id;
END;
```

### Pattern 4: Soft Delete

```sql
-- Don't actually delete data, mark as deleted
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    is_deleted INTEGER DEFAULT 0,  -- 0 = active, 1 = deleted
    deleted_at DATETIME
);

-- Query only active users
SELECT * FROM users WHERE is_deleted = 0;
```

---

## Examples

### Example 1: E-commerce Database

See `examples/ecommerce_schema.sql` for a complete e-commerce database schema.

### Example 2: Blog Platform

See `examples/blog_schema.sql` for a blogging platform database.

### Example 3: School Management

See `examples/school_schema.sql` for a school management system.

---

## Next Steps

1. **Practice**: Start with simple schemas and gradually increase complexity
2. **Review**: Study existing database designs (open-source projects)
3. **Test**: Always test your queries for performance
4. **Iterate**: Database design is iterative - don't be afraid to refactor
5. **Use Tools**: Leverage the included `db_manager.py` tool to practice

---

## Resources

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Database Normalization](https://en.wikipedia.org/wiki/Database_normalization)
- [SQL Best Practices](https://www.sqlstyle.guide/)

---

## Quick Reference

### Common SQL Commands

```sql
-- Create table
CREATE TABLE table_name (column definitions);

-- Insert data
INSERT INTO table_name (col1, col2) VALUES (val1, val2);

-- Query data
SELECT * FROM table_name WHERE condition;

-- Update data
UPDATE table_name SET col1 = val1 WHERE condition;

-- Delete data
DELETE FROM table_name WHERE condition;

-- Join tables
SELECT * FROM table1 
INNER JOIN table2 ON table1.id = table2.foreign_id;
```

---

**Remember**: A well-designed database is the foundation of any great application. Take time to plan, normalize, and test your schema before adding data!
