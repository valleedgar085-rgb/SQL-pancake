#!/usr/bin/env python3
"""
SQL Database Manager - A tool for creating, saving, and opening high-quality SQL databases

This tool provides an easy-to-use interface for managing SQLite databases with best practices.
"""

import sqlite3
import os
import sys
import json
from datetime import datetime
from pathlib import Path


class DatabaseManager:
    """Manages SQL database operations with best practices built-in"""
    
    def __init__(self, db_path=None):
        """
        Initialize the database manager
        
        Args:
            db_path (str): Path to the database file. If None, creates in-memory database.
        """
        self.db_path = db_path
        self.conn = None
        self.cursor = None
        
    def connect(self, db_path=None):
        """
        Connect to a database
        
        Args:
            db_path (str): Path to the database file
        """
        if db_path:
            self.db_path = db_path
            
        if not self.db_path:
            raise ValueError("No database path specified")
            
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(self.db_path) if os.path.dirname(self.db_path) else '.', exist_ok=True)
        
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row  # Enable column access by name
        self.cursor = self.conn.cursor()
        
        # Enable foreign key constraints (best practice)
        self.cursor.execute("PRAGMA foreign_keys = ON")
        
        print(f"✓ Connected to database: {self.db_path}")
        return self
        
    def create_database(self, db_path, schema_file=None):
        """
        Create a new database with optional schema
        
        Args:
            db_path (str): Path where database will be created
            schema_file (str): Optional path to SQL schema file
        """
        self.db_path = db_path
        
        if os.path.exists(db_path):
            response = input(f"Database {db_path} already exists. Overwrite? (yes/no): ")
            if response.lower() != 'yes':
                print("Operation cancelled.")
                return None
            os.remove(db_path)
        
        self.connect(db_path)
        
        if schema_file and os.path.exists(schema_file):
            self.execute_schema_file(schema_file)
            
        print(f"✓ Database created: {db_path}")
        return self
        
    def execute_schema_file(self, schema_file):
        """
        Execute SQL commands from a schema file
        
        Args:
            schema_file (str): Path to SQL schema file
        """
        with open(schema_file, 'r') as f:
            schema_sql = f.read()
            
        # Use executescript which handles multi-statement SQL better
        try:
            self.conn.executescript(schema_sql)
            self.conn.commit()
            print(f"✓ Schema loaded from: {schema_file}")
        except sqlite3.Error as e:
            print(f"Error loading schema: {e}")
            # Fall back to statement-by-statement execution
            statements = [stmt.strip() for stmt in schema_sql.split(';') if stmt.strip()]
            for statement in statements:
                try:
                    self.cursor.execute(statement)
                except sqlite3.Error as stmt_error:
                    # Only print error for non-comment statements
                    if not statement.startswith('--'):
                        print(f"Warning: {stmt_error}")
            self.conn.commit()
            print(f"✓ Schema loaded from: {schema_file}")
        
    def execute_query(self, query, params=None):
        """
        Execute a SQL query with parameters (prevents SQL injection)
        
        Args:
            query (str): SQL query with ? placeholders
            params (tuple): Parameters to substitute in query
            
        Returns:
            List of results for SELECT queries, None for others
        """
        if not self.conn:
            raise RuntimeError("Not connected to a database")
            
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
                
            # If it's a SELECT or PRAGMA query, fetch results
            query_upper = query.strip().upper()
            if query_upper.startswith('SELECT') or query_upper.startswith('PRAGMA'):
                results = self.cursor.fetchall()
                return results
            else:
                self.conn.commit()
                return None
        except sqlite3.Error as e:
            print(f"SQL Error: {e}")
            return None
            
    def get_tables(self):
        """Get list of all tables in the database"""
        query = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        results = self.execute_query(query)
        return [row['name'] for row in results] if results else []
        
    def get_table_schema(self, table_name):
        """Get the schema for a specific table"""
        query = f"PRAGMA table_info({table_name})"
        return self.execute_query(query)
        
    def export_to_sql(self, output_file):
        """
        Export database to SQL file (for backup/sharing)
        
        Args:
            output_file (str): Path to output SQL file
        """
        if not self.conn:
            raise RuntimeError("Not connected to a database")
            
        with open(output_file, 'w') as f:
            for line in self.conn.iterdump():
                f.write(f'{line}\n')
                
        print(f"✓ Database exported to: {output_file}")
        
    def import_from_sql(self, sql_file):
        """
        Import SQL file into current database
        
        Args:
            sql_file (str): Path to SQL file to import
        """
        if not self.conn:
            raise RuntimeError("Not connected to a database")
            
        with open(sql_file, 'r') as f:
            sql_script = f.read()
            
        self.conn.executescript(sql_script)
        self.conn.commit()
        print(f"✓ SQL file imported: {sql_file}")
        
    def show_database_info(self):
        """Display information about the current database"""
        if not self.conn:
            print("Not connected to any database")
            return
            
        print(f"\n{'='*60}")
        print(f"Database: {self.db_path}")
        print(f"{'='*60}")
        
        tables = self.get_tables()
        print(f"\nTables ({len(tables)}):")
        
        for table in tables:
            print(f"\n  📊 {table}")
            schema = self.get_table_schema(table)
            if schema:
                print("    Columns:")
                for col in schema:
                    pk = " (PRIMARY KEY)" if col['pk'] else ""
                    notnull = " NOT NULL" if col['notnull'] else ""
                    default = f" DEFAULT {col['dflt_value']}" if col['dflt_value'] else ""
                    print(f"      - {col['name']}: {col['type']}{pk}{notnull}{default}")
                    
        print(f"\n{'='*60}\n")
        
    def close(self):
        """Close the database connection"""
        if self.conn:
            self.conn.close()
            print("✓ Database connection closed")
            

