"""
Main application entry point for user management system.
Demonstrates comprehensive cross-module usage and application patterns.
"""

import sys
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from .models import User, UserProfile
from .services import UserService, ProfileService, SessionService
from .validators import EmailValidator, PasswordValidator
from .database import DatabaseConnection, DatabaseError


class UserManagementApp:
    """Main application class for user management system."""
    
    def __init__(self, debug_mode: bool = False):
        self.debug_mode = debug_mode
        self.setup_logging()
        
        # Initialize services
        self.user_service = UserService()
        self.profile_service = ProfileService()
        self.session_service = SessionService()
        
        # Application state
        self.is_running = False
        self.current_user: Optional[User] = None
        self.current_session: Optional[str] = None
        
        self.logger.info("UserManagementApp initialized")
    
    def setup_logging(self) -> None:
        """Setup application logging."""
        log_level = logging.DEBUG if self.debug_mode else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler('user_app.log') if not self.debug_mode else logging.NullHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def start(self) -> bool:
        """Start the application."""
        try:
            self.logger.info("Starting UserManagementApp...")
            
            # Initialize database connection
            db = DatabaseConnection()
            if not db.is_connected:
                db.connect()
            
            self.is_running = True
            self.logger.info("Application started successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start application: {e}")
            return False
    
    def stop(self) -> None:
        """Stop the application."""
        self.logger.info("Stopping UserManagementApp...")
        
        # Cleanup sessions
        expired_count = self.session_service.cleanup_expired_sessions()
        self.logger.info(f"Cleaned up {expired_count} expired sessions")
        
        # Disconnect database
        try:
            db = DatabaseConnection()
            db.disconnect()
        except Exception as e:
            self.logger.warning(f"Error during database disconnect: {e}")
        
        self.is_running = False
        self.current_user = None
        self.current_session = None
        
        self.logger.info("Application stopped")
    
    def register_user(self, 
                     email: str, 
                     first_name: str, 
                     last_name: str, 
                     password: str) -> Tuple[bool, str]:
        """Register a new user."""
        self.logger.info(f"Registering new user: {email}")
        
        user, error = self.user_service.create_user(email, first_name, last_name, password)
        
        if user:
            self.logger.info(f"User registered successfully: {user.user_id}")
            
            # Create profile automatically
            profile, profile_error = self.profile_service.create_profile(user.user_id)
            if not profile:
                self.logger.warning(f"Failed to create profile for user {user.user_id}: {profile_error}")
            
            return True, f"User {user.display_name} registered successfully"
        else:
            self.logger.warning(f"User registration failed: {error}")
            return False, error or "Registration failed"
    
    def login_user(self, email: str, password: str) -> Tuple[bool, str]:
        """Authenticate and login user."""
        self.logger.info(f"Login attempt for: {email}")
        
        user, error = self.user_service.authenticate_user(email, password)
        
        if user:
            # Create session
            self.current_session = self.session_service.create_session(user)
            self.current_user = user
            
            self.logger.info(f"User logged in successfully: {user.user_id}")
            return True, f"Welcome back, {user.full_name}!"
        else:
            self.logger.warning(f"Login failed for {email}: {error}")
            return False, error or "Login failed"
    
    def logout_user(self) -> bool:
        """Logout current user."""
        if self.current_session:
            success = self.session_service.destroy_session(self.current_session)
            self.logger.info(f"User logged out: {self.current_user.email if self.current_user else 'unknown'}")
            
            self.current_user = None
            self.current_session = None
            return success
        return False
    
    def update_user_profile(self, bio: str = None, social_links: List[str] = None) -> Tuple[bool, str]:
        """Update current user's profile."""
        if not self.current_user:
            return False, "No user logged in"
        
        success_count = 0
        errors = []
        
        # Update bio
        if bio is not None:
            bio_success, bio_error = self.profile_service.update_profile_bio(self.current_user.user_id, bio)
            if bio_success:
                success_count += 1
            else:
                errors.append(f"Bio update failed: {bio_error}")
        
        # Add social links
        if social_links:
            for link in social_links:
                link_success, link_error = self.profile_service.add_social_link(self.current_user.user_id, link)
                if link_success:
                    success_count += 1
                else:
                    errors.append(f"Social link failed: {link_error}")
        
        if success_count > 0:
            message = f"Profile updated successfully ({success_count} changes)"
            if errors:
                message += f" with {len(errors)} errors"
            return True, message
        else:
            return False, "; ".join(errors) if errors else "No updates made"
    
    def search_users(self, query: str, limit: int = 20) -> List[Dict[str, Any]]:
        """Search for users."""
        self.logger.info(f"Searching users with query: {query}")
        
        users = self.user_service.search_users(query=query, is_active=True, limit=limit)
        
        results = []
        for user in users:
            results.append({
                'user_id': user.user_id,
                'display_name': user.display_name,
                'email': user.email,
                'login_count': user.login_count,
                'is_active': user.is_active
            })
        
        return results
    
    def get_application_statistics(self) -> Dict[str, Any]:
        """Get comprehensive application statistics."""
        self.logger.info("Generating application statistics")
        
        stats = {
            'timestamp': datetime.now().isoformat(),
            'app_status': {
                'is_running': self.is_running,
                'current_user': self.current_user.email if self.current_user else None,
                'debug_mode': self.debug_mode
            }
        }
        
        # User statistics
        try:
            user_stats = self.user_service.get_user_statistics()
            stats['user_statistics'] = user_stats
        except Exception as e:
            self.logger.error(f"Failed to get user statistics: {e}")
            stats['user_statistics'] = {'error': str(e)}
        
        # Session statistics
        try:
            total_sessions = len(self.session_service.active_sessions)
            if self.current_user:
                user_sessions = self.session_service.get_user_sessions(self.current_user.user_id)
                user_session_count = len(user_sessions)
            else:
                user_session_count = 0
            
            stats['session_statistics'] = {
                'total_active_sessions': total_sessions,
                'current_user_sessions': user_session_count
            }
        except Exception as e:
            self.logger.error(f"Failed to get session statistics: {e}")
            stats['session_statistics'] = {'error': str(e)}
        
        return stats
    
    def run_demo(self) -> None:
        """Run application demonstration."""
        print("\n" + "="*60)
        print("USER MANAGEMENT SYSTEM DEMO")
        print("="*60)
        
        if not self.start():
            print("❌ Failed to start application")
            return
        
        try:
            # Demo user registration
            print("\n📝 Registering demo users...")
            demo_users = [
                ("alice@example.com", "Alice", "Johnson", "SecurePass123!"),
                ("bob@test.org", "Bob", "Smith", "MyPassword456@"),
                ("carol@demo.net", "Carol", "Davis", "StrongPwd789#")
            ]
            
            for email, first_name, last_name, password in demo_users:
                success, message = self.register_user(email, first_name, last_name, password)
                status = "✅" if success else "❌"
                print(f"  {status} {email}: {message}")
            
            # Demo user login
            print("\n🔐 Testing user login...")
            login_success, login_message = self.login_user("alice@example.com", "SecurePass123!")
            print(f"  {'✅' if login_success else '❌'} {login_message}")
            
            if login_success:
                # Demo profile update
                print("\n👤 Updating user profile...")
                profile_success, profile_message = self.update_user_profile(
                    bio="Software developer passionate about clean code and testing.",
                    social_links=["https://github.com/alice", "https://linkedin.com/in/alice"]
                )
                print(f"  {'✅' if profile_success else '❌'} {profile_message}")
            
            # Demo user search
            print("\n🔍 Searching users...")
            search_results = self.search_users("alice", limit=5)
            print(f"  Found {len(search_results)} users:")
            for user in search_results:
                print(f"    - {user['display_name']} (ID: {user['user_id']})")
            
            # Demo statistics
            print("\n📊 Application Statistics:")
            stats = self.get_application_statistics()
            
            app_status = stats.get('app_status', {})
            print(f"  Running: {app_status.get('is_running', False)}")
            print(f"  Current User: {app_status.get('current_user', 'None')}")
            
            user_stats = stats.get('user_statistics', {})
            print(f"  Total Users: {user_stats.get('total_users', 0)}")
            print(f"  Active Users: {user_stats.get('active_users', 0)}")
            
            session_stats = stats.get('session_statistics', {})
            print(f"  Active Sessions: {session_stats.get('total_active_sessions', 0)}")
            
            print("\n✅ Demo completed successfully!")
            
        except Exception as e:
            self.logger.error(f"Demo failed: {e}")
            print(f"\n❌ Demo failed: {e}")
        
        finally:
            if login_success:
                self.logout_user()
                print("\n🚪 User logged out")
            
            self.stop()
            print("🛑 Application stopped")


def main():
    """Main application entry point."""
    app = UserManagementApp(debug_mode=True)
    app.run_demo()


if __name__ == "__main__":
    main()