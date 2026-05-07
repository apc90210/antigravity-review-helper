#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; SCRIPT SELF-CHECK & QUICK REFERENCE
; ==============================================================================
; - DRY_RUN_MODE: true (Safety: Enabled by default)
; - SAFETY_CONFIRMATION_REQUIRED: true (Shows startup briefing)
; - ACCEPT BUTTON: MANUAL ONLY BY DEFAULT (Requires Ctrl+Alt+A or GUI click)
; - EMERGENCY EXIT: Ctrl+Alt+Esc (Terminates immediately)
; - SCREEN REGIONS: Automatically constrained to target window bounds
; ==============================================================================

; ==============================================================================
; CONFIGURATION & SAFETY SETTINGS
; ==============================================================================

global DRY_RUN_MODE := true
global SAFETY_CONFIRMATION_REQUIRED := true

; Global state
global WindowConfigs := Map() ; hwnd -> Object
global ClickTimestamps := []
global MAX_CLICKS_PER_SEC := 1
global MAX_CLICKS_PER_MIN := 20
global ALLOWED_TITLES := ["Antigravity", "Visual Studio Code", "Cursor"]
global FORBIDDEN_TITLES := ["terminal", "powershell", "cmd", "password", "credentials", "ssh", "git", "browser", "chrome", "edge"]

; Asset Paths
global ASSET_DIR := A_ScriptDir "\..\assets\buttons\"
global RETRY_IMG := ASSET_DIR "retry_button.png"
global CONTINUE_IMG := ASSET_DIR "continue_button.png"
global ACCEPT_IMG := ASSET_DIR "accept_button.png"
global LOG_FILE := A_ScriptDir "\..\logs\antigravity_review_helper.log"

; Mouse tracking
global LastMouseX := 0
global LastMouseY := 0
MouseGetPos(&LastMouseX, &LastMouseY)

; ==============================================================================
; INITIALIZATION & GUI
; ==============================================================================

if (SAFETY_CONFIRMATION_REQUIRED)
{
    msg := "Antigravity Review Helper v2 (GUI Mode) Safety Briefing:`n`n"
    msg .= "- All auto-clicking modes are OFF by default.`n"
    msg .= "- Accept All/Auto: DANGEROUS, requires confirmation.`n"
    msg .= "- Dry Run: ON by default.`n"
    msg .= "- Ctrl+Alt+Esc: Emergency Exit.`n`n"
    msg .= "Proceed?"
    if (MsgBox(msg, "Safety Audit", "YesNo Iconi") = "No")
        ExitApp()
}

MyGui := Gui("+Resize", "Antigravity Review Helper v2")
MyGui.SetFont("s9", "Segoe UI")

; Window List
MyGui.Add("Text", "x10 y10", "Detected Windows (Antigravity / VS Code / Cursor):")
LV := MyGui.Add("ListView", "x10 y30 w600 h150", ["HWND", "Status", "Title"])
LV.OnEvent("Click", OnLVClick)

; Configuration Pane
MyGui.Add("GroupBox", "x10 y190 w600 h120", "Selected Window Configuration")
chkEnabled := MyGui.Add("Checkbox", "x20 y210 vEnabled", "Enabled")
chkAlwaysOn := MyGui.Add("Checkbox", "x120 y210 vAlwaysOn", "Always On")
chkRetry := MyGui.Add("Checkbox", "x220 y210 vRetryAuto", "Retry Auto")
chkContinue := MyGui.Add("Checkbox", "x320 y210 vContinueAuto", "Continue Auto")
chkAcceptManual := MyGui.Add("Checkbox", "x20 y240 vAcceptManual", "Accept Manual")
chkAcceptAuto := MyGui.Add("Checkbox", "x120 y240 vAcceptAuto", "Accept All (Auto)")
chkAcceptAuto.OnEvent("Click", OnAcceptAutoClick)

; Buttons for selected window
btnStart := MyGui.Add("Button", "x20 y270 w100", "Start Selected")
btnStart.OnEvent("Click", (*) => SetWindowStatus("Running"))
btnStop := MyGui.Add("Button", "x130 y270 w100", "Stop Selected")
btnStop.OnEvent("Click", (*) => SetWindowStatus("Stopped"))
btnAcceptOnce := MyGui.Add("Button", "x240 y270 w150", "Accept Once (Selected)")
btnAcceptOnce.OnEvent("Click", OnAcceptOnceClick)

; Global Controls
MyGui.Add("GroupBox", "x10 y320 w600 h80", "Global Controls")
btnRefresh := MyGui.Add("Button", "x20 y340 w100", "Refresh List")
btnRefresh.OnEvent("Click", RefreshWindowList)
btnStopAll := MyGui.Add("Button", "x130 y340 w100", "Stop All")
btnStopAll.OnEvent("Click", StopAll)
chkDryRun := MyGui.Add("Checkbox", "x240 y345 vDryRunChecked", "DRY RUN MODE")
chkDryRun.Value := DRY_RUN_MODE
chkDryRun.OnEvent("Click", (ctrl, *) => (global DRY_RUN_MODE := ctrl.Value))

