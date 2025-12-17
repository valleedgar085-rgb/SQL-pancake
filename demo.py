#!/usr/bin/env python3
"""
Demo script - Shows how to use DatabaseManager programmatically
"""

from db_manager import DatabaseManager
import os

def demo():
    print("=" * 70)
    print("SQL-PANCAKE DEMONSTRATION")
    print("Creating a High-Quality Database with Best Practices")
    print("=" * 70)
    
    # Create a demo database
    print("\n📁 Step 1: Creating a new database...")
    db = DatabaseManager()
    demo_db = "/tmp/demo_library.db"
    
    if os.path.exists(demo_db):
        os.remove(demo_db)
    
    db.create_database(demo_db)
    
    # Create tables with best practices
    print("\n📊 Step 2: Creating tables with best practices...")
    
    # Authors table
    db.execute_query("""
        CREATE TABLE authors (
            author_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            country TEXT,
            birth_year INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    print("  ✓ Created 'authors' table")
    
    # Books table with foreign key
    db.execute_query("""
        CREATE TABLE books (
            book_id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            author_id INTEGER NOT NULL,
            isbn TEXT UNIQUE,
            published_year INTEGER CHECK(published_year >= 1000 AND published_year <= 2100),
            genre TEXT,
            price REAL CHECK(price >= 0),
            stock INTEGER DEFAULT 0 CHECK(stock >= 0),
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
        )
    """)
    print("  ✓ Created 'books' table with foreign key constraint")
    
    # Create index for performance
    db.execute_query("CREATE INDEX idx_books_author ON books(author_id)")
    db.execute_query("CREATE INDEX idx_books_genre ON books(genre)")
    print("  ✓ Created indexes for better query performance")
    
    # Insert sample data
    print("\n📝 Step 3: Inserting sample data with parameterized queries...")
    
    # Insert authors (safe from SQL injection!)
    authors = [
        ("J.K. Rowling", "United Kingdom", 1965),
        ("George Orwell", "United Kingdom", 1903),
        ("Gabriel García Márquez", "Colombia", 1927)
    ]
    
    for name, country, birth_year in authors:
        db.execute_query(
            "INSERT INTO authors (name, country, birth_year) VALUES (?, ?, ?)",
            (name, country, birth_year)
        )
    print(f"  ✓ Inserted {len(authors)} authors")
    
    # Insert books
    books = [
        ("Harry Potter and the Philosopher's Stone", 1, "978-0439708180", 1997, "Fantasy", 29.99, 50),
        ("1984", 2, "978-0451524935", 1949, "Dystopian", 15.99, 30),
        ("Animal Farm", 2, "978-0451526342", 1945, "Political Fiction", 12.99, 25),
        ("One Hundred Years of Solitude", 3, "978-0060883287", 1967, "Magical Realism", 18.99, 20)
    ]
    
    for title, author_id, isbn, year, genre, price, stock in books:
        db.execute_query(
            """INSERT INTO books (title, author_id, isbn, published_year, genre, price, stock) 
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (title, author_id, isbn, year, genre, price, stock)
        )
    print(f"  ✓ Inserted {len(books)} books")
    
    # Query and display data
    print("\n🔍 Step 4: Querying data with JOIN...")
    results = db.execute_query("""
        SELECT 
            b.title,
            a.name as author,
            b.published_year,
            b.genre,
            b.price,
            b.stock
        FROM books b
        JOIN authors a ON b.author_id = a.author_id
        ORDER BY b.published_year DESC
    """)
    
    print("\n  📚 Library Catalog:")
    print("  " + "-" * 100)
    print(f"  {'Title':<45} {'Author':<25} {'Year':<6} {'Genre':<20} {'Price':<8} {'Stock'}")
    print("  " + "-" * 100)
    
    for row in results:
        print(f"  {row['title']:<45} {row['author']:<25} {row['published_year']:<6} {row['genre']:<20} ${row['price']:<7.2f} {row['stock']}")
    print("  " + "-" * 100)
    
    # Demonstrate aggregation
    print("\n📊 Step 5: Running aggregation queries...")
    
    # Books by genre
    genre_stats = db.execute_query("""
        SELECT genre, COUNT(*) as book_count, AVG(price) as avg_price
        FROM books
        GROUP BY genre
        ORDER BY book_count DESC
    """)
    
    print("\n  Books by Genre:")
    for row in genre_stats:
        print(f"    - {row['genre']}: {row['book_count']} books, avg price: ${row['avg_price']:.2f}")
    
    # Books per author
    author_stats = db.execute_query("""
        SELECT a.name, COUNT(b.book_id) as book_count
        FROM authors a
        LEFT JOIN books b ON a.author_id = b.author_id
        GROUP BY a.author_id
        ORDER BY book_count DESC
    """)
    
    print("\n  Books per Author:")
    for row in author_stats:
        print(f"    - {row['name']}: {row['book_count']} book(s)")
    
    # Show database structure
    print("\n🏗️  Step 6: Database structure overview...")
    db.show_database_info()
    
    # Export database
    print("\n💾 Step 7: Exporting database for backup...")
    export_file = "/tmp/library_backup.sql"
    db.export_to_sql(export_file)
    
    # Show file size
    file_size = os.path.getsize(demo_db)
    export_size = os.path.getsize(export_file)
    print(f"  Database file size: {file_size:,} bytes")
    print(f"  Export file size: {export_size:,} bytes")
    
    # Close connection
    print("\n🔒 Step 8: Closing database connection...")
    db.close()
    
    print("\n" + "=" * 70)
    print("✅ DEMONSTRATION COMPLETE!")
    print("=" * 70)
    print("\nWhat we demonstrated:")
    print("  ✓ Database creation with best practices")
    print("  ✓ Tables with primary keys, foreign keys, and constraints")
    print("  ✓ Indexes for performance optimization")
    print("  ✓ Parameterized queries (SQL injection protection)")
    print("  ✓ Complex JOIN queries")
    print("  ✓ Aggregation and grouping")
    print("  ✓ Database export for backup")
    print("\nYour database is ready at:", demo_db)
    print("Export file available at:", export_file)
    print("\n💡 You can now open it with: python db_manager.py")
    print("=" * 70)

if __name__ == "__main__":
    demo()
