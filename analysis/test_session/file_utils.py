"""
File utilities for dotfile management
Contains helper functions for file operations, path manipulation, and content analysis
"""

import os
import stat
import hashlib
import mimetypes
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Union
import subprocess
import tempfile
from datetime import datetime


def calculate_file_hash(file_path: Path) -> str:
    """Calculate SHA256 hash of a file"""
    hash_sha256 = hashlib.sha256()
    
    try:
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    except Exception as e:
        raise Exception(f"Could not calculate hash for {file_path}: {e}")


def get_file_info(file_path: Path) -> Dict[str, Union[str, int, float, bool]]:
    """Get comprehensive file information"""
    if not file_path.exists():
        raise FileNotFoundError(f"File does not exist: {file_path}")
    
    stat_info = file_path.stat()
    
    info: Dict[str, Union[str, int, float, bool]] = {
        'path': str(file_path),
        'name': file_path.name,
        'size': stat_info.st_size,
        'modified': datetime.fromtimestamp(stat_info.st_mtime).isoformat(),
        'created': datetime.fromtimestamp(stat_info.st_ctime).isoformat(),
        'permissions': oct(stat_info.st_mode)[-3:],
        'is_file': file_path.is_file(),
        'is_dir': file_path.is_dir(),
        'is_symlink': file_path.is_symlink(),
    }
    
    if file_path.is_file():
        info['hash'] = calculate_file_hash(file_path)
        mime_type, _ = mimetypes.guess_type(str(file_path))
        info['mime_type'] = str(mime_type) if mime_type else 'unknown'
    
    return info


class FileFilter:
    """File filtering utilities"""
    
    def __init__(self):
        self.ignore_patterns = [
            '*.pyc', '*.pyo', '*.pyd', '__pycache__',
            '.DS_Store', 'Thumbs.db', '.git', '.svn',
            '*.log', '*.tmp', '*.temp', '*.swp', '*.swo'
        ]
        
        self.dotfile_extensions = [
            '.conf', '.config', '.rc', '.profile', '.bashrc',
            '.zshrc', '.vimrc', '.tmux.conf', '.gitconfig'
        ]
    
    def is_dotfile(self, path: Path) -> bool:
        """Check if a file is likely a dotfile"""
        name = path.name
        
        # Hidden files starting with dot
        if name.startswith('.') and name not in ['.', '..']:
            return True
        
        # Files with dotfile extensions
        if any(name.endswith(ext) for ext in self.dotfile_extensions):
            return True
        
        # Common config directories
        config_dirs = ['.config', '.local', '.cache', '.ssh']
        if any(str(path).find(f'/{config_dir}/') != -1 for config_dir in config_dirs):
            return True
            
        return False
    
    def should_ignore(self, path: Path) -> bool:
        """Check if a file should be ignored"""
        import fnmatch
        
        name = path.name
        
        # Check ignore patterns
        for pattern in self.ignore_patterns:
            if fnmatch.fnmatch(name, pattern):
                return True
        
        # Ignore very large files (>50MB)
        try:
            if path.is_file() and path.stat().st_size > 50 * 1024 * 1024:
                return True
        except:
            pass
        
        return False


def backup_file(file_path: Path, backup_dir: Optional[Path] = None) -> Path:
    """Create a backup of a file"""
    if not file_path.exists():
        raise FileNotFoundError(f"Cannot backup non-existent file: {file_path}")
    
    if backup_dir is None:
        backup_dir = file_path.parent / 'backups'
    
    backup_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate backup filename with timestamp
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_name = f"{file_path.name}.backup.{timestamp}"
    backup_path = backup_dir / backup_name
    
    # Copy file to backup location
    import shutil
    shutil.copy2(file_path, backup_path)
    
    return backup_path


def restore_file(backup_path: Path, original_path: Path) -> bool:
    """Restore a file from backup"""
    try:
        if not backup_path.exists():
            raise FileNotFoundError(f"Backup file does not exist: {backup_path}")
        
        # Create parent directories if needed
        original_path.parent.mkdir(parents=True, exist_ok=True)
        
        import shutil
        shutil.copy2(backup_path, original_path)
        return True
        
    except Exception as e:
        print(f"Error restoring file: {e}")
        return False


