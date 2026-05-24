# Installing Symbols Nerd Font on Windows

WezTerm is a Windows application and requires fonts to be installed on the **Windows** side — fonts installed inside WSL have no effect.

## Install

Run in **PowerShell** (not WSL):

```powershell
# Download the font
Invoke-WebRequest `
    -Uri "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf" `
    -OutFile "$env:TEMP\SymbolsNerdFontMono-Regular.ttf"

# Copy to user fonts directory
Copy-Item "$env:TEMP\SymbolsNerdFontMono-Regular.ttf" "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\"

# Register the font in Windows registry
New-ItemProperty `
    -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
    -Name "Symbols Nerd Font Mono Regular (TrueType)" `
    -Value "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\SymbolsNerdFontMono-Regular.ttf" `
    -PropertyType String -Force
```

Then **fully restart WezTerm** (close all windows — config reload is not enough).

## Verify

```powershell
wezterm ls-fonts --list-system | Select-String "Symbol"
```

Expected output includes:

```
"Symbols Nerd Font Mono",
wezterm.font("Symbols Nerd Font Mono", ...) -- C:\Users\...\SymbolsNerdFontMono-Regular.ttf
```

## How it's used

`wezterm.lua` declares the font as a fallback so nerd glyph codepoints render in the tab bar:

```lua
config.font = wezterm.font_with_fallback({
    { family = "Ubuntu Mono", weight = "Bold" },
    "Symbols Nerd Font Mono",
})
```

The same fallback is set on `config.window_frame.font` so tab bar icons also use it.
