function worker_function() {
	var loadingScreenOn = false;
	var lastHeartBeat = 0;
	var heartBeatTimer;
	
	var socket = createSocket();
	function createSocket()
	{
		var mysocket = new WebSocket("ws://127.0.0.1:9001");
		mysocket.onmessage = function(event) {
			workerdispatch(event.data);
		};
		
		mysocket.onopen=function()
		{
			lastHeartBeat = performance.now();
			heartBeatTimer = setInterval(function(){ heartBeat(); }, 200);
		}
		
		mysocket.onerror = function(error) {
			postMessage(["rustcrash", error.message]);
			clearInterval(heartBeatTimer);
		};
		
		mysocket.onclose = function(error) {
			postMessage(["rustcrash", "同步機制被關閉"]);
			clearInterval(heartBeatTimer);
		};
		return mysocket;
	}
	

	function workerdispatch(message)
	{
		var request = JSON.parse(message);	
		if(request["tasktype"]=="alive")
		{
			lastHeartBeat = performance.now();
		}else
		{
			postMessage(["dispatchthis",request]);
		}
	}
	
	function send(tasktype, detail)
	{
		var req = {
				"tasktype": tasktype,
				"detail": detail,
			};
		var msg = JSON.stringify(req);
		socket.send(msg);
	}
	
	onmessage = function(e) {
		var action = e.data[0];
		if(action == "sendRequest")
		{
			var tasktype = e.data[1];
			var detail = e.data[2];			
			send(tasktype, detail);
		}else if(action == "reopensocket")
		{
			socket = createSocket();
		}
	}

	function heartBeat()
	{
		send("healthcheck","");
		var nowTime = performance.now();
		var threshold = 300;
		
		if(loadingScreenOn == false)
		{
			if(nowTime - lastHeartBeat > threshold)
			{
				postMessage(["rustlag"]);
				loadingScreenOn = true;
			}
		}else
		{
			if(nowTime - lastHeartBeat <= threshold)
			{
				//console.log(loadingScreenOn);
				var s = "lastheartbeat:"+lastHeartBeat;
				console.log(s);
				console.log(typeof(lastHeartBeat));
				console.log(lastHeartBeat>0);
				console.log(lastHeartBeat==0);
				console.log(lastHeartBeat<0);
				console.log(nowTime - lastHeartBeat);
				//console.log(nowTime);
				postMessage(["rustrevive"]);
				loadingScreenOn = false;
			}
		}
	}


	
}
var worker = new Worker(URL.createObjectURL(new Blob(["("+worker_function.toString()+")()"], {type: 'text/javascript'})));


worker.onmessage = function(e) {
	if(e.data[0] == "rustcrash")
	{
		showErrorRustCrash(e.data[1]);
	}else if(e.data[0] == "rustlag")
	{
		showErrorRustLag();
	}else if(e.data[0] == "rustrevive")
	{
		hideErrorRustLag();
	}else if(e.data[0] == "dispatchthis")
	{
		dispatch(e.data[1]);
	}
}