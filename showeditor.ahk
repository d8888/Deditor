#SingleInstance force
#include lib\basic.ahk
#include lib\base64.ahk
#include lib\genfile.ahk
#include lib\helper.ahk
#include lib\uievent.ahk
#include config.ahk
#Persistent

; Globals



; delete temp files
DeleteTempFiles()
DeleteChromeTempFolder()

; Generate theme related files
GenTheme("assets", "theme", "temp.css", "temptheme.js")

; Generate color rules
coloraray:=ProcessFilter(FilterFile)
GenJS(coloraray, "assets\tempjson.js")

; Tray for debug
Menu, Tray, Add, ListVars, OnListVars
Menu, Tray, Add, Normal view, OnNormalView
Menu, Tray, Add, Wide view, OnWideView
Menu, Tray, Add, Debug view, OnDebugView
Menu, Tray, Add, Toggle debug console, OnShowConsole


; 檢查該有的檔案沒有被（防毒）刪掉，控制項的 ID 也是對的
if not SanityCheck()
{
	MsgBox Sanity check failed!
	ExitApp
}


ControlGet, HwndTargetControl, Hwnd ,, %targetControl%, ahk_exe %targetExeName%
HwndTargetControlParent := DllCall("user32\GetAncestor", Ptr,HwndTargetControl, UInt,1, Ptr)

; Hide control if needed to prevent obfuscating chrome
if(hideOriginalControl=true)
{
	Control, Hide ,, %targetControl%, ahk_exe %targetExeName%
}


; Run rust component
cmdstr:="editorsrv.exe"
Run, %cmdstr%,,Hide,editsrvpid
;Run, %cmdstr%,,,editsrvpid


; 取得目標 control 並設定 editor
ControlGetPos , X, Y, ClientWidth, ClientHeight, %targetControl%, ahk_exe %targetExeName%
GenLayoutParam(ClientWidth, ClientHeight, "assets\templayout.js")

; Start chrome app
StartChromeBrowser()
cefpid:=WaitChromePID(editorTitle, 45000)


DllCall( "LockSetForegroundWindow", "uint", 1, UInt)
OnExit, CleanUp


while(1)
{
	WinActivate, ahk_pid %cefpid%
	ifWinActive, ahk_pid %cefpid%
	{
		break
	}
}

; create intermediate GUI
Gui +HwndHwndMiddleGui	; store the ID of the GUI to the variable MyGuiHwnd
Gui, +AlwaysOnTop 
Gui,  -Caption -Border -sysmenu
Gui, Show, w240 h250 x100 y100

; remove chrome title bar and make chrome always on top
WinSet, Style,  -0xC40000 , ahk_pid %cefpid%
WinSet, AlwaysOnTop , On, ahk_pid %cefpid%

; 把 chrome 塞到目標程式
ControlGet, Hwndcef, Hwnd ,,Chrome Legacy Window, ahk_pid %cefpid%
if(Hwndcef="")
{
	MsgBox Cannot control chrome!
	ExitApp
}
HwndCefParent := DllCall("user32\GetAncestor", Ptr,Hwndcef, UInt,2, Ptr)
DllCall( "SetParent", "uint", HwndCefParent, "uint", HwndMiddleGui, UInt )
DllCall( "SetParent", "uint", HwndMiddleGui, "uint", HwndTargetControlParent, UInt )



; 監控目標程式有沒有被關掉
SetTimer, DetectChange, 30


; Show guardian
FileAppend 1,main.tmp
Run, %A_AhkPath% lib\syncuipos.ahk %Hwndcef% %HwndCefParent% %cefpid% %HwndMiddleGui%,,Hide,syncuipospid
Run, %A_AhkPath% lib\synccontent.ahk %HwndCefParent%,,Hide,synccontentpid
Run, %A_AhkPath% lib\guard.ahk,,Hide,guardpid
return


OnListVars()
{
	global nowContent, sync2text, targetControl, targetExeName
	ControlGetText, text, %targetControl%, ahk_exe %targetExeName%
	
	msg:="nowContent:" nowContent
	MsgBox %msg%
	msg:="sync2text:" sync2text
	MsgBox %msg%
	msg:="target:" text
	MsgBox %msg%
}




CleanUp:
DeleteFile("main.tmp")
KillProcessPid(cefpid)
KillProcessPid(editsrvpid)
KillProcessName("editorsrv.exe")
DeleteTempFiles()
DeleteChromeTempFolder()
if(hideOriginalControl=true)
{
	Control, Show ,, %targetControl%, ahk_exe %targetExeName%
}
ExitApp


DetectChange:
; has target app been closed?
if(!WinExist("ahk_exe " targetExeName))
{
	ExitApp
}

if( !ProcessExist(editsrvpid) or 
    !ProcessExist(syncuipospid) or 
	!ProcessExist(synccontentpid) or 
	!ProcessExist(guardpid)
	!ProcessExist(cefpid))
{
	MsgBox Component crashed, the program will now exit
	ExitApp
}	
return
	
OnShowConsole:
;MsgBox %editsrvpid%
IfWinExist, ahk_pid %editsrvpid%
{
	WinHide, ahk_pid %editsrvpid%
}else
{
	WinShow, ahk_pid %editsrvpid%
}

return




OnNormalView:
SetEnable(1)
return

OnWideView:
SetEnable(2)
return

OnDebugView:
SetEnable(3)
return

NumpadEnd::
WinActivate, ahk_exe %targetExeName%
WinWaitActive, ahk_exe %targetExeName%
MakeCEFForegroundIfEnabled(HwndCefParent)
return