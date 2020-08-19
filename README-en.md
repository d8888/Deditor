# Deditor ReadMe

[![Video demo](https://img.youtube.com/vi/y0-UroAVPw8/0.jpg)](https://youtu.be/y0-UroAVPw8)

Deditor can help word processing software (such as the Windows-built-in notepad, or some ancient software written in VB6) to add syntax highlighting without modifying the target program.



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

"Syntax highlighting" can help users quickly see the key points of a large number of texts, reduce the burden on users, and reduce the chance of missing and misreading vital information. However, many ancient software based on outdated technologies (such as Visual Basic 6 and textarea controls) may not necessarily allow modification of the source code to add this feature for technical reasons.

The author works in non-IT industry, and has observed that such condition is common in software designed for corporate internal-use in non-IT industries. This hobby project is developed hoping to solve this common problem.


## QuickStart

1. Confirm that Google Chrome browser and Autohotkey are installed on the computer.
2. Download/Extract Deditor to a new folder.
3. Execute Windows-built-in notepad (Start -> Execute -> notepad.exe in Windows 7)
4. Execute showeditor.ahk
5. Enter keywords such as "nodule", "stone", "free air", etc., and see the keywords automatically change color


## Usage

### Requirement

* The user must have installed Google Chrome browser and Autohotkey.
* Windows 7, 10 has been preliminary tested. Windows XP and 8 is not tested.

### Install

1. Before using Deditor for the first time, you need to change settings. First open the word processing software you wish to apply syntax highlighting, and use Autohotkey's built-in Window Spy to find out classNN of the control that requires syntax highlighting. Then modify config.ahk, set targetExeName and targetControl to the executable file name and control item classNN. Take the built-in Windows notebook as an example, the settings are as follows:

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
| F4		|Move to the first string composed of underscore	|
| F5		|Combine selected text into one paragraph			|
| Ctrl + ;	|Move to the next string composed of underscore  	|
| Ctrl + '	|Move to the previous string composed of underscore	|
| Ctrl + ]	|Zoom-in											|
| Ctrl + \[	|Zoom-out    										|
| Ctrl + Z	|Undo												|
| Ctrl + Y	|Redo												|
| Numpad End|Activate the Deditor window						|

### Configuration

* colorrule.txt can determine "what keywords" and "what color" to apply syntax highlighting. Colorrule.txt has some built-in keywords for reference. The file format is as follows:


```
                     ; text after semicolon are comment
                     ; ##rrggbb means apply this color for keywords after this line (in this case, FF0000, red)
##FF0000             ; The suffix "#nb#" means "no bold", for example ##444444#nb#
tumor                ; "tumor" will turn red regardless of case
reg:prominent.*hilum ; The "reg:" prefix indicates that the following is a regular expression. The matching is case insensitive
                     ; prominent right hilum、prominent left hilum.... all turn red

##0000FF             ; The keyword after this line will be colored to 0000FF (blue)
```


* assets/config.js contains front-end related settings, such as max number of chars per row before line-break occurs
* lib/uievent.ahk allows user to "intercept" specific "events" for customization in a similar way to event hook. Review source code for further details of events

* The default hotkeys are defined in assets/loadlibrary.js and showeditor.ahk


## Architecture


```
.					Root directory, including main scripts and dependencies
│  
├─assets			Front-end related resources, including HTML, JS, webfont
│  └─codemirror
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

