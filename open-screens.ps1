param (
    [int]$NumberOfDesktops,
    [string]$OpenOnAll,
    [string[]]$OpenFiles = @(),
    [string[]]$OpenURLs = @()
)

# Function to display help information
function Show-Help {
    Write-Host "Usage: .\open-screens.ps1 [-NumberOfDesktops <int>] [-OpenOnAll <path>] [-OpenURLs <url>]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -NumberOfDesktops <int>   Number of virtual desktops to create (required, between 1 and 8)."
    Write-Host "  -OpenOnAll <path>         Path to an executable to open on each desktop (optional)."
    Write-Host "  -OpenFiles <path(s)>      List of file path(s) to open on each desktop (optional, must be less than or equal to requested desktops)."
    Write-Host "  -OpenURLs <url(s)>        List of URL(s) to open on each desktop (optional, https:// required, must be less than or equal to requested desktops)."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\open-screens.ps1 -NumberOfDesktops 3 -OpenOnAll 'C:\Windows\System32\notepad.exe' -OpenURLs 'https://example.com', 'https://anotherexample.com'"
    Write-Host "  .\open-screens.ps1 -NumberOfDesktops 2 -OpenFiles 'C:\word.docx', 'C:\slides.pptx' -OpenURLs 'https://example.com'"
    Write-Host "  .\open-screens.ps1 -NumberOfDesktops 2 -OpenURLs 'https://example.com'"
    Write-Host ""
    exit
}

# Show help if no parameters are provided
if ($NumberOfDesktops -eq 0) {
    Show-Help
}

function Validate-URLs {
    param (
        [string[]]$URLs
    )

    foreach ($URL in $URLs) {
        if ($URL -notmatch "^http[s]{0,}://") {
            Write-Host "Invalid URL (must start with https://): $URL" -ForegroundColor Red
            exit 1
        }
    }
}

function Validate-ExecutablePath {
    param (
        [string]$Path
    )

    if ($Path) {
        if (-not (Test-Path $Path)) {
            Write-Host "Executable not found: $Path" -ForegroundColor Red
            exit 1
        }

        if ((Get-Item $Path).Extension -ne ".exe") {
            Write-Host "The path does not point to an executable file: $Path" -ForegroundColor Red
            exit 1
        }
    }
}

function Validate-Files {
    param (
        [string[]]$Files
    )

    foreach ($File in $Files) {
        if (-not (Test-Path $File)) {
            Write-Host "Invalid File Path for File $FILE." -ForegroundColor Red
            exit 1
        }
    }
}



function Validate-NumberOfDesktops {
    param (
        [int]$Number
    )

    if (-not $Number -or $Number -lt 1 -or $Number -gt 8) {
        Write-Host "The number of desktops must be an integer between 1 and 8. You provided: $Number" -ForegroundColor Red
        exit 1
    }
}

# Validate NumberOfDesktops
if ($NumberOfDesktops -ne $null) {
    Validate-NumberOfDesktops -Number $NumberOfDesktops
} else {
    Write-Host "Error: -NumberOfDesktops parameter is required." -ForegroundColor Red
    Show-Help
}

Validate-URLs -URLs $OpenURLs
Validate-ExecutablePath -Path $OpenOnAll
Validate-Files -Files $OpenFiles

# Send a keyboard shortcut to create a new virtual desktop (Windows key + Ctrl + D)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class KeyboardSimulator
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);

    public static void SendKey(byte keyCode, uint flags)
    {
        keybd_event(keyCode, 0, flags, 0);
    }
}
"@

# Define virtual key codes
$VK_LWIN = 0x5B  # Windows key
$VK_CONTROL = 0x11  # Control key
$VK_D = 0x44  # 'D' key
$VK_LEFT = 0x25  # Left Arrow key
$VK_RIGHT = 0x27  # Right Arrow key

# Function to create a new virtual desktop
function Create-NewDesktop {
    # Key down events
    [KeyboardSimulator]::SendKey($VK_LWIN, 0x0000)
    [KeyboardSimulator]::SendKey($VK_CONTROL, 0x0000)
    [KeyboardSimulator]::SendKey($VK_D, 0x0000)

    # Key up events
    [KeyboardSimulator]::SendKey($VK_D, 0x0002)
    [KeyboardSimulator]::SendKey($VK_CONTROL, 0x0002)
    [KeyboardSimulator]::SendKey($VK_LWIN, 0x0002)

    # Wait for the new desktop to be created
    Start-Sleep -Seconds 4
}

function Switch-ToDesktop {
    param (
        [int]$DesktopNumber
    )

    $direction = if ($DesktopNumber -gt 1) { $VK_RIGHT } else { $VK_LEFT }

    for ($i = 1; $i -lt $DesktopNumber; $i++) {
        [KeyboardSimulator]::SendKey($VK_LWIN, 0x0000)
        [KeyboardSimulator]::SendKey($VK_CONTROL, 0x0000)
        [KeyboardSimulator]::SendKey($direction, 0x0000)

        [KeyboardSimulator]::SendKey($direction, 0x0002)
        [KeyboardSimulator]::SendKey($VK_CONTROL, 0x0002)
        [KeyboardSimulator]::SendKey($VK_LWIN, 0x0002)

        Start-Sleep -Milliseconds 500
    }
}

# Function to open an executable on the current desktop
function Open-Executable {
    param (
        [string]$ExecutablePath
    )
    
    if (-not (Test-Path $ExecutablePath)) {
        Write-Host "Executable not found: $ExecutablePath" -ForegroundColor Red
        return
    }

    $process = Start-Process $ExecutablePath -PassThru

    # Wait for the process to start
    if ($process) {
        Write-Host "Waiting for the process to start: $($process.Id)" -ForegroundColor Green
        try {
            # Wait for the process to start or timeout after 10 seconds
            $process | Wait-Process -Timeout 10
        } catch {
            Write-Host "Failed to wait for process to start: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Failed to start the process: $ExecutablePath" -ForegroundColor Red
    }
}

function Open-File {
    param (
        [string]$File
    )

    $process = Start-Process $File
    
    # Wait for the file to open
    if ($process) {
        Write-Host "Waiting for $File to open." -ForegroundColor Green
        try {
            # Wait for the file to open or timeout after 10 seconds.
            $process | Wait-Process -Timeout 20
        } catch {
            Write-Host "Failed to wait for file to open: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}


function Open-URL {
    param (
        [string]$URL
    )
    
    try {
        Start-Process $URL
    } catch {
        Write-Host "Failed to open URL: $URL" -ForegroundColor Red
    }
}

# Create desktops and open the executable on each desktop.
for ($i = 1; $i -le $NumberOfDesktops; $i++) {
    Create-NewDesktop

    # 1. Switch to the newly created desktop.
    Switch-ToDesktop -DesktopNumber $i

    # 2. Open the next URL from the OpenURLs array if any remain.
    if ($OpenURLs.Count -ge $i) {
        $currentURL = $OpenURLs[$i - 1]
        Open-URL -URL $currentURL
        Start-Sleep -Seconds 5
    }

    # 3. Open the next File from the OpenFiles array if any remain.
    if ($OpenFiles.Count -ge $i) {
        $currentFile = $OpenFiles[$i - 1]
        Open-File -File $currentFile
        Start-Sleep -Seconds 5
    }

    # 4. Open the executable on the current desktop if specified.
    if ($OpenOnAll) {
        Open-Executable -ExecutablePath $OpenOnAll
        Start-Sleep -Seconds 5
    }
}

# Open Task View.
if (-not $OpenOnAll) {
    Start-Process "shell:::{3080F90E-D7AD-11D9-BD98-0000947B0257}"
}
