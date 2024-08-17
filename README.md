# open-screens
A PowerShell script to open Windows 11 virtual desktops, an optional app across all, and specific URLs for each.

## Usage

```powershell
.\open-screens.ps1 [-NumberOfDesktops <int>] [-OpenOnAll <path>] [-OpenURLs <url>]
```

Run without arguments for full help.  `-OpenOnAll` takes one, full path to an executable (e.g., `C:\Windows\System32\notepad.exe`).

The `-OpenURLs` parameter takes a comma-separated list of values, (e.g., `"https://example.com", "https://anotherexample.com"`).