btnClearLog := MyGui.Add("Button", "x380 y340 w100", "Clear Log")
btnClearLog.OnEvent("Click", (*) => FileDelete(LOG_FILE))
btnSaveLog := MyGui.Add("Button", "x490 y340 w100", "Save Log As...")
btnSaveLog.OnEvent("Click", OnSaveLog)

MyGui.Add("Text", "x10 y410 cGray", "Emergency Exit: Ctrl+Alt+Esc")
MyGui.Show()

RefreshWindowList()

; ==============================================================================
; GUI EVENTS
; ==============================================================================

OnLVClick(LV, RowNumber)
{
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    if (!WindowConfigs.Has(hwnd)) return
    
    config := WindowConfigs[hwnd]
    chkEnabled.Value := config.Enabled
    chkAlwaysOn.Value := config.AlwaysOn
    chkRetry.Value := config.RetryAuto
    chkContinue.Value := config.ContinueAuto
    chkAcceptManual.Value := config.AcceptManual
    chkAcceptAuto.Value := config.AcceptAuto
    
    ; Update local config on change
    chkEnabled.OnEvent("Click", (ctrl, *) => (config.Enabled := ctrl.Value))
    chkAlwaysOn.OnEvent("Click", (ctrl, *) => (config.AlwaysOn := ctrl.Value))
    chkRetry.OnEvent("Click", (ctrl, *) => (config.RetryAuto := ctrl.Value))
    chkContinue.OnEvent("Click", (ctrl, *) => (config.ContinueAuto := ctrl.Value))
    chkAcceptManual.OnEvent("Click", (ctrl, *) => (config.AcceptManual := ctrl.Value))
}

OnAcceptAutoClick(ctrl, *)
{
    RowNumber := LV.GetNext()
    if (RowNumber = 0) {
        ctrl.Value := 0
        return
    }
    hwnd := LV.GetText(RowNumber, 1)
    config := WindowConfigs[hwnd]

    if (ctrl.Value = 1)
    {
        msg := "Accept All can approve changes automatically. Use only in trusted windows. Continue?"
        if (MsgBox(msg, "DANGER: Accept All", "YesNo Icon!") = "No")
        {
            ctrl.Value := 0
            config.AcceptAuto := 0
        }
        else
        {
            config.AcceptAuto := 1
        }
    }
    else
    {
        config.AcceptAuto := 0
    }
}

SetWindowStatus(newStatus)
{
    RowNumber := LV.GetNext()
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    if (WindowConfigs.Has(hwnd))
    {
        WindowConfigs[hwnd].Status := newStatus
        LV.Modify(RowNumber, , , newStatus)
    }
}

StopAll(*)
{
    for hwnd, config in WindowConfigs
    {
        config.Status := "Stopped"
    }
    Loop LV.GetCount()
    {
        LV.Modify(A_Index, , , "Stopped")
    }
}

RefreshWindowList(*)
{
    LV.Delete()
    oldConfigs := WindowConfigs.Clone()
    WindowConfigs.Clear()
    
    allHwnds := WinGetList()
    for hwnd in allHwnds
    {
        title := WinGetTitle(hwnd)
        isMatch := false
        for pattern in ALLOWED_TITLES
        {
            if (InStr(title, pattern))
            {
                isMatch := true
                break
            }
        }
        
        if (isMatch)
        {
            status := "Stopped"
            config := {
                Enabled: 0, AlwaysOn: 0, RetryAuto: 0, ContinueAuto: 0, 
                AcceptManual: 1, AcceptAuto: 0, Status: status,
                LastAcceptX: 0, LastAcceptY: 0
            }
            
            ; Preserve settings if window existed before
            if (oldConfigs.Has(hwnd))
                config := oldConfigs[hwnd]
            
            WindowConfigs[hwnd] := config
            LV.Add("", hwnd, config.Status, title)
        }
    }
}

OnAcceptOnceClick(*)
{
    RowNumber := LV.GetNext()
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    if (!WindowConfigs.Has(hwnd)) return
    
    config := WindowConfigs[hwnd]
    if (config.LastAcceptX > 0)
    {
        DoClick(hwnd, config.LastAcceptX, config.LastAcceptY, "AcceptOnce")
        config.LastAcceptX := 0
        config.LastAcceptY := 0
    }
    else
    {
        MsgBox("No Accept button detected recently for this window.")
    }
}

OnSaveLog(*)
{
    dest := FileSelect("S16", "helper_log_export.log", "Save Log As", "Log Files (*.log)")
    if (dest != "")
        FileCopy(LOG_FILE, dest, 1)
}

