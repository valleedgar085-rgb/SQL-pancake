# Quick Start Guide - SQL-pancake 🥞

Get up and running in 5 minutes!

## Step 1: Verify Python Installation

```bash
python --version
# or
python3 --version
```

You need Python 3.6 or higher. If not installed, download from [python.org](https://www.python.org/downloads/).

## Step 2: Navigate to SQL-pancake Directory

```bash
cd SQL-pancake
```

## Step 3: Run the Database Manager

```bash
python db_manager.py
# or on some systems:
python3 db_manager.py
```

## Your First Database in 3 Minutes!

### Option A: Create with Example Schema (Recommended)

1. When the menu appears, press `1` and Enter (Create new database)
2. Type `my_ecommerce.db` and press Enter
3. Type `examples/ecommerce_schema.sql` and press Enter
4. ✅ Done! You have a professional e-commerce database

Now explore it:
- Press `3` and Enter to see all tables and their structure
- Press `4` to execute queries like: `SELECT * FROM categories`

### Option B: Create from Scratch

1. Press `1` and Enter (Create new database)
2. Type `my_first_db.db` and press Enter  
3. Just press Enter (skip schema file)
4. Press `4` to execute queries
5. Create your first table:
```sql
CREATE TABLE todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task TEXT NOT NULL,
    completed INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```
6. Press `4` again and insert data:
```sql
INSERT INTO todos (task) VALUES ('Learn SQL database design');
```
7. Press `4` again and query:
```sql
SELECT * FROM todos;
```

## Step 4: Learn Database Design

Open `TUTORIAL.md` and start reading! It covers:
- Database design principles
- Normalization
- Best practices
- Common patterns
- Real examples

## Step 5: Explore Example Schemas

Look at the three example schemas in the `examples/` directory:
- `ecommerce_schema.sql` - Online store database
- `blog_schema.sql` - Blogging platform
- `school_schema.sql` - School management system

Each demonstrates professional database design patterns.

## Common Commands Quick Reference

### In Database Manager Menu:

| Option | What it does |
|--------|--------------|
| 1 | Create new database (with or without schema) |
| 2 | Open existing database file |
| 3 | Show all tables and their structure |
| 4 | Execute SQL query (SELECT, INSERT, etc.) |
| 5 | Export database to .sql file (backup) |
| 6 | Import .sql file into current database |
| 7 | Load schema from file into current database |
| 8 | Close current database |
| 9 | Exit the program |

### Useful SQL Queries to Try:

```sql
-- See all tables
SELECT name FROM sqlite_master WHERE type='table';

-- See table structure
PRAGMA table_info(table_name);

-- Insert data
INSERT INTO table_name (column1, column2) VALUES ('value1', 'value2');

-- Query data
SELECT * FROM table_name WHERE condition;

-- Update data
UPDATE table_name SET column1 = 'new_value' WHERE condition;

-- Delete data  
DELETE FROM table_name WHERE condition;

-- Join tables
SELECT * FROM table1 
JOIN table2 ON table1.id = table2.foreign_id;
```

## Tips for Success

1. **Start Simple**: Begin with one or two tables, then expand
2. **Study Examples**: Look at the example schemas to see patterns
3. **Experiment**: Use the tool to try different designs
4. **Read the Tutorial**: `TUTORIAL.md` has everything you need to know
5. **Backup Often**: Use option 5 to export your database regularly

## Troubleshooting

**"Command not found" error?**
- Try `python3` instead of `python`
- Make sure Python is installed: `python --version`

**"No such table" error?**
- Check table name spelling
- Use option 3 to see all tables in your database

**"Syntax error" in SQL?**
- Check SQL syntax carefully
- Look at examples in the schemas for correct format

**Need to start over?**
- Delete the .db file and create a new database
- Or use option 8 to close, then option 1 to create new

## What's Next?

1. ✅ Complete the quick start above
2. 📖 Read `TUTORIAL.md` for comprehensive learning
3. 🔍 Study the example schemas
4. 🏗️ Design your own database for a project you care about
5. 💪 Practice, practice, practice!

---

**Need help?** Check the main [README.md](README.md) for more detailed information.

**Ready to learn?** Open [TUTORIAL.md](TUTORIAL.md) and become a database design expert!

🎉 Happy Learning!
