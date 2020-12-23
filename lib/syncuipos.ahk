#SingleInstance force
#include lib\helper.ahk
#include lib\uievent.ahk
#include config.ahk
#NoTrayIcon
#Persistent


oldX:=-1
oldY:=-1
oldH:=-1
oldW:=-1




showUI:=1
overlapped:=false

Hwndcef:=A_Args[1]
Hwndcef+=0
HwndCefParent:=A_Args[2]
HwndCefParent+=0
cefpid:=A_Args[3]
cefpid+=0

prevState:=0 ; for posChrome

if(Hwndcef="" or HwndCefParent="")
{
	MsgBox need params!
	ExitApp
}

; BUG: SetTimer 好像不會馬上執行
SetTimer, SyncUIPos, 20
SetTimer, CheckActivateCEF, 60

ControlGet, HwndTargetControl, Hwnd ,, %targetControl%, ahk_exe %targetExeName%
HwndTargetControlParent := DllCall("user32\GetAncestor", Ptr,HwndTargetControl, UInt,1, Ptr)

; 防閃爍的背景
Gui +HwndHwndBG
Gui, +AlwaysOnTop 
Gui, -Caption -Border -sysmenu
Gui, Show, w240 h250 x10 y10, Working overtime is harmful to your health
Gui, Color, FFFFFF
DllCall( "SetParent", "uint", HwndBG, "uint", HwndTargetControlParent, UInt )

SetWindowLong := A_PtrSize=8 ? "SetWindowLongPtr" : "SetWindowLong"
flag:=-8	;GWL_HWNDPARENT
Rst:=DllCall( SetWindowLong, "Ptr",HwndCefParent, "int", flag, "Ptr", HwndTargetControlParent, "Ptr")
e:=ErrorLevel


WinActivate, ahk_exe %targetExeName%
WinActivate, ahk_pid %cefpid%

; shell hook: see this: https://autohotkey.com/board/topic/80644-how-to-hook-on-to-shell-to-receive-its-messages/
lastActivated:=-1
Gui +LastFound
GUIhWnd := WinExist()
DllCall( "RegisterShellHookWindow", UInt,GUIhWnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "ShellMessage" )
return



SyncUIPos:
; has main program been closed?
if(!FileExist("main.tmp"))
{
	ExitApp
}

; 無其他理由，預設顯示 chrome
showUI:=1


; sync cef position
ControlGetPos , X, Y, ClientWidth, ClientHeight, %targetControl%, ahk_exe %targetExeName%
errlevel:=ErrorLevel




WinGetPos , wX, wY, wWidth, wHeight, ahk_exe %targetExeName%
WinGetPos , cX, cY, cWidth, cHeight, ahk_pid %cefpid%

if(X!="" and wX!="" and cX!="")
{
	if(X+wX!=cX or Y+wY!=cY or ClientWidth!=cWidth or ClientHeight !=cHeight)
	{
		WinMove, deditormain====,, X+wX, Y+wY , ClientWidth, ClientHeight
	}
}



if(TargetAlreadyOnTop() or ChromeOnTop())
{
	overlapped:=false
}else if(IsOverlapped())
{
	overlapped:=true
}

if(overlapped)
{
	;showUI:=0
}
	


; auto hide UI if some controls are visible
for index, control in AvoidControl
{
	if(IsControlVisible(control, "ahk_exe" targetExeName))
	{
		showUI:=0
	}
} 
for index, win in AvoidWin
{
	WinGet, num, Count, ahk_class %win% ahk_exe %targetExeName%
	if(num)
	{
		showUI:=0
	}
}


; a "hook" for app-specific UI adjustment here
OnBeforeShowUI(X, Y, ClientWidth, ClientHeight, showUI)

if(errlevel)
{	
	showUI:=0
}else if(GetEnable()!=0)
{
	Hwnd:=WinExist("ahk_exe " targetExeName)
	; X, Y value passed into MoveWindow later should be in "client" coord rather than "window" coord
	WinToClient(Hwnd, X, Y) 
	
	; move BG GUI
	Rst:=DllCall("user32\MoveWindow", "uint", HwndBG, "uint", X, "uint", Y, "uint", ClientWidth , "uint", ClientHeight, "int", 1 )
	
	OnApplyMode(X, Y, ClientWidth, ClientHeight)

}else
{
	showUI:=0
}


if(showUI=0)
{

	WinHide, %editorTitle%
}else
{
	WinShow, %editorTitle%
}

if(ClientWidth=0)
{
	; 上方 ControlGetPos 有的時候可能會出現錯誤值，如果出現錯誤值就不改變現有視窗大小、位置
	
}else if(X!=oldX or Y!=oldY or ClientWidth!=oldW or ClientHeight!=oldH)
{
	oldX:=X
	oldY:=Y
	oldW:=ClientWidth
	oldH:=ClientHeight

}
; always force redraw of chrome window
Rst:=DllCall("user32\RedrawWindow", "uint", HwndCefParent, "uint", 0, "uint", 0, "uint", 1 )


