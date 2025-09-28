#!/usr/bin/env python3
"""
Dotfile Manager - A TUI application for managing dotfiles
Supports import mode and diff mode for ~/.dotfiles management
"""

import os
import sys
import shutil
import difflib
from pathlib import Path
from typing import List, Dict, Optional, Set
from rich.console import Console
from rich.tree import Tree
from rich.text import Text
from rich.panel import Panel
from textual.app import App, ComposeResult  # type: ignore
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import (
    DirectoryTree, 
    Static, 
    Button, 
    Header, 
    Footer,
    TextArea,
    Checkbox,
    DataTable
)
from textual.binding import Binding
from textual.message import Message
from textual import events


class DotfileManager:
    """Core dotfile management functionality"""
    
    def __init__(self, dotfiles_dir: str = "~/.dotfiles"):
        self.dotfiles_dir = Path(dotfiles_dir).expanduser()
        self.home_dir = Path.home()
        self.console = Console()
        
        # Common dotfile patterns to look for
        self.dotfile_patterns = {
            ".bashrc", ".zshrc", ".vimrc", ".gitconfig", 
            ".tmux.conf", ".profile", ".bash_profile",
            ".config/nvim", ".config/alacritty", ".ssh/config"
        }
    
    def ensure_dotfiles_dir(self):
        """Create dotfiles directory if it doesn't exist"""
        if not self.dotfiles_dir.exists():
            self.dotfiles_dir.mkdir(parents=True)
            self.console.print(f"[green]Created dotfiles directory: {self.dotfiles_dir}[/green]")
    
    def get_home_dotfiles(self) -> List[Path]:
        """Scan home directory for dotfiles"""
        dotfiles = []
        
        # Check for common dotfiles in home directory
        for pattern in self.dotfile_patterns:
            path = self.home_dir / pattern
            if path.exists():
                dotfiles.append(path)
        
        # Also scan for hidden files/dirs in home
        for item in self.home_dir.iterdir():
            if item.name.startswith('.') and item.name not in ['.', '..']:
                if item.is_file() or item.is_dir():
                    dotfiles.append(item)
        
        return sorted(list(set(dotfiles)))  # Remove duplicates and sort
    
    def get_managed_dotfiles(self) -> List[Path]:
        """Get list of files currently managed in dotfiles directory"""
        if not self.dotfiles_dir.exists():
            return []
        
        managed = []
        for item in self.dotfiles_dir.rglob("*"):
            if item.is_file():
                managed.append(item)
        
        return sorted(managed)
    
    def import_dotfile(self, source_path: Path) -> bool:
        """Import a dotfile to the managed directory"""
        try:
            # Calculate relative path from home
            rel_path = source_path.relative_to(self.home_dir)
            dest_path = self.dotfiles_dir / rel_path
            
            # Create parent directories if needed
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            
            if source_path.is_file():
                shutil.copy2(source_path, dest_path)
            elif source_path.is_dir():
                shutil.copytree(source_path, dest_path, dirs_exist_ok=True)
            
            self.console.print(f"[green]Imported: {rel_path}[/green]")
            return True
            
        except Exception as e:
            self.console.print(f"[red]Error importing {source_path}: {e}[/red]")
            return False
    
    def get_diff(self, managed_file: Path) -> Optional[str]:
        """Get diff between managed file and home directory version"""
        try:
            # Calculate corresponding home path
            rel_path = managed_file.relative_to(self.dotfiles_dir)
            home_path = self.home_dir / rel_path
            
            if not home_path.exists():
                return f"File {home_path} does not exist in home directory"
            
            # Read both files
            with open(managed_file, 'r') as f:
                managed_content = f.readlines()
            
            with open(home_path, 'r') as f:
                home_content = f.readlines()
            
            # Generate diff
            diff = list(difflib.unified_diff(
                managed_content,
                home_content,
                fromfile=str(managed_file),
                tofile=str(home_path),
                lineterm=''
            ))
            
            return '\n'.join(diff) if diff else None
            
        except Exception as e:
            return f"Error generating diff: {e}"


class FileTreeWidget(DirectoryTree):
    """Custom DirectoryTree widget for dotfile selection"""
    
    def __init__(self, path: str, **kwargs):
        super().__init__(path, **kwargs)
        self.selected_files: Set[Path] = set()
    
    class FileSelected(Message):
        """Message sent when a file is selected/deselected"""
        def __init__(self, path: Path, selected: bool):
            self.path = path
            self.selected = selected
            super().__init__()


