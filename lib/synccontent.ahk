#SingleInstance force
#include lib\helper.ahk
#include lib\base64.ahk
#include config.ahk
#NoTrayIcon
#Persistent

selStart:=-1
selEnd:=-1
nowContent:=""
nowtarget:=""

HwndCefParent:=A_Args[1]
HwndCefParent+=0
if(HwndCefParent="")
{
	MsgBox need params!
	ExitApp
}

for index, element in SendToTarget
{
	key:= "$" element[1]
	Hotkey, %key% , HandleSpecialKey
} 

for index, element in SendToTargetWinMenu
{
	key:= "$" element[1]
	Hotkey, %key% , HandleWinMenu
} 



; For sync at least once
Gosub TextToCEF
Gosub CaretToCEF

SetTimer, DetectChange, 30
return

DetectChange:
; has main program been closed?
if(!FileExist("main.tmp"))
{
	ExitApp
}

; has the text change unexpectly?
ControlGetText, nowtarget, %targetControl%,ahk_exe %targetExeName%
if(ErrorLevel)
{
	; something happened, such as control out of focus.
} else if(nowContent!=nowtarget)
{
	nowContent:=nowtarget
	Gosub TextToCEF
	Gosub CaretToCEF
} else if(FileExist("sync2.tmp") and GetEnable()!=0)
{
	lastread:=""
	
	; sync report from CEF to Target control
	content:=trim(ReadFile("sync2.tmp", 0, 1))
		
	if(StrLen(content)>0)
	{
		sync2text:=b64Decode(content)
	}else
	{
		sync2text:=""
	}
	
	; use multiple check to prevent from accident overwrite
	if(CheckTarget(sync2text, nowtarget))
	{
		sleep, 15
		if(CheckTarget(sync2text, nowtarget))
		{
			ControlSetText, %targetControl%, %sync2text%, ahk_exe %targetExeName%
			; if ControlSetText fail, nowContent will not be updated and update will be performed again
			ControlGetText, nowContent, %targetControl%,ahk_exe %targetExeName%
		}
	}
}

if(FileExist("syncsel2.tmp") and GetEnable()!=0)
{
	Gosub SelectionToTarget
}

return


CaretToCEF:
; sync caret position from target control to chrome
ControlGet, cy, CurrentLine ,, %targetControl%, ahk_exe %targetExeName%
ControlGet, cx, CurrentCol ,, %targetControl%, ahk_exe %targetExeName%
cx:=cx-1
cy:=cy-1
DeleteFile("synccaret.tmp")
str:=cx "#" cy
;DllCall("user32\SetFocus", Ptr,Hwndcef, Ptr)
MakeCEFForegroundIfEnabled(HwndCefParent)
FileAppend, %str%, synccaret.tmp
return


TextToCEF:
; sync report from target control to chrome
ControlGetText, text, %targetControl%,ahk_exe %targetExeName%

if(targetLang!="UTF-8")
{
	DeleteFile("sync.big5.tmp")
	FileAppend, %text%, sync.big5.tmp
	DeleteFile("sync.tmp")
	AnsiFileToUTF8("sync.big5.tmp", "sync.tmp", targetLang)
	DeleteFile("sync.big5.tmp")
}else
{
	DeleteFile("sync.tmp")
	FileAppend, %text%, sync.tmp
}


MakeCEFForegroundIfEnabled(HwndCefParent)
return


SelectionToTarget:
; sync selection from chrome to target control
syncsel2content:=trim(ReadFile("syncsel2.tmp", 1, 1))

Array := StrSplit(syncsel2content , "#")
startpos:=Array[1]+0
endpos:=Array[2]+0
SendMessage, 0xB1, startpos, endpos, %targetControl%,ahk_exe %targetExeName%  ; EM_SETSEL

if(startpos!=endpos)
{
	selStart:=startpos
	selEnd:=endpos
}
return


SendKey(keycode)
{
	global selStart, selEnd
	global targetControl, targetExeName
	
	loop,2
	{
		SendMessage, 0xB1, selStart, selEnd, %targetControl%,ahk_exe %targetExeName%  ; EM_SETSEL
		sleep, 50
	}
	PostMessage, 0x0100, keycode, 0,  %targetControl%,ahk_exe %targetExeName% 
	return
}


HandleSpecialKey:
key:= A_ThisHotkey
key:= RegExReplace(key, "^\$" , "")
if WinActive(editorTitle)
{
	for index, element in SendToTarget
	{
		if element[1]=key
		{
			SendKey(element[2])
		}
	}
}else
{
	Send {%key%}
}
return


HandleWinMenu:
key:= A_ThisHotkey
key:= RegExReplace(key, "^\$" , "")
if WinActive(editorTitle)
{
	for index, element in SendToTargetWinMenu
	{
		if element[1]=key
		{
			if(element[2].MaxIndex()==1)
			{
				a:=element[2][1]
				WinMenuSelectItem, ahk_exe %targetExeName%,, %a%
			}else if(element[2].MaxIndex()==2)
			{
				a:=element[2][1]
				b:=element[2][2]
				WinMenuSelectItem, ahk_exe %targetExeName%,, %a%,%b%
			}
		}
	}
}else
{
	Send {%key%}
}
return
