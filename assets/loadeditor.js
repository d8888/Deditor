var editor = null;
var contentChanged = false;
var caretSelChanged = false;
var textSize=14;
var lastHeartBeat = 0;
var heartBeatTimer;
var loadingScreenOn = false;


window.onload = function() {

	CodeMirror.defineExRegexMode("radreport", grammar);
	//global scope editor
	editor = CodeMirror.fromTextArea(document.getElementById("code_input"), {
	  lineNumbers: false,
	  mode: "radreport",
	  matchBrackets: true,
	  lineWrapping: false,
	  lineSeparator: "\r\n",
	  extraKeys: {
		"F4": function(cm) { searchUnderscore(0); },
		"Ctrl-;": function(cm) { searchUnderscore(2); },
		"Ctrl-'": function(cm) { searchUnderscore(1); },
		"F5": function(cm) { rewarpSelection(); },
		"Ctrl-]": function(cm) { setTextSize(textSize+1); },
		"Ctrl-[": function(cm) { setTextSize(textSize-1); },
		"Ctrl-Z": function(cm) { performUndo(); },
		"Ctrl-Y": function(cm) { performRedo(); },
		"Insert": function(cm) { editor.toggleOverwrite(false); },
		"Tab": function(cm){ cm.replaceSelection(Array(cm.getOption('tabSize')).join(""));},
		},
	});

	//editor.on("blur", enable_key);
	//editor.on("focus", disable_key);

	//full screen
	editor.setOption("fullScreen", true)

	//editor.on("change", syncTextToTarget);
	editor.on("change", function(cm, changeobj){contentChanged=true; });
	editor.on("cursorActivity", function(){caretSelChanged=true; });
	editor.on("mousedown", function(){activateEditorWindow();});
	editor.on("mouseup", function(){activateEditorWindow();});
	
	setInterval(function(){ syncTextToTarget(); }, 80);
	setInterval(function(){ syncCaretPosToTarget(); }, 80);



	signalInitComplete(1);
	//setInterval(function(){ console.log("main::alive") }, 10000);
	setTextSize(textSize);
	console.log("editor JS executed.")
	
};



function showErrorRustCrash(error) {
	var err = "程式故障："+error;

	Swal.fire({
		icon: 'error',
		title: err,
		html: getReportDump("請備份報告，並重開本編輯軟體"),
		footer: ''
	}).then((result) => {
		worker.postMessage(["reopensocket"])
	});
};


function dispatch(request)
{
	if(request["tasktype"]=="sync")
	{
		setContent(request["detail"]);
	}else if(request["tasktype"]=="synccaret")
	{
		var temp = atou(request["detail"]).split("#");
		setCaret(temp[0], temp[1]);
	}else if(request["tasktype"]=="init")
	{
		signalInitComplete(2);
	}else if(request["tasktype"]=="alive")
	{
		lastHeartBeat = Date.now();
	}

}




function sendRequest(tasktype, detail)
{
	worker.postMessage(["sendRequest", tasktype, detail]);
}

function searchUnderscore(pos)
{
	keyword = /_+/g
	
	var backward = false;
	if(pos==0)
	{
		// search from start
		pos = CodeMirror.Pos(editor.firstLine(), 0);
	}else if(pos==1)
	{
		// search next
		pos = editor.getDoc().getCursor();
	}else if(pos==2)
	{
		// search backward
		pos = editor.getDoc().getCursor();
		pos = moveCursorBackOne(getSelectionHead(pos));
		backward = true;
	}
	
	var cursor = editor.getSearchCursor(keyword , pos, {caseFold: true, multiline: true});
    if(cursor.find(backward)){ //move to that position.
		editor.setSelection(cursor.from(), cursor.to());
		editor.scrollIntoView({from: cursor.from(), to: cursor.to()}, 20);
    }
	return;
}

function syncTextToTarget()
{
	if(!contentChanged)
	{
		return;
	}
	contentChanged=false;
	
	addWrap();
	

	var val = utoa(editor.getDoc().getValue());	
	
	//console.log(editor.getDoc().getValue());
	sendRequest("sync2", val);
	
	// force a caret sync
	caretSelChanged=true;
	syncCaretPosToTarget();
}

function activateEditorWindow()
{
	sendRequest("activate2"," ");
	window.focus();
}