; ==============================================================================
; HOTKEYS
; ==============================================================================

^!esc:: ExitApp()

; Global Accept for the ACTIVE window if it's configured
^!a::
{
    hwnd := WinActive("A")
    hwndStr := "" hwnd
    if (WindowConfigs.Has(hwndStr))
    {
        config := WindowConfigs[hwndStr]
        if (config.LastAcceptX > 0)
        {
            DoClick(hwnd, config.LastAcceptX, config.LastAcceptY, "AcceptHotkey")
            config.LastAcceptX := 0
            config.LastAcceptY := 0
        }
    }
}

; ==============================================================================
; MAIN SCAN LOOP
; ==============================================================================

SetTimer(MainLoop, 1000)

MainLoop()
{
    for hwnd, config in WindowConfigs
    {
        if (!config.Enabled) continue
        if (config.Status != "Running" and !config.AlwaysOn) continue
        
        if (!WinExist("ahk_id " hwnd))
        {
            config.Status := "Not Found"
            continue
        }
        
        if (WinGetMinMax("ahk_id " hwnd) = -1)
        {
            ; Minimized
            continue
        }

        ; Check safety (Forbidden titles)
        title := WinGetTitle("ahk_id " hwnd)
        isForbidden := false
        for f in FORBIDDEN_TITLES
        {
            if (InStr(title, f))
            {
                isForbidden := true
                break
            }
        }
        if (isForbidden) continue

        ; Check mouse movement
        global LastMouseX, LastMouseY
        currX := 0, currY := 0
        MouseGetPos(&currX, &currY)
        if (currX != LastMouseX or currY != LastMouseY)
        {
            LastMouseX := currX, LastMouseY := currY
            continue
        }

        ; Get Window Rect for constrained search
        x := 0, y := 0, w := 0, h := 0
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)

        ; Prioritize Accept
        if (ScanForButton(ACCEPT_IMG, x, y, x+w, y+h, &foundX, &foundY))
        {
            config.LastAcceptX := foundX
            config.LastAcceptY := foundY
            
            if (config.AcceptAuto)
            {
                DoClick(hwnd, foundX, foundY, "AcceptAuto")
            }
            else if (config.AcceptManual)
            {
                LogAction(hwnd, "ACCEPT_WAITING_MANUAL_APPROVAL", foundX, foundY, "Manual mode")
            }
            continue ; Don't process others if Accept is present
        }

        ; Retry
        if (config.RetryAuto and ScanForButton(RETRY_IMG, x, y, x+w, y+h, &foundX, &foundY))
        {
            DoClick(hwnd, foundX, foundY, "Retry")
        }

        ; Continue
        if (config.ContinueAuto and ScanForButton(CONTINUE_IMG, x, y, x+w, y+h, &foundX, &foundY))
        {
            DoClick(hwnd, foundX, foundY, "Continue")
        }
    }
}

ScanForButton(imgPath, x1, y1, x2, y2, &foundX, &foundY)
{
    if (!FileExist(imgPath)) return false
    CoordMode "Pixel", "Screen"
    if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*50 " imgPath)
    {
        foundX += 10
        foundY += 10
        return true
    }
    return false
}

DoClick(hwnd, clickX, clickY, type)
{
    ; Final safety: Is the click inside the window?
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
    if (clickX < winX or clickX > winX+winW or clickY < winY or clickY > winY+winH)
    {
        LogAction(hwnd, "SKIPPED_OUTSIDE_WINDOW", clickX, clickY, type)
        return
    }

    if (!CheckRateLimit(hwnd)) return

    if (DRY_RUN_MODE)
    {
        LogAction(hwnd, "DRY_RUN_" type "_DETECTED", clickX, clickY, "Dry Run")
        return
    }

    CoordMode "Mouse", "Screen"
    Click(clickX, clickY)
    LogAction(hwnd, "CLICKED_" type, clickX, clickY, "Live")
}

CheckRateLimit(hwnd)
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

    if (ClickTimestamps.Length > 0 and now - ClickTimestamps[ClickTimestamps.Length] < 1000)
    {
        LogAction(hwnd, "SKIPPED_RATE_LIMIT", 0, 0, "Too fast")
        return false
    }

    if (ClickTimestamps.Length >= MAX_CLICKS_PER_MIN)
    {
        LogAction(hwnd, "SKIPPED_RATE_LIMIT", 0, 0, "Too many per minute")
        return false
    }

    ClickTimestamps.Push(now)
    return true
}

LogAction(hwnd, event, x, y, actionNote)
{
    global LOG_FILE
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    title := WinGetTitle("ahk_id " hwnd)
    logLine := timestamp " | " hwnd " | " title " | " event " | " (DRY_RUN_MODE ? "DRY" : "LIVE") " | " x "," y " | " actionNote "`n"
    try {
        FileAppend(logLine, LOG_FILE)
    } catch {
    }
}
