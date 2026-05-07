#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; CONFIGURATION & SAFETY SETTINGS
; ==============================================================================

; Set DRY_RUN_MODE := false only after manual validation.
global DRY_RUN_MODE := true

; If true, shows a safety briefing on startup.
global SAFETY_CONFIRMATION_REQUIRED := true

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
; INITIALIZATION
; ==============================================================================

if (SAFETY_CONFIRMATION_REQUIRED)
{
    msg := "Antigravity Review Helper Safety Briefing:`n`n"
    msg .= "- Retry/Continue: Auto-click when enabled (and DRY_RUN is false).`n"
    msg .= "- Accept: MANUAL ONLY via Ctrl+Alt+A.`n"
    msg .= "- Ctrl+Alt+S: Toggle Helper.`n"
    msg .= "- Ctrl+Alt+Esc: Emergency Exit.`n`n"
    msg .= "DRY_RUN_MODE is currently " (DRY_RUN_MODE ? "ENABLED" : "DISABLED") ".`n`n"
    msg .= "Proceed?"
    
    if (MsgBox(msg, "Safety Audit", "YesNo Iconi") = "No")
        ExitApp()
}

; ==============================================================================
; HOTKEYS
; ==============================================================================

; Ctrl+Alt+S: Toggle Helper
^!s::
{
    global HelperEnabled := !HelperEnabled
    state := HelperEnabled ? "ENABLED" : "DISABLED"
    modeText := DRY_RUN_MODE ? " (DRY RUN)" : ""
    Tooltip("Helper " state modeText)
    SetTimer () => Tooltip(), -2000
    LogAction("System", 0, 0, "Helper toggled to " state modeText)
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

    ; Check for Accept button first
    if (ScanForButton(ACCEPT_IMG, &foundX, &foundY))
    {
        global AcceptPending := true
        global AcceptX := foundX
        global AcceptY := foundY
        Tooltip("Accept Detected at " foundX "," foundY ". Press Ctrl+Alt+A to approve.")
        return 
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
    title := WinGetTitle("A")
    
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

    for forbidden in FORBIDDEN_TITLES
    {
        if (InStr(title, forbidden))
            return false
    }

    global LastMouseX, LastMouseY
    currX := 0
    currY := 0
    MouseGetPos(&currX, &currY)
    
    if (currX != LastMouseX or currY != LastMouseY)
    {
        LastMouseX := currX
        LastMouseY := currY
        return false 
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

    if (DRY_RUN_MODE)
    {
        LogAction("DRY_RUN_DETECTED", x, y, WinGetTitle("A") " | Button: " type)
        Tooltip("DRY RUN: Detected " type " at " x "," y)
        SetTimer () => Tooltip(), -2000
        return
    }

    CoordMode "Mouse", "Screen"
    Click(x, y)
    LogAction(type, x, y, WinGetTitle("A"))
    
    Tooltip("Clicked " type " at " x "," y)
    SetTimer () => Tooltip(), -1000
}

CheckRateLimit()
{
    global ClickTimestamps
    now := A_TickCount
    
    newTimestamps := []
    for ts in ClickTimestamps
    {
        if (now - ts < 60000)
            newTimestamps.Push(ts)
    }
    ClickTimestamps := newTimestamps

    if (ClickTimestamps.Length > 0)
    {
        lastClick := ClickTimestamps[ClickTimestamps.Length]
        if (now - lastClick < 1000)
            return false
    }

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
    }
}