function moveCursorBackOne(pos)
{
	if(pos["ch"]>0)
	{
		pos["ch"] = pos["ch"]-1;
	}else if(pos["line"]>0)
	{
		pos["line"] = pos["line"]-1;
		delete pos["ch"];
	}
	return pos;
}

function getSelectionHead(cursor)
{
	var fromxy = editor.getDoc().getCursor("from");
	var fy = fromxy["line"];
	var fx = fromxy["ch"];
	
	var endxy = editor.getDoc().getCursor("to");
	var ey = endxy["line"];
	var ex = endxy["ch"];
	if((fy!=ey) || (fx!=ex))
	{
		return fromxy;
	}
	return cursor;
}

function syncCaretPosToTarget()
{	
	if(!caretSelChanged)
	{
		return;
	}
	caretSelChanged = false;
	
	
	var fromxy = editor.getDoc().getCursor("from");
	var fy = fromxy["line"];
	var fx = fromxy["ch"];
	
	var endxy = editor.getDoc().getCursor("to");
	var ey = endxy["line"];
	var ex = endxy["ch"];
	
	if((fy!=ey) || (fx!=ex))
	{
		var start = editor.getDoc().indexFromPos(fromxy);
		var end = editor.getDoc().indexFromPos(endxy);
		
		sendRequest("syncsel2", start+"#"+end);
		//console.log(start+"#"+end);
	}else
	{
		var xy = editor.getDoc().getCursor();	
		var s1 = editor.getDoc().indexFromPos(xy);
		
		sendRequest("syncsel2", s1+"#"+s1);
	}
}

function replaceAberrantCrLf(input)
{
	//remove all \r, \n if not appear with each other
	input = input.replace(/(?<!\r)\n/g, ""); 
	input = input.replace(/\r(?!\n)/g, "");
	return input
}

function packRedundantSpace(input)
{
	input = input.replace(/\ {2,}/g, " ");
	return input;
}

function setContent(newContent)
{
	var decoded = atou(newContent);
	decoded = replaceAberrantCrLf(decoded);
	
	//decoded = decoded.replace(/\n/g, "\r\n");
	//decoded = decoded.replace(/\n/g, "|\r\n|");
	
	//editor.getDoc().setValue(decoded);
	var oldContent = editor.getDoc().getValue();
	var end = oldContent.length+5;
	var exy = editor.getDoc().posFromIndex(end);
	
	editor.getDoc().replaceRange(decoded, {line:0, ch:0}, exy);
	
	contentChanged = true;
	
	return;
}

function setCaret(x, y)
{
	console.log("x,y:"+x+" "+y);
	
	if(y >= editor.lineCount())
	{
		return;
	}
	if(x > editor.getLine(y).length)
	{
		return;
	}
	
	editor.focus();
	editor.setCursor({line: +y, ch: +x})
	
	caretSelChanged = true;
	
	//console.log("setCaret: cursor is:"+x+" "+y);
	return;
}

// from: http://levy.work/2017-03-24-black-magic-js-atob-with-utf8/
// 使用utf-8字符集进行base64编码
function utoa(str) {
    return window.btoa(unescape(encodeURIComponent(str)));
}
// 使用utf-8字符集解析base64字符串 
function atou(str) {
    return decodeURIComponent(escape(window.atob(str)));
}

function performUndo()
{
	var last = getLastChangeHistory();
	if(last && last.hasOwnProperty("onemoreskip"))
	{
		//do one additional undo
		editor.execCommand("undo");
			
		var lastundone = getUndoneLastChangeHistory();
		if(lastundone)
		{
			lastundone["onemoreskip"] = true;
		}
		
		editor.execCommand("undo");
	}else
	{
		editor.execCommand("undo");
	}
	

	return;
}

function performRedo()
{	
	editor.execCommand("redo");
	

	
	
	var last = getUndoneLastChangeHistory();
	
	if(last && last.hasOwnProperty("onemoreskip"))
	{
		//do one additional undo
		editor.execCommand("redo");
	}
	
	return;
}

function getLastChangeHistory()
{	
	for(var i = editor.doc.history.done.length-1; i>=0 &&
		!editor.doc.history.done[i].hasOwnProperty("changes"); i--)
	{
	}
	return editor.doc.history.done[i];
}

