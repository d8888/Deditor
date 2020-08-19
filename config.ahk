; DON'T CHANGE THIS unless change title in deditor.html
editorTitle:="deditormain===="  	

; Hide original control? false or true. 
hideOriginalControl:=true

; targetExeName: process name to override control, such as notepad.exe
; targetControl: control class name as seen in windowspy, such as "Edit1" (textarea in notepad.exe)
; Example:
; 	targetExeName := "notepad.exe"
;	targetControl := "Edit1"

targetExeName := "notepad.exe"
targetControl := "Edit1"

; Language of target control, big5, UTF-8, etc.

targetLang := "big5"

; Pass specific keys to target application for handling
; SendToTarget:= [[Hot key 1, Virtual-Key Code 1], [Hot key 2, Virtual-Key Code 2]....]
; Example:
; 	SendToTarget:= [["F1", 0x70], ["F2", 0x71]]

SendToTarget:= []

; auto hide UI if specified controls are visible
; Example: 
;	AvoidControl:=["AfxWnd401", "ListView20WndClass1"]

AvoidControl:=[]

; Also send a single left mouse click to these controls if chrome is activated
; Example
; 	ClickWhenActivate:=["ThunderRT6TextBox14"]
ClickWhenActivate:=[]