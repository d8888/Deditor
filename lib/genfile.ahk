EscapeReg(line)
{
	special:=".()[]|{}*+?&$/-\"
	retval:=""
	
	Loop, Parse, line
	{
		c:=A_LoopField
		FoundPos := InStr(special, c)
		if(FoundPos>0)
		{
			retval:=retval "\"
		}
		retval:=retval c
	}
	return retval	
}

EscapeJSON(line)
{
	line := StrReplace(line, "\", "\\")
	return line
}

GenJS(coloraray, outfile)
{
	cmd:="del """ outfile """"
	RunWait,%ComSpec% /c %cmd%,,Hide

	lines:=""
	for key in coloraray
	{
		if(lines!="")
		{
			lines := lines ",`n"
		}
	
		jsline:="{""regex"": KEYWORD, ""token"": ""STYLE""}"
		kw:=coloraray[key][2]
		isReg:=coloraray[key][3]
		
		; we need case insensitive match
		if(isReg)
		{
			kw:="/" kw "/i"
		}else
		{
			kw:="/" EscapeReg(kw) "/i"
		}
		
		
		
		
		jsline:=StrReplace(jsline, "KEYWORD" , kw)
		stylepost:= coloraray[key][1]
		jsline:=StrReplace(jsline, "STYLE" , stylepost)
		
		lines:=lines jsline
	}
	jscontent:= "var grammar = [`n" lines "`n];"
	
	FileAppend, %jscontent%, %outfile%
}

GenMasterCSS(workfolder, searchfolder, outfile)
{
	curdir:=A_WorkingDir
	SetWorkingDir, %workfolder%
	
	cmd:="del """ outfile """"
	RunWait,%ComSpec% /c %cmd%,,Hide
	
	folder := rtrim(searchfolder, "\") "\"
	allcss:= folder "*.css"
	
	Loop, Files, %allcss%
	{
		folder2:=rtrim(searchfolder, "\") "/"
		val:= folder2 A_LoopFileName
		val:= "@import url(" val ");`n"
		FileAppend , %val%, %outfile%
	}
	
	SetWorkingDir, %curdir%
}

ProcessFilter(inputfile)
{
	coloraray:=Array()
	FileRead, rulefile,%inputfile%
	if ErrorLevel
	{
		MsgBox cannot read %inputfile%
		return
	}

	
	StringSplit, rulelines, rulefile,`n
	
	; init coloraray
	nowstyle:=""
	
	Loop, %rulelines0%
	{
		linecontent := rulelines%a_index%
		linecontent:=d8trim(linecontent)
		
		; is it blank?
		if StrLen(linecontent)=0
		{
			continue
		}
	
		;is this a comment?
		StringLeft, tmp, linecontent, 1
		if tmp=;
		{
			continue
		}
	
		;is this a style name?
		StringLeft, tmp, linecontent, 2
		if tmp=##
		{
			nowstyle:=trim(SubStr(linecontent, 3), " `t`r`n")
			continue
		}
		
		;is this regular expression?
		StringLeft, tmp, linecontent, 4
		if tmp=reg:
		{
			linecontent:=SubStr(linecontent, 5)
			coloraray.insert(Array(nowstyle,linecontent, 1))
			continue
		}
		
		
		;This is a normal keyword
		; Working on multidimentional array is painful ass in AHK
		coloraray.insert(Array(nowstyle,linecontent, 0))

	}

	return coloraray
}