class ImportModeScreen(Container):
    """Screen for importing dotfiles"""
    
    def __init__(self, manager: DotfileManager):
        super().__init__()
        self.manager = manager
        self.selected_files: Set[Path] = set()
    
    def compose(self) -> ComposeResult:
        yield Static("Import Mode - Select dotfiles to import", classes="header")
        
        with Horizontal():
            # File tree on the left
            with Vertical(classes="left-panel"):
                yield Static("Available Dotfiles:", classes="panel-title")
                yield FileTreeWidget(str(self.manager.home_dir), id="file_tree")
                
            # Selection panel on the right  
            with Vertical(classes="right-panel"):
                yield Static("Selected Files:", classes="panel-title")
                yield TextArea("", id="selected_files", read_only=True)
                
        with Horizontal(classes="button-row"):
            yield Button("Import Selected", id="import_btn", variant="primary")
            yield Button("Clear Selection", id="clear_btn")
            yield Button("Back to Menu", id="back_btn")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "import_btn":
            self.import_selected_files()
        elif event.button.id == "clear_btn":
            self.clear_selection()
        elif event.button.id == "back_btn":
            self.app.pop_screen()
    
    def import_selected_files(self):
        """Import all selected files"""
        imported_count = 0
        for file_path in self.selected_files:
            if self.manager.import_dotfile(file_path):
                imported_count += 1
        
        self.app.notify(f"Imported {imported_count} files")
        self.clear_selection()
    
    def clear_selection(self):
        """Clear all selected files"""
        self.selected_files.clear()
        self.update_selection_display()
    
    def update_selection_display(self):
        """Update the selected files display"""
        text_area = self.query_one("#selected_files", TextArea)
        file_list = "\n".join(str(f) for f in sorted(self.selected_files))
        text_area.text = file_list


class DiffModeScreen(Container):
    """Screen for viewing diffs between managed and home dotfiles"""
    
    def __init__(self, manager: DotfileManager):
        super().__init__()
        self.manager = manager
        self.managed_files: List[Path] = []
    
    def compose(self) -> ComposeResult:
        yield Static("Diff Mode - Compare managed dotfiles with home directory", classes="header")
        
        with Horizontal():
            # File list on the left
            with Vertical(classes="left-panel"):
                yield Static("Managed Dotfiles:", classes="panel-title")
                table: DataTable = DataTable(id="managed_files_table")
                table.add_columns("File", "Status")
                yield table
                
            # Diff display on the right
            with Vertical(classes="right-panel"):
                yield Static("Diff Preview:", classes="panel-title")
                yield TextArea("Select a file to view diff", id="diff_display", read_only=True)
        
        with Horizontal(classes="button-row"):
            yield Button("Refresh", id="refresh_btn")
            yield Button("Back to Menu", id="back_btn")
    
    def on_mount(self):
        """Initialize the diff mode screen"""
        self.refresh_managed_files()
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "refresh_btn":
            self.refresh_managed_files()
        elif event.button.id == "back_btn":
            self.app.pop_screen()
    
    def refresh_managed_files(self):
        """Refresh the list of managed files and their status"""
        table = self.query_one("#managed_files_table", DataTable)
        table.clear()
        
        self.managed_files = self.manager.get_managed_dotfiles()
        
        for managed_file in self.managed_files:
            rel_path = managed_file.relative_to(self.manager.dotfiles_dir)
            home_path = self.manager.home_dir / rel_path
            
            if not home_path.exists():
                status = "Missing in home"
            else:
                diff = self.manager.get_diff(managed_file)
                status = "Different" if diff else "In sync"
            
            table.add_row(str(rel_path), status)


class DotfileManagerApp(App):
    """Main TUI application"""
    
    CSS = """
    .header {
        text-align: center;
        background: $primary;
        color: $text;
        padding: 1;
    }
    
    .left-panel {
        width: 50%;
        padding: 1;
        border: solid $primary;
    }
    
    .right-panel {
        width: 50%;
        padding: 1;
        border: solid $secondary;
    }
    
    .panel-title {
        background: $surface;
        padding: 1;
        text-align: center;
    }
    
    .button-row {
        height: 3;
        align: center middle;
    }
    """
    
    BINDINGS = [
        Binding("ctrl+i", "import_mode", "Import Mode"),
        Binding("ctrl+d", "diff_mode", "Diff Mode"),
        Binding("ctrl+q", "quit", "Quit"),
    ]
    
    def __init__(self):
        super().__init__()
        self.manager = DotfileManager()
        self.manager.ensure_dotfiles_dir()
    
    def compose(self) -> ComposeResult:
        yield Header()
        yield Container(
            Static("Dotfile Manager", classes="header"),
            Static(
                "Welcome to Dotfile Manager!\n\n"
                "• Ctrl+I: Import Mode - Import dotfiles from home directory\n"
                "• Ctrl+D: Diff Mode - Compare managed dotfiles with home directory\n"  
                "• Ctrl+Q: Quit application",
                classes="commands-panel"
            ),
            id="main_menu"
        )
        yield Footer()
    
    def action_import_mode(self):
        """Switch to import mode"""
        self.push_screen(ImportModeScreen(self.manager))
    
    def action_diff_mode(self):
        """Switch to diff mode"""
        self.push_screen(DiffModeScreen(self.manager))


def main():
    """Main entry point"""
    if len(sys.argv) > 1 and sys.argv[1] == "-i":
        # CLI import mode
        manager = DotfileManager()
        manager.ensure_dotfiles_dir()
        
        dotfiles = manager.get_home_dotfiles()
        console = Console()
        
        console.print("[bold]Available dotfiles for import:[/bold]")
        for i, dotfile in enumerate(dotfiles, 1):
            rel_path = dotfile.relative_to(manager.home_dir)
            console.print(f"{i:2d}. {rel_path}")
        
        # Simple CLI import (could be enhanced)
        console.print("\n[yellow]Use the TUI for interactive import (run without -i flag)[/yellow]")
        
    else:
        # Launch TUI
        app = DotfileManagerApp()
        app.run()


if __name__ == "__main__":
    main()
