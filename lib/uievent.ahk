#SingleInstance force
#include lib\helper.ahk
#include config.ahk
#Persistent



OnBeforeShowUI(ByRef X, ByRef Y, ByRef ClientWidth, ByRef ClientHeight, ByRef showUI)
{
	global targetExeName, targetControl
	
}

OnApplyMode(ByRef X, ByRef Y, ByRef ClientWidth, ByRef ClientHeight)
{
	if(GetEnable()=1) ;normal mode
	{
	}else if(GetEnable()=2) ;wide mode
	{
		ClientWidth := ClientWidth + 140
	}else if(GetEnable()=3) ;debug mode
	{
		Y:= Y + 140
	}
}

OnBeforeActivation()
{
	global targetExeName, targetControl
}

OnDuringActivation()
{
	global targetExeName, targetControl
}



OnAfterActivation()
{
	global targetExeName, targetControl
}
