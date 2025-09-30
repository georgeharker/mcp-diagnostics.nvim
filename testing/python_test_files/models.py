"""
User and data models for the application.
Demonstrates classes, inheritance, and type hints for LSP testing.
"""

from typing import Optional, Dict, Any, List
from datetime import datetime
import json
from .validators import EmailValidator, PasswordValidator
from .database import DatabaseConnection


class BaseModel:
    """Base model class with common functionality."""
    
    def __init__(self):
        self.created_at = datetime.now()
        self.updated_at = datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert model to dictionary representation."""
        return {
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    def update_timestamp(self) -> None:
        """Update the modified timestamp."""
        self.updated_at = datetime.now()


class User(BaseModel):
    """User model with validation and database operations."""
    
    def __init__(self, email: str, first_name: str, last_name: str, user_id: Optional[int] = None):
        super().__init__()
        self.user_id = user_id
        self.email = email
        self.first_name = first_name
        self.last_name = last_name
        self.is_active = True
        self.login_count = 0
        
        # Validate email on creation
        if not EmailValidator.is_valid(email):
            raise ValueError(f"Invalid email format: {email}")
    
    @property
    def full_name(self) -> str:
        """Get user's full name."""
        return f"{self.first_name} {self.last_name}"
    
    @property
    def display_name(self) -> str:
        """Get user's display name with email."""
        return f"{self.full_name} <{self.email}>"
    
    def update_email(self, new_email: str) -> bool:
        """Update user email with validation."""
        if not EmailValidator.is_valid(new_email):
            return False
        
        self.email = new_email
        self.update_timestamp()
        return True
    
    def set_password(self, password: str) -> bool:
        """Set user password with validation."""
        validator = PasswordValidator()
        is_valid, error_message = validator.validate(password)
        
        if not is_valid:
            raise ValueError(f"Password validation failed: {error_message}")
        
        # In real app, would hash password
        self._password_hash = hash(password)
        self.update_timestamp()
        return True
    
    def increment_login(self) -> None:
        """Increment login counter."""
        self.login_count += 1
        self.update_timestamp()
    
    def deactivate(self) -> None:
        """Deactivate the user account."""
        self.is_active = False
        self.update_timestamp()
    
    def save(self) -> bool:
        """Save user to database."""
        db = DatabaseConnection()
        if self.user_id:
            return db.update_user(self.user_id, self.to_dict())
        else:
            self.user_id = db.create_user(self.to_dict())
            return self.user_id is not None
    
    @classmethod
    def load_by_id(cls, user_id: int) -> Optional['User']:
        """Load user from database by ID."""
        db = DatabaseConnection()
        user_data = db.get_user(user_id)
        
        if not user_data:
            return None
        
        user = cls(
            email=user_data['email'],
            first_name=user_data['first_name'],
            last_name=user_data['last_name'],
            user_id=user_data['user_id']
        )
        user.is_active = user_data.get('is_active', True)
        user.login_count = user_data.get('login_count', 0)
        
        return user
    
    @classmethod
    def load_by_email(cls, email: str) -> Optional['User']:
        """Load user from database by email."""
        db = DatabaseConnection()
        user_data = db.find_user_by_email(email)
        
        if not user_data:
            return None
        
        return cls.load_by_id(user_data['user_id'])
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert user to dictionary representation."""
        data = super().to_dict()
        data.update({
            'user_id': self.user_id,
            'email': self.email,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': self.full_name,
            'is_active': self.is_active,
            'login_count': self.login_count
        })
        return data
    
    def to_json(self) -> str:
        """Convert user to JSON string."""
        return json.dumps(self.to_dict(), default=str)
    
    def __str__(self) -> str:
        return self.display_name
    
    def __repr__(self) -> str:
        return f"User(id={self.user_id}, email='{self.email}', name='{self.full_name}')"


class UserProfile(BaseModel):
    """Extended user profile with additional information."""
    
    def __init__(self, user: User):
        super().__init__()
        self.user = user
        self.bio: Optional[str] = None
        self.avatar_url: Optional[str] = None
        self.preferences: Dict[str, Any] = {}
        self.social_links: List[str] = []
    
    def update_bio(self, bio: str) -> None:
        """Update user bio."""
        if len(bio) > 500:
            raise ValueError("Bio too long (max 500 characters)")
        self.bio = bio
        self.update_timestamp()
    
    def add_social_link(self, url: str) -> None:
        """Add social media link."""
        from .validators import URLValidator
        
        if not URLValidator.is_valid(url):
            raise ValueError(f"Invalid URL: {url}")
        
        if url not in self.social_links:
            self.social_links.append(url)
            self.update_timestamp()
    
    def set_preference(self, key: str, value: Any) -> None:
        """Set user preference."""
        self.preferences[key] = value
        self.update_timestamp()
    
    def get_preference(self, key: str, default: Any = None) -> Any:
        """Get user preference."""
        return self.preferences.get(key, default)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert profile to dictionary."""
        data = super().to_dict()
        data.update({
            'user': self.user.to_dict(),
            'bio': self.bio,
            'avatar_url': self.avatar_url,
            'preferences': self.preferences,
            'social_links': self.social_links
        })
        return data