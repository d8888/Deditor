extern crate notify;
extern crate base64;

use notify::{Watcher, RecursiveMode, RawEvent, raw_watcher};
use std::sync::mpsc::channel;
use std::sync::{Arc, Mutex, Condvar};
use std::{thread, time};

use std::net::TcpListener;
use std::thread::spawn;
use serde_json::{Value};
// also see: https://crates.io/crates/tungstenite
use tungstenite::protocol::Message;
use tungstenite::protocol;
use tungstenite::server::accept;
use std::fs;
//use fancy_regex::Regex;






fn wsserver(){
	let server = TcpListener::bind("127.0.0.1:9001").unwrap();
	println!("local port binded");
	
	// is the editor initialized?
	let pair = Arc::new((Mutex::new(false), Condvar::new()));
	
	
	
	
	for stream in server.incoming() {
		let stream_ori = stream.unwrap();
		let stream_clone = stream_ori.try_clone().expect("TCPStream clone failed...");
	
		
		let pair2 = Arc::clone(&pair);
		spawn (move || {
			let mut websocket = accept(stream_ori).unwrap();
			
			
			
			loop {
			
				let msg = match websocket.read_message() {
					Ok(message) => message,
					Err(error) => {
						println!("thread 1 websocket wrror! {:?}", error);
						return;
					}
				};
				println!("message coming!");
				
				
				match msg {
					Message::Text(txt) => {
						println!("message: {:?}", txt);
						
						let v: Value = serde_json::from_str(txt.as_ref()).unwrap();				
						let t = &v["tasktype"];
						let detail = if let Value::String(s) = &v["detail"] {s.clone()} else {String::from("")};
					
						match t{
							Value::String(val) if val=="init" => {
								let (lock, cvar) = &*pair2;
								let mut initptr = lock.lock().unwrap();
								*initptr = true;
								cvar.notify_one();
								
								let job = format!("{{
									  \"tasktype\": \"init\", 
									  \"detail\": \" \"
									}}");
								let writemsg = Message::Text(job);
								websocket.write_message(writemsg).unwrap();
								println!("finished writing message");
								
							},
							Value::String(val) if val=="healthcheck" => {
								let job = format!("{{
									  \"tasktype\": \"alive\", 
									  \"detail\": \" \"
									}}");
								let writemsg = Message::Text(job);
								websocket.write_message(writemsg).unwrap();
								println!("finished writing message");
							},
							Value::String(val) if (val=="sync2" || val=="activate2" 
								|| val=="syncsel2") => {
								let fname = format!("{}.tmp", val);
								write_files_with_retry(&fname, detail.as_bytes(), 10, 20);
								println!("finished writing file {:?}", &fname);
							},
							_ => {
								panic!("invalid task type:{:?}", t);
							}
						}
						
					},
					_ => {
					}
				}
				
				
			}
		});
		
		let pair3 = Arc::clone(&pair);
		// stream for writing
		spawn (move || {
			
			// wait for JS client to init
			let (lock, cvar) = &*pair3;
			let mut started = lock.lock().unwrap();
			while !*started {
				started = cvar.wait(started).unwrap();
			}
			println!("CEF client initialization detected");
			
			
					 
			
		
			//let mut websocket = accept(stream_clone).unwrap();
			
			let mut websocket = protocol::WebSocket::from_raw_socket(stream_clone, protocol::Role::Server, None);
			
			
			// Create a channel to receive the events.
			let (tx, rx) = channel();

			// Create a watcher object, delivering raw events.
			// The notification back-end is selected based on the platform.
			let mut watcher = raw_watcher(tx).unwrap();

			// Add a path to be watched. All files and directories at that path and
			// below will be monitored for changes.
			watcher.watch("./", RecursiveMode::Recursive).unwrap();

			//init 
			process_files(&mut websocket);
			loop {
				match rx.recv() {
				   Ok(RawEvent{path: Some(path), op: Ok(op), cookie}) => {
					   println!("{:?} {:?} ({:?})", op, path, cookie);
					   
					   process_files(&mut websocket);
					   
				   },
				   Ok(event) => println!("broken event: {:?}", event),
				   Err(e) => println!("watch error: {:?}", e),
				}	
			}
		});
	}
}

fn write_files_with_retry(fname:&str, content:&[u8], sleep_interval:u64, max_try:u64)
{
	let s = time::Duration::from_millis(sleep_interval);
	
	for _ in 0..max_try
	{
		let x = fs::write(&fname, content);
		if x.is_ok()
		{
			//write file succeed!
			return;
		}
		thread::sleep(s);
	}
	panic!("Failed writing file:{:?}", fname);
}

fn process_files(websocket:&mut protocol::WebSocket<std::net::TcpStream>)
{
	if let Ok(content) = fs::read_to_string("sync.tmp")
	{
		let _ = fs::remove_file("sync.tmp");
		println!("sync.tmp detected: {:?}", content);
		
		let encodedrst = base64::encode(content.as_bytes());
		let job = format!("{{
			  \"tasktype\": \"sync\", 
			  \"detail\": \"{}\"
			}}", encodedrst);
		let writemsg = Message::Text(job);
		websocket.write_message(writemsg).unwrap();
		println!("thread 2 finished writing message");
	}
	if let Ok(content) = fs::read_to_string("synccaret.tmp")
	{
		let _ = fs::remove_file("synccaret.tmp");
		println!("synccaret.tmp detected: {:?}", content);
		
		let encodedrst = base64::encode(content.as_bytes());
		let job = format!("{{
			  \"tasktype\": \"synccaret\", 
			  \"detail\": \"{}\"
			}}", encodedrst);
		let writemsg = Message::Text(job);
		websocket.write_message(writemsg).unwrap();
		println!("thread 2 finished writing message");
	}
}



fn main() {
	println!("server initializing");
	//create another thread as websocket server
	let serverthread = spawn(move || {
		wsserver();
	});


	
	// the process never stop, so no need to join
	serverthread.join().unwrap();
	println!("server shutting down");
}