return


CheckActivateCEF:
; is there a "windows activation" request? 
if(FileExist("activate2.tmp"))
{
	FileRead, content, activate2.tmp
	DeleteFile("activate2.tmp")
	
	
	; also notifies these control if chrome is to be activated
	for index, control in ClickWhenActivate
	{
		if(IsControlVisible(control, "ahk_exe" targetExeName))
		{
			ControlGetPos , Xt, Yt, wt, ht, %control%, ahk_exe %targetExeName%
			if(ht>0)
			{
				ControlClick , %control%, ahk_exe %targetExeName%,,L,1
			}
		}
	} 
	
	; 延伸用途：裡面有設定背景顏色？
	if(InStr(content, "#bgcolor:"))
	{
		aray := StrSplit(content, ":")
		color:= aray[2]
		Gui, Color, %color%
	}
	
	
	return
}
return

ChromeOnTop()
{
	global lastActivated, HwndCefParent,Hwndcef
	if (lastActivated*1)=(HwndCefParent*1)
	{
		return true
	}
	if (lastActivated*1)=(Hwndcef*1)
	{
		return true
	}
	return false
}

TargetAlreadyOnTop()
{
	global lastActivated, HwndTargetControlParent
	if (lastActivated*1)!=(HwndTargetControlParent*1)
	{
		return false
	}
	return true
}

IsOverlapped()
{
	global lastActivated, HwndCefParent, HwndTargetControlParent
	global oldX, oldY, oldW, oldH
	
	WinGetPos, wX, wY, wWidth, wHeight, ahk_id %lastActivated%
	if(wX="" or lastActivated=-1)
	{
		return false
	}
	l1x:=wX*1
	l1y:=wY*1
	r1x:=wX*1+wWidth*1
	r1y:=wY*1+wHeight*1
	
	WinGetPos , wX, wY, wWidth, wHeight, ahk_id %HwndCefParent%
	if(wX="")
	{
		; window already hidden, use old value
		l2x:=oldX*1
		l2y:=oldY*1
		r2x:=oldX*1+oldW*1
		r2y:=oldY*1+oldH*1
	}else
	{	
		l2x:=wX*1
		l2y:=wY*1
		r2x:=wX*1+wWidth*1
		r2y:=wY*1+wHeight*1
	}
	
		
	
	;If one rectangle is on left side of other 
    if(l1x >= r2x or l2x >= r1x)
	{
        return false
	}
    ;If one rectangle is above other 
    if(l1y >= r2y or l2y >= r1y) 
	{
        return false
	}
	return true
}

PosChrome()
{
	global HwndCefParent, HwndTargetControlParent, cefpid, targetExeName, lastActivated, HwndBG, prevState
	if(WinActive("ahk_exe" targetExeName) or lastActivated=HwndBG)
	{
		WinSet, AlwaysOnTop, On,ahk_pid %cefpid%
		
		if(lastActivated=HwndBG)
		{
			WinActivate, ahk_pid %cefpid%
		}
		
		prevState:=0
		
	}else if(WinActive("ahk_pid" cefpid))
	{
		if(prevState!=1)
		{	
			WinSet, AlwaysOnTop, On,ahk_pid %cefpid%		
			
			if(prevState!=0)
			{
				sleep,50
				WinActivate, ahk_exe %targetExeName%
			}
		}
		;Rst:=DllCall("user32\SetWindowPos", "uint", HwndCefParent, "uint", -1, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint", flag )
		;FileAppend,1,test.log
		prevState:=1
	}else
	{
		if(prevState!=2)
		{
			WinSet, AlwaysOnTop,Off,ahk_pid %cefpid%
			flag:=0x10|0x02|0x01
			Rst:=DllCall("user32\SetWindowPos", "uint", HwndCefParent, "uint", lastActivated, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint", flag )
			Rst:=DllCall("user32\SetWindowPos", "uint", HwndTargetControlParent, "uint", HwndCefParent, "uint", 0, "uint", 0, "uint", 0, "uint", 0, "uint", flag )
			;FileAppend,x,test.log
		}
		;FileAppend,2,test.log
		prevState:=2
	}
}

ShellMessage( wParam,lParam ) 
{	
	global lastActivated
	
	;MsgBox %wParam%
	If ( wParam = 4 or wParam = 32772) ;  HSHELL_WINDOWACTIVATED := 4,  HSHELL_RUDEAPPACTIVATED:=32772
	{
		lastActivated:=lParam
	}
	
	;WinGet, OutputVar, ProcessName, ahk_id %lastActivated%
	;FileAppend,%lastActivated%:%OutputVar% `r`n,test.log
	
	;PosChrome()
}
