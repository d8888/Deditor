FindChrome()
{
	candidate := []
	candidate.Push("\Apps\GoogleChromePortable32\App\Chrome-bin\chrome.exe") ; 自帶的乾淨 portable chrome 優先
	candidate.Push("C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
	candidate.Push(USERPROFILE "\AppData\Local\Google\Chrome\Application\chrome.exe")
	
	for index, element in candidate ; 
	{
		if(FileExist(element))
		{
			return element
		}
	}
	MsgBox Cannot find chrome installation, program will exit!
	ExitApp
}

ConstructChromeArgs()
{
	rst:=""
	
	; arguments copied from rust alcro crate
	rst:=rst " " "--disable-background-networking"
    rst:=rst " " "--disable-background-timer-throttling"
    rst:=rst " " "--disable-backgrounding-occluded-windows"
    rst:=rst " " "--disable-breakpad"
    rst:=rst " " "--disable-client-side-phishing-detection"
    rst:=rst " " "--disable-default-apps"
    rst:=rst " " "--disable-dev-shm-usage"
    rst:=rst " " "--disable-infobars"
    rst:=rst " " "--disable-extensions"
    rst:=rst " " "--disable-features=site-per-process"
    rst:=rst " " "--disable-hang-monitor"
    rst:=rst " " "--disable-ipc-flooding-protection"
    rst:=rst " " "--disable-popup-blocking"
    rst:=rst " " "--disable-prompt-on-repost"
    rst:=rst " " "--disable-renderer-backgrounding"
    rst:=rst " " "--disable-sync"
    rst:=rst " " "--disable-translate"
    rst:=rst " " "--disable-windows10-custom-titlebar"
    rst:=rst " " "--metrics-recording-only"
    rst:=rst " " "--no-first-run"
    rst:=rst " " "--no-default-browser-check"
    rst:=rst " " "--safebrowsing-disable-auto-update"
    ;rst:=rst " " "--enable-automation" <-- this cause "Chrome is being controlled by automated software"
    rst:=rst " " "--password-store=basic"
    rst:=rst " " "--use-mock-keychain"
	
	
	;launch our own app
	rst:=rst " " "--user-data-dir=" A_Temp "\chromedata"
	;rst:=rst " " "--silent-launch"
	;rst:=rst " " "--load-and-launch-app=" A_WorkingDir "\assets"
	rst:=rst " " "--kiosk file:///" A_WorkingDir "\assets\deditor.html"
	
	return rst
}

DeleteChromeTempFolder()
{
	DeleteFolder(A_Temp "\chromedata")
}

StartChromeBrowser()
{
	path:=FindChrome()
	path:= """" path """"
	cmdstr:=path " " ConstructChromeArgs()
	;FileAppend , %cmdstr%, startchrome.txt
	;ExitApp
	
	Run, %cmdstr%,,,chromepid
	return chromepid
}

WaitChromePID(title, waitms)
{
	sleepms:=200
	totalms:=0
	
	while(1)
	{
		WinGet, pid, PID , %title%
		if(pid="")
		{
			totalms:=totalms+sleepms
			Sleep,sleepms
		}else
		{
			break
		}
		if(totalms>=waitms)
		{
			MsgBox Cannot find chrome, program will exit
			ExitApp
		}
	}
	return pid
}



DeleteTempFiles()
{
	DeleteFile("*.tmp")
}

DeleteFile(filename)
{
	cmd:="del """ filename """"
	RunWait,%ComSpec% /c %cmd%,,Hide
}

DeleteFolder(filename)
{
	cmd:="rmdir /s /q """ filename """"
	RunWait,%ComSpec% /c %cmd%,,Hide
}

; TODO: replace ugly file I/O with better IPC solution?
GetEnable()
{
	if(!FileExist("enable.tmp"))
	{
		FileAppend 1, enable.tmp
	}
	FileRead, enable, enable.tmp
	; convert text to number
	enable:=enable*1
	return enable
}

SetEnable(newenable)
{
	try:=0
	while(1)
	{
		DeleteFile("enable.tmp")
		FileAppend %newenable%, enable.tmp
		Enable:=GetEnable()
		if(Enable=newenable)
		{
			break
		}
		try:=try+1
		if(try>100)
		{
			MsgBox Cannot change view
			return
		}
		sleep, 20
	}
}



MakeCEFForegroundIfEnabled(HwndCefParent)
{
	Enable:=GetEnable()
	
	if(Enable!=0)
	{
		DllCall("user32\SetForegroundWindow", Ptr,HwndCefParent)
	}
}

CheckTarget(sync2text, nowtarget)
{
	global targetExeName, targetControl
	
	ControlGetText, text, %targetControl%,ahk_exe %targetExeName%
	; check if text from CEF is different from current target text, and current target text hasn't been updated unexpectly
	
	if(sync2text!=text and nowtarget=text)
	{
		return true
	}
	return false
}


WinToClient(hWnd, ByRef x, ByRef y)
{
    WinGetPos wX, wY,,, ahk_id %hWnd%
    x += wX, y += wY
    VarSetCapacity(pt, 8), NumPut(y, NumPut(x, pt, "int"), "int")
    if !DllCall("ScreenToClient", "ptr", hWnd, "ptr", &pt)
	{
		; MsgBox %ErrorLevel%
        return false
	}
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
    return true
}


ReadFile(filename, deleteAfterRead, exitIfFail)
{
	FileRead, val, %filename%
	if(ErrorLevel and exitIfFail!=0)
	{
		err:="ReadFile::failed reading " filename
		MsgBox %err%
		ExitApp
	}
	if(deleteAfterRead)
	{
		DeleteFile(filename)
	}
	return val
}

AnsiFileToUTF8(infile, outfile, srclang)
{
	cmd:="iconv -f " srclang " -t UTF-8//IGNORE " infile " > " outfile
	RunWait,%ComSpec% /c %cmd%,,Hide
}

ansi2utf8(str)
{
	FileOpen(".utf8", "w", "UTF-8-RAW").Write(str)
	FileRead, str_utf8, .utf8
	FileDelete, .utf8
	Return, str_utf8
}

KillProcessPid(pid)
{
	cmd:="taskkill /pid " pid " /F"
	;MsgBox %cmd%
	RunWait,%cmd%,,Hide
	
}

KillProcessName(name)
{
	cmd:="taskkill /im " name " /F"
	;MsgBox %cmd%
	RunWait,%cmd%,,Hide
	
}

ProcessExist(PIDOrName){
	Process,Exist,%PIDOrName%
	return Errorlevel
}

IsControlVisible(control, target)
{
	ControlGet, vis1, Visible ,, %control%, %target%
	if(ErrorLevel)
	{
		return false
	}
	if(vis1=1)
	{
		return true
	}
	return false
}


SanityCheck()
{
	global targetExeName, targetControl
	
	if !FileExist("editorsrv.exe")
	{
		MsgBox, editorsrv.exe not found. Deleted by antivirus?
		return false
	}	
	
	ControlGet, Handle, Hwnd, , %targetControl%, ahk_exe %targetExeName%
	if(ErrorLevel)
	{
		;MsgBox %ErrorLevel%
		MsgBox Invalid targetExeName or targetControl, program failed to start
		return false
	}
	return true
}