"""
Input validation utilities for user data.
Provides comprehensive validation for emails, passwords, URLs, etc.
"""

import re
from typing import Tuple, List, Optional
from urllib.parse import urlparse


class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


class EmailValidator:
    """Email validation utility class."""
    
    # RFC 5322 compliant email regex (simplified)
    EMAIL_PATTERN = re.compile(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    )
    
    FORBIDDEN_DOMAINS = ['tempmail.org', '10minutemail.com', 'guerrillamail.com']
    
    @classmethod
    def is_valid(cls, email: str) -> bool:
        """Check if email format is valid."""
        if not email or not isinstance(email, str):
            return False
        
        # Check basic format
        if not cls.EMAIL_PATTERN.match(email.lower()):
            return False
        
        # Check length
        if len(email) > 254:
            return False
        
        # Check for forbidden domains
        domain = email.split('@')[-1].lower()
        if domain in cls.FORBIDDEN_DOMAINS:
            return False
        
        return True
    
    @classmethod
    def validate_with_details(cls, email: str) -> Tuple[bool, Optional[str]]:
        """Validate email with detailed error message."""
        if not email or not isinstance(email, str):
            return False, "Email must be a non-empty string"
        
        if len(email) > 254:
            return False, "Email too long (max 254 characters)"
        
        if not cls.EMAIL_PATTERN.match(email.lower()):
            return False, "Invalid email format"
        
        domain = email.split('@')[-1].lower()
        if domain in cls.FORBIDDEN_DOMAINS:
            return False, f"Domain {domain} is not allowed"
        
        return True, None
    
    @classmethod
    def normalize(cls, email: str) -> str:
        """Normalize email address."""
        return email.lower().strip()


class PasswordValidator:
    """Password validation utility class."""
    
    MIN_LENGTH = 8
    MAX_LENGTH = 128
    
    def __init__(self, 
                 require_uppercase: bool = True,
                 require_lowercase: bool = True,
                 require_digits: bool = True,
                 require_special: bool = True):
        self.require_uppercase = require_uppercase
        self.require_lowercase = require_lowercase
        self.require_digits = require_digits
        self.require_special = require_special
        self.special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    
    def validate(self, password: str) -> Tuple[bool, Optional[str]]:
        """Validate password with detailed feedback."""
        if not password or not isinstance(password, str):
            return False, "Password must be a non-empty string"
        
        # Check length
        if len(password) < self.MIN_LENGTH:
            return False, f"Password must be at least {self.MIN_LENGTH} characters"
        
        if len(password) > self.MAX_LENGTH:
            return False, f"Password must not exceed {self.MAX_LENGTH} characters"
        
        # Check character requirements
        errors = []
        
        if self.require_uppercase and not any(c.isupper() for c in password):
            errors.append("at least one uppercase letter")
        
        if self.require_lowercase and not any(c.islower() for c in password):
            errors.append("at least one lowercase letter")
        
        if self.require_digits and not any(c.isdigit() for c in password):
            errors.append("at least one digit")
        
        if self.require_special and not any(c in self.special_chars for c in password):
            errors.append("at least one special character")
        
        if errors:
            return False, f"Password must contain {', '.join(errors)}"
        
        return True, None
    
    def get_strength_score(self, password: str) -> int:
        """Get password strength score (0-100)."""
        if not password:
            return 0
        
        score = 0
        
        # Length bonus
        score += min(len(password) * 2, 50)
        
        # Character variety bonus
        if any(c.isupper() for c in password):
            score += 10
        if any(c.islower() for c in password):
            score += 10
        if any(c.isdigit() for c in password):
            score += 10
        if any(c in self.special_chars for c in password):
            score += 10
        
        # Uniqueness bonus
        unique_chars = len(set(password))
        score += min(unique_chars * 2, 20)
        
        return min(score, 100)


class URLValidator:
    """URL validation utility class."""
    
    ALLOWED_SCHEMES = ['http', 'https', 'ftp', 'ftps']
    
    @classmethod
    def is_valid(cls, url: str) -> bool:
        """Check if URL is valid."""
        if not url or not isinstance(url, str):
            return False
        
        try:
            parsed = urlparse(url)
            
            # Check scheme
            if parsed.scheme.lower() not in cls.ALLOWED_SCHEMES:
                return False
            
            # Check netloc (domain)
            if not parsed.netloc:
                return False
            
            return True
        except Exception:
            return False
    
    @classmethod
    def validate_with_details(cls, url: str) -> Tuple[bool, Optional[str]]:
        """Validate URL with detailed error message."""
        if not url or not isinstance(url, str):
            return False, "URL must be a non-empty string"
        
        try:
            parsed = urlparse(url)
            
            if not parsed.scheme:
                return False, "URL must include a scheme (http, https, etc.)"
            
            if parsed.scheme.lower() not in cls.ALLOWED_SCHEMES:
                return False, f"Unsupported scheme: {parsed.scheme}"
            
            if not parsed.netloc:
                return False, "URL must include a domain"
            
            return True, None
        except Exception as e:
            return False, f"Invalid URL format: {str(e)}"


class PhoneValidator:
    """Phone number validation utility class."""
    
    # US phone number patterns
    US_PATTERNS = [
        re.compile(r'^\+1[2-9]\d{2}[2-9]\d{2}\d{4}$'),  # +1XXXXXXXXXX
        re.compile(r'^[2-9]\d{2}[2-9]\d{2}\d{4}$'),     # XXXXXXXXXX
        re.compile(r'^\([2-9]\d{2}\)\s?[2-9]\d{2}-\d{4}$'),  # (XXX) XXX-XXXX
    ]
    
    @classmethod
    def normalize_us_phone(cls, phone: str) -> str:
        """Normalize US phone number to +1XXXXXXXXXX format."""
        # Remove all non-digits
        digits = re.sub(r'[^\d]', '', phone)
        
        # Add country code if missing
        if len(digits) == 10:
            digits = '1' + digits
        
        return '+' + digits
    
    @classmethod
    def is_valid_us_phone(cls, phone: str) -> bool:
        """Check if phone number is valid US format."""
        if not phone or not isinstance(phone, str):
            return False
        
        normalized = cls.normalize_us_phone(phone)
        
        for pattern in cls.US_PATTERNS:
            if pattern.match(normalized):
                return True
        
        return False


class DataValidator:
    """General data validation utilities."""
    
    @staticmethod
    def is_positive_integer(value: any) -> bool:
        """Check if value is a positive integer."""
        try:
            int_val = int(value)
            return int_val > 0
        except (ValueError, TypeError):
            return False
    
    @staticmethod
    def is_valid_age(age: any) -> bool:
        """Check if age is valid (0-150)."""
        try:
            age_int = int(age)
            return 0 <= age_int <= 150
        except (ValueError, TypeError):
            return False
    
    @staticmethod
    def sanitize_string(text: str, max_length: int = 255) -> str:
        """Sanitize string input."""
        if not isinstance(text, str):
            return ""
        
        # Remove control characters
        sanitized = ''.join(char for char in text if ord(char) >= 32)
        
        # Trim whitespace
        sanitized = sanitized.strip()
        
        # Truncate if too long
        if len(sanitized) > max_length:
            sanitized = sanitized[:max_length]
        
        return sanitized
    
    @staticmethod
    def validate_json_string(json_str: str) -> Tuple[bool, Optional[str]]:
        """Validate JSON string format."""
        try:
            import json
            json.loads(json_str)
            return True, None
        except json.JSONDecodeError as e:
            return False, str(e)
        except Exception as e:
            return False, f"Unexpected error: {str(e)}"