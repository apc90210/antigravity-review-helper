#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; CONFIGURATION
; ==============================================================================

global HelperEnabled := false
global AcceptPending := false
global AcceptX := 0
global AcceptY := 0

; Rate limiting
global ClickTimestamps := []
global MAX_CLICKS_PER_SEC := 1
global MAX_CLICKS_PER_MIN := 20

; Allowed Window Titles (Case-sensitive)
global ALLOWED_TITLES := ["Antigravity", "Visual Studio Code", "Cursor"]

; Forbidden Window Titles (Case-insensitive check)
global FORBIDDEN_TITLES := ["terminal", "powershell", "cmd", "password", "credentials", "ssh", "git", "browser", "chrome", "edge"]

; Monitoring Regions (x1, y1, x2, y2)
; Edit these to match your dual monitor setup.
; Example: Monitor 1 (0, 0, 1920, 1080), Monitor 2 (1920, 0, 3840, 1080)
global SCAN_REGIONS := [
    {x1: 0, y1: 0, x2: 1920, y2: 1080},      ; Monitor 1
    {x1: 1920, y1: 0, x2: 3840, y2: 1080}    ; Monitor 2
]

; Asset Paths
global ASSET_DIR := A_ScriptDir "\..\assets\buttons\"
global RETRY_IMG := ASSET_DIR "retry_button.png"
global CONTINUE_IMG := ASSET_DIR "continue_button.png"
global ACCEPT_IMG := ASSET_DIR "accept_button.png"
global LOG_FILE := A_ScriptDir "\..\logs\antigravity_review_helper.log"

; Tracking mouse movement
global LastMouseX := 0
global LastMouseY := 0
MouseGetPos(&LastMouseX, &LastMouseY)

; ==============================================================================
; HOTKEYS
; ==============================================================================

; Ctrl+Alt+S: Toggle Helper
^!s::
{
    global HelperEnabled := !HelperEnabled
    state := HelperEnabled ? "ENABLED" : "DISABLED"
    Tooltip("Helper " state)
    SetTimer () => Tooltip(), -2000
    LogAction("System", 0, 0, "Helper toggled to " state)
}

; Ctrl+Alt+Esc: Emergency Exit
^!esc::
{
    LogAction("System", 0, 0, "Emergency Exit triggered")
    ExitApp()
}

; Ctrl+Alt+A: Approve Accept
^!a::
{
    global AcceptPending, AcceptX, AcceptY
    if (AcceptPending)
    {
        DoClick(AcceptX, AcceptY, "Accept")
        AcceptPending := false
        Tooltip() ; Clear detection tooltip
    }
    else
    {
        Tooltip("No Accept button detected")
        SetTimer () => Tooltip(), -1500
    }
}

; ==============================================================================
; MAIN LOOP
; ==============================================================================

SetTimer(ScanLoop, 500)

ScanLoop()
{
    if (!HelperEnabled)
        return

    ; Check Safety Guards
    if (!IsSafeToClick())
        return

    ; Check for Accept button first (it has priority detection)
    if (ScanForButton(ACCEPT_IMG, &foundX, &foundY))
    {
        global AcceptPending := true
        global AcceptX := foundX
        global AcceptY := foundY
        Tooltip("Accept Detected at " foundX "," foundY ". Press Ctrl+Alt+A to approve.")
        return ; Don't auto-click others while Accept is pending
    }
    else
    {
        global AcceptPending := false
    }

    ; Scan for Retry
    if (ScanForButton(RETRY_IMG, &foundX, &foundY))
    {
        DoClick(foundX, foundY, "Retry")
        return
    }

    ; Scan for Continue
    if (ScanForButton(CONTINUE_IMG, &foundX, &foundY))
    {
        DoClick(foundX, foundY, "Continue")
        return
    }
}

; ==============================================================================
; FUNCTIONS
; ==============================================================================

IsSafeToClick()
{
    ; 1. Check Active Window
    title := WinGetTitle("A")
    
    ; Must be an allowed window
    isAllowed := false
    for allowed in ALLOWED_TITLES
    {
        if (InStr(title, allowed))
        {
            isAllowed := true
            break
        }
    }
    if (!isAllowed)
        return false

    ; Must not be a forbidden window
    for forbidden in FORBIDDEN_TITLES
    {
        if (InStr(title, forbidden))
            return false
    }

    ; 2. Check Mouse Movement
    global LastMouseX, LastMouseY
    currX := 0
    currY := 0
    MouseGetPos(&currX, &currY)
    
    if (currX != LastMouseX or currY != LastMouseY)
    {
        LastMouseX := currX
        LastMouseY := currY
        return false ; Mouse is moving, don't interfere
    }
    
    return true
}

ScanForButton(imgPath, &foundX, &foundY)
{
    if (!FileExist(imgPath))
        return false

    CoordMode "Pixel", "Screen"
    for region in SCAN_REGIONS
    {
        if ImageSearch(&foundX, &foundY, region.x1, region.y1, region.x2, region.y2, "*50 " imgPath)
        {
            ; Center the click (approximate offset, adjust if needed)
            foundX += 10
            foundY += 10
            return true
        }
    }
    return false
}

DoClick(x, y, type)
{
    if (!CheckRateLimit())
        return

    CoordMode "Mouse", "Screen"
    Click(x, y)
    LogAction(type, x, y, WinGetTitle("A"))
    
    ; Visual feedback
    Tooltip("Clicked " type " at " x "," y)
    SetTimer () => Tooltip(), -1000
}

CheckRateLimit()
{
    global ClickTimestamps
    now := A_TickCount
    
    ; Clean up old timestamps (older than 1 minute)
    newTimestamps := []
    for ts in ClickTimestamps
    {
        if (now - ts < 60000)
            newTimestamps.Push(ts)
    }
    ClickTimestamps := newTimestamps

    ; Check 1 click per second
    if (ClickTimestamps.Length > 0)
    {
        lastClick := ClickTimestamps[ClickTimestamps.Length]
        if (now - lastClick < 1000)
            return false
    }

    ; Check 20 clicks per minute
    if (ClickTimestamps.Length >= MAX_CLICKS_PER_MIN)
        return false

    ClickTimestamps.Push(now)
    return true
}

LogAction(type, x, y, windowTitle)
{
    global LOG_FILE
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    logLine := "[" timestamp "] TYPE: " type " | POS: " x "," y " | WIN: " windowTitle "`n"
    try {
        FileAppend(logLine, LOG_FILE)
    } catch {
        ; Ignore log failures
    }
}
