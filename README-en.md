# Video demo

[![Video demo](https://img.youtube.com/vi/VV6W8LjA8tY/0.jpg)](https://youtu.be/VV6W8LjA8tY)

Deditor can help word processing software (such as the Windows-built-in notepad, or some ancient software written in VB6) to add syntax highlighting and other functions that modern IDEs commonly have, without modifying the target program. 



## Table of Contents

- [Background](#background)
- [QuickStart](#quickstart)
- [Install](#install)
- [Usage](#usage)
- [How does it work?](#architecture)
- [Building](#building)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)
- [License](#license)
- [3rd-party-licenses](#3rd-party-licenses)


## Background

The author works in a hospital. The input interface of the radiology report input software provided by the hospital is the textarea control of VB6. There is no grammar highlighting, auto-completion, spell checking, theme and other functions commonly found in modern IDEs or word processing software. It is error-prone and cause eye discomfort if prolonged use.

It is impractical to request information department to rebuild software in author’s situation. Therefore the author created the program, which is based on Autohotkey script and Codemirror, provides overlay UI with above functionality without needing to modify the original report software. VB6 textarea is upgraded to lightweight IDE immediately after use 


Major features:
1. No need to modify the original report software. The program take care of text synchronization of overlay UI and target report software.
2. Provide grammar highlighting, auto-completion, spell checking.
3. Keywords for syntax highlighting and dictionary for auto-completion, spell checking can be customized. The current dictionary uses words derived from radiology textbooks. Keywords for syntax highlighting come from the author’s keyword list used in daily practice. 



## QuickStart

1. Confirm that Google Chrome browser and Autohotkey are installed on the computer.
2. Download/Extract Deditor to a new folder. Copy config.ahk.template to config.ahk
3. Execute Windows-built-in notepad (Start -> Execute -> notepad.exe in Windows 7). Using Deditor on program other than notepad requires modifying config.ahk.
4. Execute showeditor.ahk
5. Enter keywords such as "nodule", "stone", "free air", etc., and see the keywords automatically change color


## Usage

### Requirement

* The user must have installed Google Chrome browser and Autohotkey.
* Windows 7, 10 has been preliminary tested. Windows XP and 8 is not tested.

### Install

1. Before using Deditor on a new program for the first time, you need to change settings. First open the word processing software you wish to apply syntax highlighting, and use Autohotkey's built-in Window Spy to find out classNN of the control that requires syntax highlighting. Then modify config.ahk, set targetExeName and targetControl to the executable file name and control item classNN. Take the built-in Windows notebook as an example, the settings are as follows:

```
	targetExeName := "notepad.exe"
	targetControl := "Edit1"
```

2. For normal use, first start the word processing software as usual, and then start showeditor.ahk.

3. If the control of the target program and Deditor keep trying to overlap each other, set hideOriginalControl to true

```
	hideOriginalControl:=true
```

### Default keys
|Key		|description							            |
|-----------|---------------------------------------------------|
| F4		|Move to the first underscore						|
| F5		|Combine selected text into one paragraph			|
| Ctrl + ;	|Move to the next underscore  						|
| Ctrl + '	|Move to the previous underscore					|
| Ctrl + ]	|Zoom-in											|
| Ctrl + \[	|Zoom-out    										|
| Ctrl + Z	|Undo												|
| Ctrl + Y	|Redo												|
| Ctrl + F1	|Change theme										|
| Numpad End|Activate the Deditor window						|

### Configuration

* colorrule.txt can determine "what keywords" and "what color" to apply syntax highlighting. Colorrule.txt has some built-in keywords for reference. The file format is as follows:
* theme setting is defined in config.ahk
* CSS files can be found in assets/theme

```
                     ; text after semicolon are comment
                     ; ##classname indicates following keywords use CSS style 'cm-classname'
##critical           ; e.g ##critical indicates following keywords use 'cm-critical' CSS style
tumor                ; "tumor" will use 'cm-critical' style regardless of case
reg:prominent.*hilum ; The "reg:" prefix indicates that the following is a regular expression. The matching is case insensitive
                     ; prominent right hilum、prominent left hilum.... all use 'cm-critical' style

##info1              ; The keyword after this line will use 'cm-info1' CSS style
```


* assets/config.js contains front-end related settings, such as max number of chars per row before line-break occurs
* lib/uievent.ahk allows user to "intercept" specific "events" for customization in a similar way to event hook. Review source code for further details of events

* The default hotkeys are defined in assets/loadlibrary.js and showeditor.ahk


## Architecture


```
.                   Root directory, including main scripts and dependencies
│  
├─assets			Front-end related resources, including HTML, JS, webfont
│  ├─codemirror
│  └─theme			user-defined themes
├─editsrv  			editorsrv.exe source code, which helps Chrome communicate with the "outside world" through websocket
└─lib				Other necessary Autohotkey scripts
```

The user interface in Deditor is actually CodeMirror code editor running on the Chrome browser.

After Deditor is started, it will execute Chrome and run the editor as a Chrome App, and then the Chrome window will be "injected" into the target program. The synchronization of the text and cursor position between Chrome and the target program is done through Javascript, editorsrv.exe (written in Rust), and Autohotkey scripts.



# Building

Deditor is basically composed of scripts, and only editorsrv.exe (written in Rust) requires additional compilation. The existing stable version of Rust should be able to compile it via "cargo build".

Compiling editorsrv for the first time may require "rustup target add i686-pc-windows-msvc"


## Contributing

Pull requests and forking are welcomed. Also welcome to discuss together on Github.

# Disclaimer

This software and other information contained in it is provided as "as is", and the author does not make any guarantee for its use. Users should take their own risk, and it is strongly recommended to test carefully before applying it in a production environment.

As a hobby script-based project which is designed to "get things done quickly" and written by an amateur programmer, the code writing and structure are not professional and some problems are obvious, especially complete absence of tests and outdated, unprofessional programming especially Javascript. I hope to get your understanding.

Please refer to other documents carefully, for other statements

## License

Please see [LICENSE.md](LICENSE.md)

## 3rd-party-licenses

Please see [3rd-party-licenses.md](3rd-party-licenses.md)

