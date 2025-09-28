"""
Configuration handler for dotfile management
Handles loading, saving, and validation of configuration settings
"""

import json
import yaml
import toml
from pathlib import Path
from typing import Dict, Any, List, Optional, Union
from dataclasses import dataclass, asdict
import logging


# Set up logging (intentional linting issue - unused)
logger = logging.getLogger(__name__)


@dataclass
class DotfileConfig:
    """Configuration structure for dotfile management"""
    dotfiles_dir: str = "~/.dotfiles"
    backup_dir: str = "~/.dotfiles/backups"
    auto_backup: bool = True
    sync_permissions: bool = True
    ignore_patterns: Optional[List[str]] = None
    include_patterns: Optional[List[str]] = None
    symlink_mode: bool = False
    dry_run: bool = False
    
    def __post_init__(self):
        if self.ignore_patterns is None:
            self.ignore_patterns = [
                "*.pyc", "*.pyo", "__pycache__", ".DS_Store",
                "Thumbs.db", "*.log", "*.tmp", "*.swp"
            ]
        
        if self.include_patterns is None:
            self.include_patterns = [
                ".*rc", ".*profile", ".*conf", ".*config"
            ]


class ConfigManager:
    """Manages configuration loading and saving"""
    
    def __init__(self, config_path: Optional[Path] = None):
        if config_path is None:
            config_path = Path.home() / ".config" / "dotfile_manager" / "config.yaml"
        
        self.config_path = config_path
        self.config: DotfileConfig = DotfileConfig()
        
        # Ensure config directory exists
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
    
    def load_config(self) -> DotfileConfig:
        """Load configuration from file"""
        if not self.config_path.exists():
            self.save_config()  # Create default config
            return self.config
        
        try:
            with open(self.config_path, 'r') as f:
                if self.config_path.suffix.lower() == '.yaml' or self.config_path.suffix.lower() == '.yml':
                    data = yaml.safe_load(f)
                elif self.config_path.suffix.lower() == '.json':
                    data = json.load(f)
                elif self.config_path.suffix.lower() == '.toml':
                    data = toml.load(f)
                else:
                    raise ValueError(f"Unsupported config format: {self.config_path.suffix}")
            
            # Update config with loaded data
            for key, value in data.items():
                if hasattr(self.config, key):
                    setattr(self.config, key, value)
            
            return self.config
            
        except Exception as e:
            print(f"Error loading config: {e}")
            return self.config
    
    def save_config(self) -> bool:
        """Save current configuration to file"""
        try:
            config_dict = asdict(self.config)
            
            with open(self.config_path, 'w') as f:
                if self.config_path.suffix.lower() in ['.yaml', '.yml']:
                    yaml.dump(config_dict, f, default_flow_style=False, indent=2)
                elif self.config_path.suffix.lower() == '.json':
                    json.dump(config_dict, f, indent=2)
                elif self.config_path.suffix.lower() == '.toml':
                    toml.dump(config_dict, f)
                else:
                    raise ValueError(f"Unsupported config format: {self.config_path.suffix}")
            
            return True
            
        except Exception as e:
            print(f"Error saving config: {e}")
            return False
    
    def validate_config(self) -> List[str]:
        """Validate configuration and return list of issues"""
        issues = []
        
        # Check if dotfiles directory path is valid
        dotfiles_path = Path(self.config.dotfiles_dir).expanduser()
        if not dotfiles_path.parent.exists():
            issues.append(f"Parent directory of dotfiles_dir does not exist: {dotfiles_path.parent}")
        
        # Check backup directory
        backup_path = Path(self.config.backup_dir).expanduser()
        if not backup_path.parent.exists():
            issues.append(f"Parent directory of backup_dir does not exist: {backup_path.parent}")
        
        # Validate patterns
        if not isinstance(self.config.ignore_patterns, list):
            issues.append("ignore_patterns must be a list")
        
        if not isinstance(self.config.include_patterns, list):
            issues.append("include_patterns must be a list")
        
        return issues
    
    def get_expanded_paths(self) -> Dict[str, Path]:
        """Get configuration paths with shell expansion applied"""
        return {
            'dotfiles_dir': Path(self.config.dotfiles_dir).expanduser(),
            'backup_dir': Path(self.config.backup_dir).expanduser()
        }
    
    def update_config(self, **kwargs) -> bool:
        """Update configuration with new values"""
        try:
            for key, value in kwargs.items():
                if hasattr(self.config, key):
                    setattr(self.config, key, value)
                else:
                    print(f"Warning: Unknown config key: {key}")
            
            return self.save_config()
            
        except Exception as e:
            print(f"Error updating config: {e}")
            return False