function getUndoneLastChangeHistory()
{	
	for(var i = editor.doc.history.undone.length-1; i>=0 &&
		!editor.doc.history.undone[i].hasOwnProperty("changes"); i--)
	{
	}
	return editor.doc.history.undone[i];
}

function addWrap()
{
	var rst = _addWrap();
	// when performing undo, also automatically undo the addWrap operation
	if(rst==true)
	{
		var last = getLastChangeHistory();
		if(last)
		{
			last["onemoreskip"]=true;
		}
	}	
}

function _addWrap()
{
	//console.log("addWrap::entered");
	var maxColumn = maxColumnPerLine;

	var hasWrap = false;
	var doMerge = false;
	
	editor.startOperation();
	
	var nowCursor = editor.getDoc().getCursor();
	var nowLine = parseInt(nowCursor["line"]);
	var nowCh = parseInt(nowCursor["ch"]);
	
	for(var lineNum = 0;lineNum < editor.lineCount();)
	{
		var line = editor.getDoc().getLine(lineNum);
		if(line.length <= maxColumn)
		{
			lineNum ++;
			continue;
		}
		console.log("--------------------");
		hasWrap = true;



		var pos = findNearestSpace(line, maxColumn);
		var postline = line.slice(pos);
		var eatSpace = countBeginSpaces(postline);
		postline = postline.slice(eatSpace);
		var addSpace = calculateIndentation(lineNum);
		postline = " ".repeat(addSpace) + postline;
		
		if(nowLine > lineNum)
		{
			nowLine = nowLine + 1;
			doMerge = false;
		} else if(nowLine == lineNum && nowCh>=pos)
		{
			nowLine = nowLine + 1;
			nowCh = nowCh - pos - eatSpace + addSpace;
			doMerge = false;
		} else
		{
			if(lineNum+1 < editor.lineCount() && !isHeader(lineNum+1))
			{
				//only merge next line if next line is not a "heading" line
				doMerge = true;
			}else
			{
			    doMerge = false;
				//console.log("no merge:"+calculateIndentation(lineNum+1));
			}
		}

		
		var newline = line.slice(0,pos)+"\r\n"+postline;
		editor.getDoc().replaceRange(newline, {line:lineNum, ch:0}, {line:lineNum});
		editor.getDoc().setCursor({line:nowLine, ch:nowCh});
		
		// merge line lineNum+1(spliced new line) and lineNum+2 (previous immediate next line before line slicing)
		if(doMerge && lineNum+2 < editor.lineCount())
		{
			mergeLine(lineNum+1);
		}
		
		//rescan again
		lineNum = 0;
	}
	if(hasWrap)
	{
		contentChanged = true;
	}
	
	editor.endOperation();
	
	return hasWrap;
	//console.log("addWrap::return");
}

function mergeLine(lineNum)
{
	// merge line lineNum and lineNum+1 into lineNum, heading spaces from lineNum+1 is removed
	if(lineNum >= editor.lineCount()-1) 
	{
		console.log("oh no!");
		console.log(lineNum);
		console.log(editor.lineCount());
		return;
	}
	var thisline = editor.getDoc().getLine(lineNum).replace(/(\r|\n)+$/, '');
	var nextline = editor.getDoc().getLine(lineNum+1);
	nextline = nextline.slice(countBeginSpaces(nextline));
	console.log("mergeLine::merging line "+lineNum+":"+thisline+" and line "+(lineNum+1)+":"+nextline);
	editor.getDoc().replaceRange(thisline+" "+nextline, {line:lineNum, ch:0}, {line:lineNum});
	deleteLine(lineNum+1);
}

function deleteLine(lineNum)
{
	editor.getDoc().replaceRange("", {line:lineNum, ch:0}, {line:lineNum+1, ch:0});
}

function isAtLastLine()
{
	var nowCursor = editor.getDoc().getCursor();
	var nowLine = nowCursor["line"];
	return parseInt(nowLine) >= editor.lineCount()-1;
}

function isAtEOL()
{
	var nowCursor = editor.getDoc().getCursor();
	var nowLine = nowCursor["line"];
	var nowCh = nowCursor["ch"];
	
	var line = editor.getDoc().getLine(nowLine);
	return parseInt(nowCh) == line.length;
}