def main():
    """Main CLI interface"""
    print("""
╔═══════════════════════════════════════════════════════════╗
║         SQL Database Manager - High Quality Edition       ║
║                Create • Save • Open • Manage              ║
╚═══════════════════════════════════════════════════════════╝
    """)
    
    db_manager = DatabaseManager()
    
    while True:
        print("\nOptions:")
        print("1. Create new database")
        print("2. Open existing database")
        print("3. Show database info")
        print("4. Execute SQL query")
        print("5. Export database to SQL file")
        print("6. Import SQL file")
        print("7. Load schema from file")
        print("8. Close database")
        print("9. Exit")
        
        choice = input("\nEnter your choice (1-9): ").strip()
        
        try:
            if choice == '1':
                db_path = input("Enter database path (e.g., mydatabase.db): ").strip()
                schema_file = input("Enter schema file path (or press Enter to skip): ").strip()
                db_manager.create_database(db_path, schema_file if schema_file else None)
                
            elif choice == '2':
                db_path = input("Enter database path: ").strip()
                if os.path.exists(db_path):
                    db_manager.connect(db_path)
                else:
                    print(f"Error: Database {db_path} not found")
                    
            elif choice == '3':
                db_manager.show_database_info()
                
            elif choice == '4':
                if not db_manager.conn:
                    print("Error: No database connected")
                    continue
                    
                query = input("Enter SQL query: ").strip()
                results = db_manager.execute_query(query)
                
                if results:
                    print(f"\nResults ({len(results)} rows):")
                    for row in results:
                        print(dict(row))
                else:
                    print("✓ Query executed successfully")
                    
            elif choice == '5':
                if not db_manager.conn:
                    print("Error: No database connected")
                    continue
                output_file = input("Enter output SQL file path: ").strip()
                db_manager.export_to_sql(output_file)
                
            elif choice == '6':
                if not db_manager.conn:
                    print("Error: No database connected")
                    continue
                sql_file = input("Enter SQL file path: ").strip()
                db_manager.import_from_sql(sql_file)
                
            elif choice == '7':
                if not db_manager.conn:
                    print("Error: No database connected")
                    continue
                schema_file = input("Enter schema file path: ").strip()
                db_manager.execute_schema_file(schema_file)
                
            elif choice == '8':
                db_manager.close()
                db_manager = DatabaseManager()
                
            elif choice == '9':
                if db_manager.conn:
                    db_manager.close()
                print("\nGoodbye! Happy database designing! 🎉")
                break
                
            else:
                print("Invalid choice. Please enter 1-9.")
                
        except Exception as e:
            print(f"Error: {e}")
            import traceback
            traceback.print_exc()


if __name__ == "__main__":
    main()
