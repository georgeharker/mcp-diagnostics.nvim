"""
Database operations module for user management.
Simulates database operations with in-memory storage for testing.
"""

import sqlite3
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
import json
import threading
from contextlib import contextmanager


class DatabaseError(Exception):
    """Custom exception for database operations."""
    pass


class DatabaseConnection:
    """Database connection and operations manager."""
    
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        """Singleton pattern for database connection."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if not getattr(self, '_initialized', False):
            self.connection_string = ":memory:"  # In-memory SQLite for testing
            self.connection = None
            self.is_connected = False
            self._initialize_database()
            self._initialized = True
    
    def _initialize_database(self) -> None:
        """Initialize database schema."""
        self.connect()
        
        # Create users table
        self.execute_query('''
            CREATE TABLE IF NOT EXISTS users (
                user_id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE NOT NULL,
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                login_count INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create user_profiles table
        self.execute_query('''
            CREATE TABLE IF NOT EXISTS user_profiles (
                profile_id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                bio TEXT,
                avatar_url TEXT,
                preferences TEXT,  -- JSON string
                social_links TEXT, -- JSON string
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (user_id)
            )
        ''')
        
        # Create indexes for performance
        self.execute_query('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)')
        self.execute_query('CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON user_profiles(user_id)')
    
    def connect(self) -> bool:
        """Establish database connection."""
        try:
            if not self.is_connected:
                self.connection = sqlite3.connect(
                    self.connection_string, 
                    check_same_thread=False
                )
                self.connection.row_factory = sqlite3.Row
                self.is_connected = True
            return True
        except sqlite3.Error as e:
            raise DatabaseError(f"Connection failed: {e}")
    
    def disconnect(self) -> None:
        """Close database connection."""
        if self.connection:
            self.connection.close()
            self.is_connected = False
    
    @contextmanager
    def transaction(self):
        """Database transaction context manager."""
        if not self.is_connected:
            self.connect()
        
        try:
            yield self.connection
            self.connection.commit()
        except Exception:
            self.connection.rollback()
            raise
    
    def execute_query(self, query: str, params: tuple = ()) -> sqlite3.Cursor:
        """Execute SQL query with parameters."""
        if not self.is_connected:
            self.connect()
        
        try:
            cursor = self.connection.cursor()
            cursor.execute(query, params)
            self.connection.commit()
            return cursor
        except sqlite3.Error as e:
            raise DatabaseError(f"Query execution failed: {e}")
    
    def fetch_one(self, query: str, params: tuple = ()) -> Optional[Dict[str, Any]]:
        """Fetch single row from query result."""
        cursor = self.execute_query(query, params)
        row = cursor.fetchone()
        return dict(row) if row else None
    
    def fetch_all(self, query: str, params: tuple = ()) -> List[Dict[str, Any]]:
        """Fetch all rows from query result."""
        cursor = self.execute_query(query, params)
        rows = cursor.fetchall()
        return [dict(row) for row in rows]
    
    def create_user(self, user_data: Dict[str, Any]) -> Optional[int]:
        """Create new user in database."""
        try:
            with self.transaction():
                query = '''
                    INSERT INTO users (email, first_name, last_name, is_active, login_count)
                    VALUES (?, ?, ?, ?, ?)
                '''
                params = (
                    user_data['email'],
                    user_data['first_name'],
                    user_data['last_name'],
                    user_data.get('is_active', True),
                    user_data.get('login_count', 0)
                )
                
                cursor = self.connection.cursor()
                cursor.execute(query, params)
                return cursor.lastrowid
        except sqlite3.IntegrityError:
            raise DatabaseError(f"User with email {user_data['email']} already exists")
    
    def get_user(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Retrieve user by ID."""
        query = 'SELECT * FROM users WHERE user_id = ?'
        return self.fetch_one(query, (user_id,))
    
    def find_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Find user by email address."""
        query = 'SELECT * FROM users WHERE email = ?'
        return self.fetch_one(query, (email,))
    
    def update_user(self, user_id: int, updates: Dict[str, Any]) -> bool:
        """Update user information."""
        if not updates:
            return False
        
        # Build dynamic update query
        set_clauses = []
        params = []
        
        for field, value in updates.items():
            if field in ['email', 'first_name', 'last_name', 'is_active', 'login_count']:
                set_clauses.append(f"{field} = ?")
                params.append(value)
        
        if not set_clauses:
            return False
        
        set_clauses.append("updated_at = CURRENT_TIMESTAMP")
        params.append(user_id)
        
        query = f"UPDATE users SET {', '.join(set_clauses)} WHERE user_id = ?"
        
        try:
            cursor = self.execute_query(query, tuple(params))
            return cursor.rowcount > 0
        except sqlite3.IntegrityError:
            raise DatabaseError("Update failed due to constraint violation")
    
    def delete_user(self, user_id: int) -> bool:
        """Delete user from database."""
        with self.transaction():
            # Delete related profiles first
            self.execute_query('DELETE FROM user_profiles WHERE user_id = ?', (user_id,))
            
            # Delete user
            cursor = self.execute_query('DELETE FROM users WHERE user_id = ?', (user_id,))
            return cursor.rowcount > 0
    
    def search_users(self, 
                    email_pattern: Optional[str] = None,
                    name_pattern: Optional[str] = None,
                    is_active: Optional[bool] = None,
                    limit: int = 100) -> List[Dict[str, Any]]:
        """Search users with various criteria."""
        conditions = []
        params = []
        
        if email_pattern:
            conditions.append("email LIKE ?")
            params.append(f"%{email_pattern}%")
        
        if name_pattern:
            conditions.append("(first_name LIKE ? OR last_name LIKE ?)")
            params.extend([f"%{name_pattern}%", f"%{name_pattern}%"])
        
        if is_active is not None:
            conditions.append("is_active = ?")
            params.append(is_active)
        
        where_clause = " AND ".join(conditions) if conditions else "1=1"
        query = f"SELECT * FROM users WHERE {where_clause} LIMIT ?"
        params.append(limit)
        
        return self.fetch_all(query, tuple(params))
    
    def get_user_statistics(self) -> Dict[str, Any]:
        """Get database statistics."""
        stats = {}
        
        # Total users
        result = self.fetch_one("SELECT COUNT(*) as total FROM users")
        stats['total_users'] = result['total'] if result else 0
        
        # Active users
        result = self.fetch_one("SELECT COUNT(*) as active FROM users WHERE is_active = 1")
        stats['active_users'] = result['active'] if result else 0
        
        # Users by login count
        stats['login_stats'] = self.fetch_all('''
            SELECT 
                CASE 
                    WHEN login_count = 0 THEN 'never_logged_in'
                    WHEN login_count < 5 THEN 'low_activity'
                    WHEN login_count < 20 THEN 'medium_activity'
                    ELSE 'high_activity'
                END as category,
                COUNT(*) as count
            FROM users
            GROUP BY category
        ''')
        
        return stats
    
    def create_user_profile(self, profile_data: Dict[str, Any]) -> Optional[int]:
        """Create user profile."""
        try:
            with self.transaction():
                query = '''
                    INSERT INTO user_profiles (user_id, bio, avatar_url, preferences, social_links)
                    VALUES (?, ?, ?, ?, ?)
                '''
                params = (
                    profile_data['user_id'],
                    profile_data.get('bio'),
                    profile_data.get('avatar_url'),
                    json.dumps(profile_data.get('preferences', {})),
                    json.dumps(profile_data.get('social_links', []))
                )
                
                cursor = self.connection.cursor()
                cursor.execute(query, params)
                return cursor.lastrowid
        except sqlite3.IntegrityError:
            raise DatabaseError("Profile creation failed")
    
    def get_user_profile(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Get user profile by user ID."""
        query = 'SELECT * FROM user_profiles WHERE user_id = ?'
        profile = self.fetch_one(query, (user_id,))
        
        if profile:
            # Parse JSON fields
            profile['preferences'] = json.loads(profile['preferences'] or '{}')
            profile['social_links'] = json.loads(profile['social_links'] or '[]')
        
        return profile
    
    def update_user_profile(self, user_id: int, updates: Dict[str, Any]) -> bool:
        """Update user profile."""
        if not updates:
            return False
        
        # Serialize JSON fields
        if 'preferences' in updates:
            updates['preferences'] = json.dumps(updates['preferences'])
        if 'social_links' in updates:
            updates['social_links'] = json.dumps(updates['social_links'])
        
        set_clauses = []
        params = []
        
        for field, value in updates.items():
            if field in ['bio', 'avatar_url', 'preferences', 'social_links']:
                set_clauses.append(f"{field} = ?")
                params.append(value)
        
        if not set_clauses:
            return False
        
        set_clauses.append("updated_at = CURRENT_TIMESTAMP")
        params.append(user_id)
        
        query = f"UPDATE user_profiles SET {', '.join(set_clauses)} WHERE user_id = ?"
        
        cursor = self.execute_query(query, tuple(params))
        return cursor.rowcount > 0
    
    def clear_all_data(self) -> None:
        """Clear all data (for testing purposes)."""
        with self.transaction():
            self.execute_query('DELETE FROM user_profiles')
            self.execute_query('DELETE FROM users')
            self.execute_query('DELETE FROM sqlite_sequence')  # Reset auto-increment