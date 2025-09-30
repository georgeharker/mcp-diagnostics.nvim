"""
Business logic services for user management.
Demonstrates service patterns and comprehensive cross-module dependencies.
"""

from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime, timedelta
import hashlib
import secrets
from .models import User, UserProfile
from .validators import EmailValidator, PasswordValidator, ValidationError
from .database import DatabaseConnection, DatabaseError


class UserService:
    """Business logic service for user operations."""
    
    def __init__(self):
        self.db = DatabaseConnection()
        self.password_validator = PasswordValidator()
    
    def create_user(self, 
                   email: str, 
                   first_name: str, 
                   last_name: str, 
                   password: str) -> Tuple[Optional[User], Optional[str]]:
        """Create a new user with validation."""
        
        # Validate email
        email_valid, email_error = EmailValidator.validate_with_details(email)
        if not email_valid:
            return None, email_error
        
        # Normalize email
        email = EmailValidator.normalize(email)
        
        # Check if user already exists
        if self.get_user_by_email(email):
            return None, f"User with email {email} already exists"
        
        # Validate password
        password_valid, password_error = self.password_validator.validate(password)
        if not password_valid:
            return None, password_error
        
        # Create user instance
        try:
            user = User(email=email, first_name=first_name, last_name=last_name)
            user.set_password(password)
            
            # Save to database
            if user.save():
                return user, None
            else:
                return None, "Failed to save user to database"
                
        except (ValueError, DatabaseError) as e:
            return None, str(e)
    
    def get_user_by_id(self, user_id: int) -> Optional[User]:
        """Retrieve user by ID."""
        try:
            return User.load_by_id(user_id)
        except DatabaseError:
            return None
    
    def get_user_by_email(self, email: str) -> Optional[User]:
        """Retrieve user by email."""
        try:
            normalized_email = EmailValidator.normalize(email)
            return User.load_by_email(normalized_email)
        except DatabaseError:
            return None
    
    def update_user_email(self, user_id: int, new_email: str) -> Tuple[bool, Optional[str]]:
        """Update user email with validation."""
        user = self.get_user_by_id(user_id)
        if not user:
            return False, "User not found"
        
        # Validate new email
        email_valid, email_error = EmailValidator.validate_with_details(new_email)
        if not email_valid:
            return False, email_error
        
        # Check if email is already taken
        normalized_email = EmailValidator.normalize(new_email)
        existing_user = self.get_user_by_email(normalized_email)
        if existing_user and existing_user.user_id != user_id:
            return False, "Email already in use by another user"
        
        # Update email
        success = user.update_email(normalized_email)
        if success:
            user.save()
            return True, None
        else:
            return False, "Failed to update email"
    
    def authenticate_user(self, email: str, password: str) -> Tuple[Optional[User], Optional[str]]:
        """Authenticate user with email and password."""
        user = self.get_user_by_email(email)
        if not user:
            return None, "Invalid email or password"
        
        if not user.is_active:
            return None, "Account is deactivated"
        
        # In a real app, would verify password hash
        # For testing, we'll accept any password for existing users
        user.increment_login()
        user.save()
        
        return user, None
    
    def deactivate_user(self, user_id: int) -> Tuple[bool, Optional[str]]:
        """Deactivate user account."""
        user = self.get_user_by_id(user_id)
        if not user:
            return False, "User not found"
        
        user.deactivate()
        user.save()
        return True, None
    
    def search_users(self, 
                    query: str = "",
                    is_active: Optional[bool] = None,
                    limit: int = 50) -> List[User]:
        """Search users by various criteria."""
        users = []
        
        try:
            # Search by email or name
            results = self.db.search_users(
                email_pattern=query if '@' in query else None,
                name_pattern=query if '@' not in query else None,
                is_active=is_active,
                limit=limit
            )
            
            for user_data in results:
                user = User(
                    email=user_data['email'],
                    first_name=user_data['first_name'],
                    last_name=user_data['last_name'],
                    user_id=user_data['user_id']
                )
                user.is_active = user_data['is_active']
                user.login_count = user_data['login_count']
                users.append(user)
                
        except DatabaseError:
            pass
        
        return users
    
    def get_user_statistics(self) -> Dict[str, Any]:
        """Get user management statistics."""
        try:
            return self.db.get_user_statistics()
        except DatabaseError:
            return {
                'total_users': 0,
                'active_users': 0,
                'login_stats': []
            }


