#SingleInstance force
#include lib\base64.ahk
#include lib\helper.ahk
#include config.ahk
#NoTrayIcon
#Persistent

; globals
lastSameTime:=-1
block:=0
AlarmThreshold:=500

; Create GUI
Gosub CreateGUI

SetTimer, Sentinel, 50
return

Sentinel:
; has main program been closed?
if(!FileExist("main.tmp"))
{
	ExitApp
}

; has target app been closed?
if(!WinExist("ahk_exe " targetExeName ))
{
	ExitApp
}

read:=0
Sentinelcontent:=""
decoded:=""
if(FileExist("sync2.tmp"))
{
	Sentinelcontent:=trim(ReadFile("sync2.tmp", 0, 1))
	read:=1
	if(StrLen(Sentinelcontent)>0)
	{
		decoded:=b64Decode(Sentinelcontent)
	}else
	{
		decoded:=""
	}
	
}
if(read=0)
{
	lastSameTime:=A_TickCount
    goto CheckOK
}

ControlGetText, curtext, %targetControl% ,ahk_exe %targetExeName%
if(ErrorLevel)
{
	lastSameTime:=A_TickCount
	goto CheckOK
}
decoded:=trim(decoded)
curtext:=trim(curtext)
if("" decoded=curtext)
{
	lastSameTime:=A_TickCount
	goto CheckOK
}

nowTick:=A_TickCount
if(nowTick - lastSameTime > AlarmThreshold)
{
	block:=1
	;LogError(curtext,decoded)
	Gosub ShowGuard
}
return

CheckOK:
Gui, Show, Hide
block:=0
return



ShowGuard:
WinGetPos , X, Y, Width, Height, ahk_exe %targetExeName%
;Rst:=DllCall("user32\MoveWindow", "uint", MyGuiHwnd, "uint", 0, "uint", -60, "uint", 100 , "uint", 100, "int", 1 )
Y:=Y+30
Gui, Show, w250 h25 x%X% y%Y%
;DllCall("SetMenu", uint, WinActive( ahk_exe %targetExeName% ), uint, 0)
return

CreateGUI:
Gui +HwndMyGuiHwnd	; store the ID of the GUI to the variable MyGuiHwnd
HelpMsg:= "syncing..." ; Messages

Gui, +AlwaysOnTop 
Gui, font,s14,Verdana
Gui,  -Caption -Border -sysmenu

Gui, font,s10 bold,Verdana
Gui, add, text, x10 y0 w220 h500 vMsg, %HelpMsg%

Gui, Show, w250 h500 x1 y-100, Working overtime is harmful to your health
return


$Alt::
if WinActive("ahk_class CefBrowserWindow") or WinActive("ahk_exe " targetExeName)
{
	if(block=0)
	{
		Send {Alt}
	}
}else
{
	Send {Alt}
}
return


LogError(curtext, decoded)
{
	FormatTime, TimeString
	
	FileAppend ----Mismatch detected----`n, guard.log
	FileAppend %TimeString%, guard.log
	FileAppend `n----target text----`n, guard.log
	FileAppend %curtext%, guard.log
	FileAppend `n----End of target text`, start of sync text----`n, guard.log
	FileAppend %decoded%, guard.log
	FileAppend `n----End of message----`n, guard.log
}