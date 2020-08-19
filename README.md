# Deditor ReadMe

[![影片示範](https://img.youtube.com/vi/y0-UroAVPw8/0.jpg)](https://youtu.be/y0-UroAVPw8)

Deditor 可幫助文書處理軟體（例如 Windows 內建記事本，VB6 寫的萬年公司報表軟體）加入語法高亮功能（syntax highlighting），且不需修改目標程式。


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

「語法高亮」能幫助使用者快速看到大量文字的重點，減輕使用者負擔、並減少漏看、錯看的機會。但許多基於陳舊技術（例如 Visual Basic 6 和 textarea 控制項）的古老軟體，基於技術理由，不一定允許修改原始碼加入此功能。

作者在非 IT 產業工作，觀察到非 IT 產業、公司內部使用的軟體容易有這種情形。出於興趣開發了此愛好項目，希望能解決這個常見的問題。


## QuickStart

1. 確認電腦已安裝 Google Chrome 瀏覽器和 Autohotkey。
2. 把 Deditor 下載至任意目錄。
3. 執行 Windows 內建記事本（Windows 7 為開始 -> 執行 -> notepad.exe）
4. 執行 showeditor.ahk
5. 輸入 nodule、stone、free air 等關鍵字，可看到關鍵字自動變色

## Usage

### Requirement

* 使用者必須已安裝 Google Chrome browser 和 Autohotkey。
* Windows 7, 10 有稍微測試。Windows XP、8 未測試。

### Install

1. 第一次使用 Deditor 前需進行設定，先開啟欲加入語法高亮的文書處理軟體，使用 Autohotkey 內建的 Window Spy 查出需要語法高亮功能的控制項 classNN。再修改 config.ahk，將 targetExeName 和 targetControl 設定為執行檔名稱和控制項 classNN。以 Windows 內建記事本為例，設定如下：

```
	targetExeName := "notepad.exe"
	targetControl := "Edit1"
```
2. 平常要使用，先開啟文書處理軟體，再啟動 showeditor.ahk 即可。
3. 若目標程式的控制項會和 Deditor 互相覆蓋，可把 hideOriginalControl 設為 true
```
	hideOriginalControl:=true
	
```

### Default keys
|按鍵		|說明									|
|-----------|---------------------------------------|
| F4		|移動到第一個由 underscore 構成的字串	|
| F5		|將選取文字合併成一段					|
| Ctrl + ;	|移動到下一個由 underscore 構成的字串	|
| Ctrl + '	|移動到上一個由 underscore 構成的字串	|
| Ctrl + ]	|文字放大								|
| Ctrl + \[	|文字縮小								|
| Ctrl + Z	|Undo									|
| Ctrl + Y	|Redo									|
| Numpad End|活化 Deditor 窗口						|

### Configuration

* colorrule.txt 可設定「哪些關鍵字可變色」和「變甚麼顏色」，內附 colorrule.txt 已內建可參考關鍵字，檔案格式如下：

```
					 ; 分號後面可加註解
					 ; ##rrggbb 表示此行後變這個顏色（本例為 FF0000，紅色）
##FF0000			 ; 後綴 "#nb#" 表示不要套粗體，例如 ##444444#nb#
tumor				 ; tumor 關鍵字不分大小寫一律變紅色
reg:prominent.*hilum ; "reg:" 前綴，表示後面是 regular expression，配對不分大小寫
					 ; prominent right hilum、prominent left hilum.... 都會變紅色

##0000FF			 ; 這行以後的關鍵字顏色設定為 0000FF （藍色）
```


* assets/config.js 包含前端環境設定，例如每列超過幾個字元後換行
* lib/uievent.ahk 使用者可用類似 event hook 的方式「攔截」 各事件進行客製化。事件何時被呼叫可直接看 .ahk 腳本
* 預設按鍵分別定義於 assets/loadlibrary.js 和 showeditor.ahk

## Architecture


```
.					根目錄，包含主要腳本和依賴工具
│  
├─assets			前端相關資源，包含 HTML、JS、webfont
│  └─codemirror
├─editsrv  			editorsrv.exe 原始碼，透過 websocket 協助 Chrome 與「外界」溝通
└─lib				其他必要 Autohotkey 腳本
```
使用者看到的 Deditor 輸入介面，實際上是運行在 Chrome 瀏覽器的 CodeMirror 代碼編輯器。

Deditor 啟動後會呼叫 Chrome，將編輯器作為 Chrome App 執行，然後 Chrome 的視窗會被「注入」目標程式。Chrome 和目標程式間文字、游標位置的同步透過 Javascript、editorsrv.exe（由 Rust 編寫）、Autohotkey 腳本進行

# Building

Deditor 基本由腳本組成，只有由 Rust 編寫的 editorsrv.exe 需要額外編譯。現有穩定版本 Rust 應該都能透過 cargo build 直接編譯
第一次編譯 editorsrv 可能需要執行： rustup target add i686-pc-windows-msvc 

## Contributing

歡迎 pull request 和 fork。也歡迎一起在 Github 上討論。

# Disclaimer

本軟體及所含之其他資訊按「現況」（as is）提供，作者對其之使用不作任何保證。使用者應自負風險，應用於生產環境前強烈建議仔細測試。

作者非專業軟體開發人員，作為業餘愛好項目之腳本程式，代碼寫法和架構不嚴謹，特別是完全沒有測試、代碼水平不高但 JS 又特別差等等，請多包涵。

其餘聲明請仔細參閱其他文件

## License

請參閱 [LICENSE.md](LICENSE.md)

## 3rd-party-licenses

請參閱 [3rd-party-licenses.md](3rd-party-licenses.md)