class ProfileService:
    """Service for managing user profiles."""
    
    def __init__(self):
        self.db = DatabaseConnection()
        self.user_service = UserService()
    
    def create_profile(self, user_id: int) -> Tuple[Optional[UserProfile], Optional[str]]:
        """Create a user profile."""
        user = self.user_service.get_user_by_id(user_id)
        if not user:
            return None, "User not found"
        
        # Check if profile already exists
        existing_profile = self.get_profile(user_id)
        if existing_profile:
            return None, "Profile already exists for this user"
        
        try:
            profile = UserProfile(user)
            
            # Save to database
            profile_data = {
                'user_id': user_id,
                'bio': profile.bio,
                'avatar_url': profile.avatar_url,
                'preferences': profile.preferences,
                'social_links': profile.social_links
            }
            
            profile_id = self.db.create_user_profile(profile_data)
            if profile_id:
                return profile, None
            else:
                return None, "Failed to create profile"
                
        except (ValueError, DatabaseError) as e:
            return None, str(e)
    
    def get_profile(self, user_id: int) -> Optional[UserProfile]:
        """Get user profile by user ID."""
        try:
            user = self.user_service.get_user_by_id(user_id)
            if not user:
                return None
            
            profile_data = self.db.get_user_profile(user_id)
            if not profile_data:
                return None
            
            profile = UserProfile(user)
            profile.bio = profile_data.get('bio')
            profile.avatar_url = profile_data.get('avatar_url')
            profile.preferences = profile_data.get('preferences', {})
            profile.social_links = profile_data.get('social_links', [])
            
            return profile
            
        except DatabaseError:
            return None
    
    def update_profile_bio(self, user_id: int, bio: str) -> Tuple[bool, Optional[str]]:
        """Update user profile bio."""
        profile = self.get_profile(user_id)
        if not profile:
            return False, "Profile not found"
        
        try:
            profile.update_bio(bio)
            success = self.db.update_user_profile(user_id, {'bio': bio})
            return success, None if success else "Failed to update bio"
            
        except ValueError as e:
            return False, str(e)
    
    def add_social_link(self, user_id: int, url: str) -> Tuple[bool, Optional[str]]:
        """Add social media link to profile."""
        profile = self.get_profile(user_id)
        if not profile:
            return False, "Profile not found"
        
        try:
            profile.add_social_link(url)
            success = self.db.update_user_profile(user_id, {
                'social_links': profile.social_links
            })
            return success, None if success else "Failed to add social link"
            
        except ValueError as e:
            return False, str(e)
    
    def update_preference(self, user_id: int, key: str, value: Any) -> Tuple[bool, Optional[str]]:
        """Update user preference."""
        profile = self.get_profile(user_id)
        if not profile:
            return False, "Profile not found"
        
        profile.set_preference(key, value)
        success = self.db.update_user_profile(user_id, {
            'preferences': profile.preferences
        })
        return success, None if success else "Failed to update preference"


class SessionService:
    """Service for managing user sessions."""
    
    def __init__(self):
        self.user_service = UserService()
        self.active_sessions: Dict[str, Dict[str, Any]] = {}
        self.session_timeout = timedelta(hours=24)
    
    def create_session(self, user: User) -> str:
        """Create a new user session."""
        session_id = secrets.token_urlsafe(32)
        
        self.active_sessions[session_id] = {
            'user_id': user.user_id,
            'user_email': user.email,
            'created_at': datetime.now(),
            'last_activity': datetime.now(),
            'ip_address': None  # Would be set by web framework
        }
        
        return session_id
    
    def get_session_user(self, session_id: str) -> Optional[User]:
        """Get user from session ID."""
        session = self.active_sessions.get(session_id)
        if not session:
            return None
        
        # Check if session has expired
        if datetime.now() - session['last_activity'] > self.session_timeout:
            self.destroy_session(session_id)
            return None
        
        # Update last activity
        session['last_activity'] = datetime.now()
        
        return self.user_service.get_user_by_id(session['user_id'])
    
    def destroy_session(self, session_id: str) -> bool:
        """Destroy user session."""
        if session_id in self.active_sessions:
            del self.active_sessions[session_id]
            return True
        return False
    
    def get_user_sessions(self, user_id: int) -> List[Dict[str, Any]]:
        """Get all active sessions for a user."""
        user_sessions = []
        
        for session_id, session_data in self.active_sessions.items():
            if session_data['user_id'] == user_id:
                user_sessions.append({
                    'session_id': session_id,
                    'created_at': session_data['created_at'],
                    'last_activity': session_data['last_activity'],
                    'ip_address': session_data.get('ip_address')
                })
        
        return user_sessions
    
    def cleanup_expired_sessions(self) -> int:
        """Remove expired sessions and return count removed."""
        current_time = datetime.now()
        expired_sessions = []
        
        for session_id, session_data in self.active_sessions.items():
            if current_time - session_data['last_activity'] > self.session_timeout:
                expired_sessions.append(session_id)
        
        for session_id in expired_sessions:
            del self.active_sessions[session_id]
        
        return len(expired_sessions)