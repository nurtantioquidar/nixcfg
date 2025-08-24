#!/usr/bin/env python3
"""
Force register Atlassian fonts with macOS using multiple methods
"""
import subprocess
import os
import shutil
from pathlib import Path

def force_register_fonts():
    """Try multiple methods to force font registration"""
    fonts_dir = Path.home() / "Library" / "Fonts"
    atlassian_fonts = list(fonts_dir.glob("Atlassian*.ttf"))
    
    print(f"Found {len(atlassian_fonts)} Atlassian fonts to register:")
    for font in atlassian_fonts:
        print(f"  - {font.name}")
    
    # Method 1: Move fonts out and back in to trigger registration
    print("\n1. Triggering re-registration by moving fonts...")
    temp_dir = Path("/tmp/atlassian_fonts_temp")
    temp_dir.mkdir(exist_ok=True)
    
    try:
        # Move fonts to temp
        for font in atlassian_fonts:
            temp_font = temp_dir / font.name
            shutil.move(str(font), str(temp_font))
            print(f"   Moved {font.name} to temp")
        
        # Brief pause for system to notice
        import time
        time.sleep(2)
        
        # Move fonts back
        for temp_font in temp_dir.glob("*.ttf"):
            final_font = fonts_dir / temp_font.name
            shutil.move(str(temp_font), str(final_font))
            print(f"   Restored {temp_font.name}")
            
    finally:
        # Cleanup temp dir
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
    
    # Method 2: Use osascript to tell Font Book to refresh
    print("\n2. Asking Font Book to refresh...")
    applescript = '''
    tell application "Font Book"
        activate
        delay 1
        tell application "System Events"
            tell process "Font Book"
                try
                    keystroke "r" using command down
                on error
                    -- Refresh failed, try menu
                    try
                        click menu item "Refresh Fonts" of menu "File" of menu bar 1
                    end try
                end try
            end tell
        end tell
    end tell
    '''
    
    try:
        subprocess.run(['osascript', '-e', applescript], 
                      capture_output=True, text=True, timeout=10)
        print("   Font Book refresh attempted")
    except Exception as e:
        print(f"   Font Book refresh failed: {e}")
    
    # Method 3: Force system font cache rebuild
    print("\n3. Forcing system font cache rebuild...")
    try:
        # Clear various font caches
        subprocess.run(['rm', '-rf', os.path.expanduser('~/Library/Caches/com.apple.FontServices')], 
                      capture_output=True)
        subprocess.run(['rm', '-rf', os.path.expanduser('~/Library/FontCollections')], 
                      capture_output=True)
        
        # Touch the fonts to update modification time
        for font in fonts_dir.glob("Atlassian*.ttf"):
            font.touch()
            print(f"   Updated timestamp for {font.name}")
            
    except Exception as e:
        print(f"   Cache clearing failed: {e}")
    
    # Method 4: Use Core Text to register fonts programmatically
    print("\n4. Attempting programmatic font registration...")
    try:
        # This uses PyObjC if available to register fonts via Core Text
        import CoreText
        import CoreFoundation
        
        for font_path in fonts_dir.glob("Atlassian*.ttf"):
            font_url = CoreFoundation.CFURLCreateFromFileSystemRepresentation(
                None, str(font_path).encode('utf-8'), len(str(font_path)), False
            )
            
            result = CoreText.CTFontManagerRegisterFontsForURL(
                font_url, CoreText.kCTFontManagerScopeUser, None
            )
            
            if result:
                print(f"   ✓ Registered {font_path.name}")
            else:
                print(f"   ✗ Failed to register {font_path.name}")
                
    except ImportError:
        print("   PyObjC not available, skipping programmatic registration")
    except Exception as e:
        print(f"   Programmatic registration failed: {e}")
    
    print("\n" + "="*50)
    print("Font registration attempts completed.")
    print("Please test in your applications now.")
    print("If still not working, try restarting the application.")
    print("="*50)

if __name__ == "__main__":
    force_register_fonts()