def compare_files(file1: Path, file2: Path) -> Dict[str, Union[bool, str, None]]:
    """Compare two files for differences"""
    result: Dict[str, Union[bool, str, None]] = {
        'files_exist': file1.exists() and file2.exists(),
        'same_size': False,
        'same_content': False,
        'same_permissions': False,
        'error': None
    }
    
    try:
        if not result['files_exist']:
            result['error'] = "One or both files do not exist"
            return result
        
        stat1 = file1.stat()
        stat2 = file2.stat()
        
        # Compare sizes
        result['same_size'] = stat1.st_size == stat2.st_size
        
        # Compare permissions
        result['same_permissions'] = oct(stat1.st_mode) == oct(stat2.st_mode)
        
        # Compare content (only if sizes match)
        if result['same_size']:
            hash1 = calculate_file_hash(file1)
            hash2 = calculate_file_hash(file2)
            result['same_content'] = hash1 == hash2
        
    except Exception as e:
        result['error'] = str(e)
    
    return result


def find_files_by_pattern(directory: Path, pattern: str, recursive: bool = True) -> List[Path]:
    """Find files matching a pattern"""
    import fnmatch
    
    matches = []
    
    try:
        if recursive:
            for root, dirs, files in os.walk(directory):
                for filename in files:
                    if fnmatch.fnmatch(filename, pattern):
                        matches.append(Path(root) / filename)
        else:
            for item in directory.iterdir():
                if item.is_file() and fnmatch.fnmatch(item.name, pattern):
                    matches.append(item)
                    
    except Exception as e:
        print(f"Error finding files: {e}")
    
    return sorted(matches)


def get_directory_size(directory: Path) -> int:
    """Calculate total size of a directory"""
    total_size = 0
    
    try:
        for dirpath, dirnames, filenames in os.walk(directory):
            for filename in filenames:
                filepath = Path(dirpath) / filename
                try:
                    total_size += filepath.stat().st_size
                except (OSError, IOError):
                    # Skip files we can't access
                    continue
                    
    except Exception as e:
        print(f"Error calculating directory size: {e}")
    
    return total_size


def create_symlink(target: Path, link_path: Path, force: bool = False) -> bool:
    """Create a symbolic link"""
    try:
        if link_path.exists() or link_path.is_symlink():
            if not force:
                raise FileExistsError(f"Link already exists: {link_path}")
            link_path.unlink()  # Remove existing link/file
        
        # Create parent directories if needed
        link_path.parent.mkdir(parents=True, exist_ok=True)
        
        link_path.symlink_to(target)
        return True
        
    except Exception as e:
        print(f"Error creating symlink: {e}")
        return False


class ConfigFileParser:
    """Parse common configuration file formats"""
    
    @staticmethod
    def parse_env_file(file_path: Path) -> Dict[str, str]:
        """Parse .env style files"""
        env_vars = {}
        
        try:
            with open(file_path, 'r') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    
                    # Skip empty lines and comments
                    if not line or line.startswith('#'):
                        continue
                    
                    # Parse KEY=VALUE format
                    if '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"\'')  # Remove quotes
                        env_vars[key] = value
                    
        except Exception as e:
            print(f"Error parsing env file {file_path}: {e}")
        
        return env_vars
    
    @staticmethod
    def parse_ini_like(file_path: Path) -> Dict[str, Dict[str, str]]:
        """Parse INI-like configuration files"""
        config: Dict[str, Dict[str, str]] = {}
        current_section = 'DEFAULT'
        config[current_section] = {}
        
        try:
            with open(file_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    
                    # Skip empty lines and comments
                    if not line or line.startswith('#') or line.startswith(';'):
                        continue
                    
                    # Section headers
                    if line.startswith('[') and line.endswith(']'):
                        current_section = line[1:-1]
                        config[current_section] = {}
                        continue
                    
                    # Key-value pairs
                    if '=' in line:
                        key, value = line.split('=', 1)
                        config[current_section][key.strip()] = value.strip()
                        
        except Exception as e:
            print(f"Error parsing config file {file_path}: {e}")
        
        return config


# Intentional linting issues for testing:
# 1. Unused import
import json

# 2. Unused variable
# UNUSED_CONSTANT = "Fixed unused variable warning"

# 3. Line too long
def very_long_function_name_that_exceeds_typical_line_length_limits_and_should_trigger_linting_warnings(parameter_with_very_long_name, another_parameter_with_long_name):
    """This function has an intentionally long signature"""
    pass

# 4. Missing docstring
def undocumented_function():
    x = 1
    return x

# 5. Undefined variable (will cause error)
def function_with_undefined_var():
    return "fixed_variable_value"  # This will cause NameError
