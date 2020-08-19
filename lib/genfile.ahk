GetStyle(input)
{
	nowcolor := SubStr(input, 1 , 6)
	isBold := not InStr(input, "#nb#")
	stylepostfix:="c" nowcolor
	if(not isBold)
	{
		stylepostfix:=stylepostfix "nb"
	}
	
	return Array(nowcolor, isBold, stylepostfix)
}

GenCSS(coloraray, outfile)
{
	cmd:="del """ outfile """"
	RunWait,%ComSpec% /c %cmd%,,Hide
	
	written:=""
	
	for key in coloraray
	{
		tmp:=GetStyle(coloraray[key][1])
		nowcolor := tmp[1]
		isBold := tmp[2]
		stylepost:= tmp[3]
		
		if(InStr(written, nowcolor))
		{
			continue
		}
		
		written:=written nowcolor "##"
		style=
		(
.cm-STYLEPOST {
  color: TRUECOLOR;
  font-weight:bold;
}

		)
		style:=StrReplace(style, "TRUECOLOR" , nowcolor)
		style:=StrReplace(style, "STYLEPOST" , stylepost)
		if(not isBold)
		{
			style:=StrReplace(style, "font-weight:bold;" , "font-weight:normal;")
		}
		
		FileAppend, %style%, %outfile%
	}
}

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
		tmp:=GetStyle(coloraray[key][1])
		stylepost:= tmp[3]
		jsline:=StrReplace(jsline, "STYLE" , stylepost)
		
		lines:=lines jsline
	}
	jscontent:= "var grammar = [`n" lines "`n];"
	
	FileAppend, %jscontent%, %outfile%
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
	nowcolor:="000000"
	
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
	
		;is this a color?
		StringLeft, tmp, linecontent, 2
		if tmp=##
		{
			nowcolor:=trim(SubStr(linecontent, 3), " `t`r`n")
			continue
		}
		
		;is this regular expression?
		StringLeft, tmp, linecontent, 4
		if tmp=reg:
		{
			linecontent:=SubStr(linecontent, 5)
			coloraray.insert(Array(nowcolor,linecontent, 1))
			continue
		}
		
		
		;This is a normal keyword
		; Working on multidimentional array is painful ass in AHK
		coloraray.insert(Array(nowcolor,linecontent, 0))

	}

	return coloraray
}