class ConfigValidator:
    """Validates configuration files and dotfiles"""
    
    @staticmethod
    def validate_yaml(file_path: Path) -> Dict[str, Any]:
        """Validate YAML file syntax"""
        result: Dict[str, Any] = {
            'valid': False,
            'errors': [],
            'warnings': []
        }
        
        try:
            with open(file_path, 'r') as f:
                yaml.safe_load(f)
            result['valid'] = True
            
        except yaml.YAMLError as e:
            result['errors'].append(f"YAML syntax error: {e}")
        except Exception as e:
            result['errors'].append(f"Error reading file: {e}")
        
        return result
    
    @staticmethod
    def validate_json(file_path: Path) -> Dict[str, Any]:
        """Validate JSON file syntax"""
        result: Dict[str, Any] = {
            'valid': False,
            'errors': [],
            'warnings': []
        }
        
        try:
            with open(file_path, 'r') as f:
                json.load(f)
            result['valid'] = True
            
        except json.JSONDecodeError as e:
            result['errors'].append(f"JSON syntax error: {e}")
        except Exception as e:
            result['errors'].append(f"Error reading file: {e}")
        
        return result
    
    @staticmethod
    def validate_shell_script(file_path: Path) -> Dict[str, Any]:
        """Basic validation of shell scripts"""
        result: Dict[str, Any] = {
            'valid': True,
            'errors': [],
            'warnings': []
        }
        
        try:
            with open(file_path, 'r') as f:
                content = f.read()
            
            # Basic checks
            if not content.strip():
                result['warnings'].append("File is empty")
            
            lines = content.split('\n')
            for i, line in enumerate(lines, 1):
                line = line.strip()
                
                # Check for common issues
                if line.endswith('\\') and i == len(lines):
                    result['warnings'].append(f"Line {i}: Ends with backslash but is last line")
                
                if 'rm -rf /' in line or 'rm -rf *' in line:
                    result['errors'].append(f"Line {i}: Potentially dangerous rm command")
                
        except Exception as e:
            result['errors'].append(f"Error reading file: {e}")
            result['valid'] = False
        
        return result


def create_default_config(config_path: Path) -> bool:
    """Create a default configuration file"""
    config_manager = ConfigManager(config_path)
    return config_manager.save_config()


def merge_configs(base_config: DotfileConfig, override_config: Dict[str, Any]) -> DotfileConfig:
    """Merge two configurations, with override taking precedence"""
    merged_dict = asdict(base_config)
    
    for key, value in override_config.items():
        if key in merged_dict:
            merged_dict[key] = value
    
    # Create new config from merged dictionary
    return DotfileConfig(**merged_dict)


# More intentional linting issues for testing:

# 1. Import not used at top level
from datetime import datetime

# 2. Variable assigned but never used
config_cache: Dict[str, Any] = {}

# 3. Function too complex (too many branches)
def overly_complex_function(x, y, z, a, b, c):
    if x > 0:
        if y > 0:
            if z > 0:
                if a > 0:
                    if b > 0:
                        if c > 0:
                            return x + y + z + a + b + c
                        else:
                            return x + y + z + a + b
                    else:
                        return x + y + z + a
                else:
                    return x + y + z
            else:
                return x + y
        else:
            return x
    else:
        return 0

# 4. Line too long with string
VERY_LONG_ERROR_MESSAGE = "This is an extremely long error message that exceeds the typical line length limit and should trigger a linting warning about line length"

# 5. Inconsistent naming (snake_case vs camelCase)
def snake_case_function():
    camelCaseVariable = "mixed naming styles"
    return camelCaseVariable

# 6. Duplicate code (similar functions)
def format_path_1(path):
    return str(Path(path).expanduser().resolve())

def format_path_2(path):
    return str(Path(path).expanduser().resolve())

# 7. Missing type hints on function with multiple params
def process_config_data(config, data, options, flags):
    return config, data, options, flags

# 8. Unreachable code
def function_with_unreachable_code():
    return "early return"
    print("This line is unreachable")  # Dead code