function isHeader(lineNum)
{
	var headers = [/^\s*-\s*/, /^\s*\d+\. \s*/, /^\s*\/\s*/, /^\s*(?=[A-Z])/];
	
	var line = editor.getDoc().getLine(lineNum);
	
	for(key in headers)
	{
		var regex = headers[key];
		var rst = regex.exec(line);
		if(rst!==null)
		{
			return true;
		}
	}
	return false;
}

function calculateIndentation(lineNum)
{
	// 注意和上面 isHeader 差別在最後一個 
	var headers = [/^\s*-\s*/, /^\s*\d+\. \s*/, /^\s*\/\s*/, /^\s*(?=[A-Z])/, /^\s+/];

	var line = editor.getDoc().getLine(lineNum);
	
	for(key in headers)
	{
		var regex = headers[key];
		var rst = regex.exec(line);
		//console.log("calculateIndentation::regex is"+regex+" result is:"+rst);
		if(rst!==null)
		{
			//console.log("calculateIndentation::matched regex "+regex+" match:"+rst[0]);
			//console.log("calculateIndentation::returning "+rst[0].length);
			return rst[0].length;
		}
	}
	return 0;
}

function countBeginSpaces(valstr)
{
	var i;
	for(i=0;i<valstr.length;i++)
	{
		if(valstr.slice(i,i+1)!=" ")
		{
			break;
		}
	}
	return i;
}

function findNearestSpace(valstr, startpos)
{
	valstr = valstr.slice(0, startpos);
	var ret = valstr.lastIndexOf(" ");
	ret = (ret == -1)?startpos:ret;
	return ret;
}

function setTextSize(newsize)
{
	textSize = newsize;
	editor.getWrapperElement().style["font-size"] = textSize+"px";
	editor.refresh();
}

function rewarpSelection()
{
	var fromxy = editor.getDoc().getCursor("from");
	var fy = fromxy["line"];
	var fx = fromxy["ch"];
	
	var endxy = editor.getDoc().getCursor("to");
	var ey = endxy["line"];
	var ex = endxy["ch"];
	
	if((fy==ey) && (fx==ex))
	{
		return;
	}
	
	var spos = editor.getDoc().indexFromPos(fromxy);
	var epos = editor.getDoc().indexFromPos(endxy);
	var content = editor.getValue().slice(spos, epos);
	
	var lines = content.split("\r\n");
	var rst = "";
	for(key in lines)
	{
		var line = lines[key];
		if(rst.length>0) rst += " ";
		rst = rst + line.slice(countBeginSpaces(line));
	}
	
	rst = packRedundantSpace(rst);
	
	editor.getDoc().replaceSelection(rst);
}





function signalInitComplete(param)
{	
	if( typeof signalInitComplete.timeoutID == 'undefined' ) {
        signalInitComplete.timeoutID = -1;
    }
	
	if(param == 1)
	{
		signalInitComplete.timeoutID = window.setInterval(( () => sendRequest("init"," ") ), 2000);
	}else if(param == 2)
	{
		if(signalInitComplete.timeoutID != -1)
		{
			window.clearInterval(signalInitComplete.timeoutID);
		}
	}
	
}

function showErrorRustLag()
{
	var err = "同步發生延遲，設法回復中";
	
	Swal.fire({
		icon: 'error',
		title: err,
		html: getReportDump("若無法回復，請備份報告，並重開本編輯軟體"),
		onBeforeOpen: () => {
			Swal.showLoading();
		},
		onClose: () => {},
		onAfterClose () {
			Swal.hideLoading()
		},
		allowOutsideClick: false,
		allowEscapeKey: false,
		allowEnterKey: false
	}).then((result) => {
		lastHeartBeat = 0;
		//heartBeatTimer = setInterval(function(){ heartBeat(); }, 200);
	});
}

function hideErrorRustLag()
{
	Swal.hideLoading();
	Swal.close();
}


function getReportDump(suggestion)
{
	var s = "<p style=\"text-align:center\">"+suggestion+"</p><br><pre>"+escapeHtml(editor.getValue())+"</pre>";
	return s;
}

function escapeHtml(unsafe) {
    return unsafe
         .replace(/&/g, "&amp;")
         .replace(/</g, "&lt;")
         .replace(/>/g, "&gt;")
         .replace(/"/g, "&quot;")
         .replace(/'/g, "&#039;");
 }




