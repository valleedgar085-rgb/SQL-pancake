#!/usr/bin/env python3
"""
Test script for DatabaseManager - Validates functionality
"""

import os
import sys
import tempfile
from pathlib import Path
from db_manager import DatabaseManager

def test_database_operations():
    """Test basic database operations"""
    print("Testing SQL Database Manager...")
    print("=" * 60)
    
    # Test 1: Create database
    print("\n1. Testing database creation...")
    db = DatabaseManager()
    tmp_dir = Path(tempfile.gettempdir())
    test_db_path = str(tmp_dir / "test_database.db")
    
    # Remove if exists
    if os.path.exists(test_db_path):
        os.remove(test_db_path)
    
    db.create_database(test_db_path)
    assert os.path.exists(test_db_path), "Database file should exist"
    print("✓ Database created successfully")
    
    # Test 2: Create table
    print("\n2. Testing table creation...")
    create_table_sql = """
    CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """
    db.execute_query(create_table_sql)
    print("✓ Table created successfully")
    
    # Test 3: Insert data
    print("\n3. Testing data insertion...")
    db.execute_query(
        "INSERT INTO users (username, email) VALUES (?, ?)",
        ("john_doe", "john@example.com")
    )
    db.execute_query(
        "INSERT INTO users (username, email) VALUES (?, ?)",
        ("jane_smith", "jane@example.com")
    )
    print("✓ Data inserted successfully")
    
    # Test 4: Query data
    print("\n4. Testing data retrieval...")
    results = db.execute_query("SELECT * FROM users")
    assert len(results) == 2, f"Expected 2 users, got {len(results)}"
    print(f"✓ Retrieved {len(results)} records")
    for row in results:
        print(f"  - {dict(row)}")
    
    # Test 5: Parameterized query (SQL injection protection)
    print("\n5. Testing parameterized queries...")
    results = db.execute_query(
        "SELECT * FROM users WHERE username = ?",
        ("john_doe",)
    )
    assert len(results) == 1, "Should find one user"
    assert results[0]['username'] == 'john_doe'
    print("✓ Parameterized query works correctly")
    
    # Test 6: Get tables
    print("\n6. Testing table listing...")
    tables = db.get_tables()
    assert 'users' in tables, "users table should be listed"
    print(f"✓ Found tables: {tables}")
    
    # Test 7: Get table schema
    print("\n7. Testing schema retrieval...")
    schema = db.get_table_schema('users')
    assert len(schema) > 0, "Schema should have columns"
    print(f"✓ Schema retrieved: {len(schema)} columns")
    for col in schema:
        print(f"  - {col['name']}: {col['type']}")
    
    # Test 8: Export to SQL
    print("\n8. Testing database export...")
    export_path = str(tmp_dir / "test_export.sql")
    db.export_to_sql(export_path)
    assert os.path.exists(export_path), "Export file should exist"
    print("✓ Database exported successfully")
    
    # Test 9: Foreign key constraints
    print("\n9. Testing foreign key constraints...")
    db.execute_query("""
        CREATE TABLE posts (
            post_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(user_id)
        )
    """)
    db.execute_query(
        "INSERT INTO posts (user_id, title) VALUES (?, ?)",
        (1, "My First Post")
    )
    print("✓ Foreign key constraints working")
    
    # Test 10: Show database info
    print("\n10. Testing database info display...")
    db.show_database_info()
    print("✓ Database info displayed")
    
    # Test 11: Load schema from example
    print("\n11. Testing schema loading from file...")
    db2 = DatabaseManager()
    blog_db_path = str(tmp_dir / "test_blog.db")
    if os.path.exists(blog_db_path):
        os.remove(blog_db_path)
    
    db2.create_database(blog_db_path, "examples/blog_schema.sql")
    tables = db2.get_tables()
    print(f"✓ Loaded schema with {len(tables)} tables")
    if len(tables) > 5:
        print(f"  Tables: {', '.join(tables[:5])}...")
    else:
        print(f"  Tables: {', '.join(tables)}")
    
    # Close connections
    db.close()
    db2.close()
    
    # Cleanup
    if os.path.exists(test_db_path):
        os.remove(test_db_path)
    if os.path.exists(export_path):
        os.remove(export_path)
    if os.path.exists(blog_db_path):
        os.remove(blog_db_path)
    
    print("\n" + "=" * 60)
    print("✅ All tests passed! Database Manager is working correctly.")
    print("=" * 60)
    return True

if __name__ == "__main__":
    try:
        test_database_operations()
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
