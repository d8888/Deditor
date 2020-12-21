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


Hwndcef:=A_Args[1]
Hwndcef+=0
HwndCefParent:=A_Args[2]
HwndCefParent+=0
cefpid:=A_Args[3]
cefpid+=0


if(Hwndcef="" or HwndCefParent="")
{
	MsgBox need params!
	ExitApp
}

; BUG: SetTimer 好像不會馬上執行
SetTimer, SyncUIPos, 60
SetTimer, CheckActivateCEF, 60

ControlGet, HwndTargetControl, Hwnd ,, %targetControl%, ahk_exe %targetExeName%
HwndTargetControlParent := DllCall("user32\GetAncestor", Ptr,HwndTargetControl, UInt,1, Ptr)

if(useSetParent)
{
	DllCall( "SetParent", "uint", HwndCefParent, "uint", HwndTargetControlParent, UInt )
}



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

if(!useSetParent)
{
	WinGetPos , wX, wY, wWidth, wHeight, ahk_exe %targetExeName%
	WinMove, deditormain====,, X+wX, Y+wY , ClientWidth, ClientHeight
	if(!TargetAlreadyOnTop() && !ChromeOnTop())
	{
		if(IsOverlapped())
		{
			showUI:=0
		}
	}
}

; auto hide UI if some controls are visible
for index, control in AvoidControl
{
	if(IsControlVisible(control, "ahk_exe" targetExeName))
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
	
	OnApplyMode(X, Y, ClientWidth, ClientHeight)

}else
{
	showUI:=0
}


if(showUI=0)
{
	;WinHide, Control hide doesn't work for chrome for unknown reason
	if(!useSetParent)
	{
		WinHide, %editorTitle%
	}else
	{
		X:=9000
		Y:=9000
	}
	
	
}else
{
	if(!useSetParent)
	{
		WinShow, %editorTitle%
	}
}

if(ClientWidth=0)
{
	; 上方 ControlGetPos 有的時候可能會出現錯誤值，如果出現錯誤值就不改變現有視窗大小、位置
	
}else if(X!=oldX or Y!=oldY or ClientWidth!=oldW or ClientHeight!=oldH)
{
	dbg:=X ":" Y
	
	oldX:=X
	oldY:=Y
	oldW:=ClientWidth
	oldH:=ClientHeight
	
	Rst:=DllCall("user32\MoveWindow", "uint", Hwndcef, "uint", 0, "uint", 0, "uint", ClientWidth , "uint", ClientHeight, "int", 1 )
	Rst:=DllCall("user32\MoveWindow", "uint", HwndCefParent, "uint", X, "uint", Y, "uint", ClientWidth , "uint", ClientHeight, "int", 1 )

}
; always force redraw of chrome window
Rst:=DllCall("user32\RedrawWindow", "uint", HwndCefParent, "uint", 0, "uint", 0, "uint", 1 )
return


CheckActivateCEF:
; is there a "windows activation" request? 
if(FileExist("activate2.tmp"))
{
	DeleteFile("activate2.tmp")
	
	OnBeforeActivation()
	
	if not TargetAlreadyOnTop()
	{
		WinActivate, ahk_exe %targetExeName%
	}
	
	OnDuringActivation()

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
	
	DllCall("user32\SetForegroundWindow", Ptr,HwndCefParent)
	
	OnAfterActivation()
}
return

ChromeOnTop()
{
	global lastActivated, HwndCefParent
	if (lastActivated*1)!=(HwndCefParent*1)
	{
		return false
	}
	return true
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

ShellMessage( wParam,lParam ) 
{	
	global lastActivated
	
	;MsgBox %wParam%
	If ( wParam = 4 or wParam = 32772) ;  HSHELL_WINDOWACTIVATED := 4,  HSHELL_RUDEAPPACTIVATED:=32772
	{
		lastActivated:=lParam
	}
}