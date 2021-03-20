#SingleInstance force

BackSlash(input)
{
	return rtrim(input,"\") "\"
}

GetDir(input)
{
	Array := StrSplit(input , "\")
	dir:=""
	
	Array.Remove(Array.MaxIndex())
	for index, element in Array
	{
		if(dir!="")
		{
			dir:=dir "\"
		}
		dir:=dir element
	}
	return dir
}

ahkdir:=GetDir(A_AhkPath)
compilerdir:=BackSlash(ahkdir) "Compiler"
compiler:="""" BackSlash(compilerdir) "Ahk2Exe.exe"""
binfile:=BackSlash(compilerdir) "Unicode 32-bit.bin"

; make output and compile temp directory and clean them
cmd:="md output"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="md compiletemp"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="del /Q .\output\*"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="del /Q .\compiletemp\*"
RunWait, %ComSpec% /c %cmd% ,,Hide


cmd:="md compiletemp\lib"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="md output\lib"
RunWait, %ComSpec% /c %cmd% ,,Hide




; copy all scripts to compile temp dir
cmd:="copy *.ahk .\compiletemp\"
RunWait, %ComSpec% /c %cmd% ,,Hide
cmd:="copy .\lib\*.ahk .\compiletemp\"
RunWait, %ComSpec% /c %cmd% ,,Hide
cmd:="copy .\lib\*.ahk .\compiletemp\lib\"
RunWait, %ComSpec% /c %cmd% ,,Hide


; Start compiling script
rootdir:=a_scriptdir
srcdir:=rootdir "\compiletemp"

SetWorkingDir, %srcdir%

cmd:=compiler " /in showeditor.ahk /out ..\output\showeditor.exe /bin """ binfile """"
RunWait, %cmd%,,Hide

cmd:=compiler " /in guard.ahk /out ..\output\lib\guard.exe /bin """ binfile """"
RunWait, %cmd% ,,Hide

cmd:=compiler " /in syncuipos.ahk /out ..\output\lib\syncuipos.exe /bin """ binfile """"
RunWait, %cmd% ,,Hide

cmd:=compiler " /in synccontent.ahk /out ..\output\lib\synccontent.exe /bin """ binfile """"
RunWait, %cmd% ,,Hide


; copy assets
SetWorkingDir, %rootdir%

cmd:="xcopy .\assets .\output\assets\ /E /H"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="copy *.exe .\output\"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="copy *.dll .\output\"
RunWait, %ComSpec% /c %cmd% ,,Hide

cmd:="copy *.txt .\output\"
RunWait, %ComSpec% /c %cmd% ,,Hide

; clear compile dir
FileRemoveDir,%srcdir%,1


Msgbox Done!