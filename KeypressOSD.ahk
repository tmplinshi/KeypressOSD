; KeypressOSD.ahk
;--------------------------------------------------------------------------------------------------------------------------
; ChangeLog : v2.40 (2018-03-19) - Added font and background color settings
;             v2.30 (2018-03-16) - Settings are now saved to ini file.
;                                - Added settings GUI and tray menu.
;                                - Moved this script from Gist to GitHub.
;             v2.22 (2017-02-25) - Now pressing same combination keys continuously more than 2 times,
;                                  for example press Ctrl+V 3 times, will displayed as "Ctrl + v (3)"
;             v2.21 (2017-02-24) - Fixed LWin/RWin not poping up start menu
;             v2.20 (2017-02-24) - Added displaying continuous-pressed combination keys.
;                                  e.g.: With CTRL key held down, pressing K and U continuously will shown as "Ctrl + k, u"
;             v2.10 (2017-01-22) - Added ShowStickyModKeyCount option
;             v2.09 (2017-01-22) - Added ShowModifierKeyCount option
;             v2.08 (2017-01-19) - Fixed a bug
;             v2.07 (2017-01-19) - Added ShowSingleModifierKey option (default is True)
;             v2.06 (2016-11-23) - Added more keys. Thanks to SashaChernykh.
;             v2.05 (2016-10-01) - Fixed not detecting "Ctrl + ScrollLock/NumLock/Pause". Thanks to lexikos.
;             v2.04 (2016-10-01) - Added NumpadDot and AppsKey
;             v2.03 (2016-09-17) - Added displaying "Double-Click" of the left mouse button.
;             v2.02 (2016-09-16) - Added displaying mouse button, and 3 settings (ShowMouseButton, FontSize, GuiHeight)
;             v2.01 (2016-09-11) - Display non english keyboard layout characters when combine with modifer keys.
;             v2.00 (2016-09-01) - Removed the "Fade out" effect because of its buggy.
;                                - Added support for non english keyboard layout.
;                                - Added GuiPosition setting.
;             v1.00 (2013-10-11) - First release.
;--------------------------------------------------------------------------------------------------------------------------

#SingleInstance force
#NoEnv
SetBatchLines, -1
ListLines, Off

global TransN, ShowSingleKey, ShowMouseButton, ShowSingleModifierKey, ShowModifierKeyCount
     , ShowStickyModKeyCount, DisplayTime, GuiPosition, FontSize, GuiHeight, hGUI_s, BkColor, FontColor, FontStyle, FontName
scriptPID := DllCall("GetCurrentProcessId")

ReadSettings()
CreateTrayMenu()
CreateGUI()
CreateHotkey()
return

#if !WinExist("ahk_pid " scriptPID)
	OnKeyPressed:
		try {
			key := GetKeyStr()
			ShowHotkey(key)
			SetTimer, HideGUI, % -1 * DisplayTime
		}
	return

	OnKeyUp:
	return

	_OnKeyUp:
		tickcount_start := A_TickCount
	return

; ===================================================================================
CreateGUI() {
	global

	Gui, +AlwaysOnTop -Caption +Owner +LastFound +E0x20
	Gui, Margin, 0, 0
	Gui, Color, %BkColor%
	Gui, Font, c%FontColor% %FontStyle% s%FontSize%, %FontName%
	Gui, Add, Text, vHotkeyText Center y20

	WinSet, Transparent, %TransN%
}

CreateHotkey() {
	Loop, 95
	{
		k := Chr(A_Index + 31)
		k := (k = " ") ? "Space" : k

		Hotkey, % "~*" k, OnKeyPressed
		Hotkey, % "~*" k " Up", _OnKeyUp
	}

	Loop, 24 ; F1-F24
	{
		Hotkey, % "~*F" A_Index, OnKeyPressed
		Hotkey, % "~*F" A_Index " Up", _OnKeyUp
	}

	Loop, 10 ; Numpad0 - Numpad9
	{
		Hotkey, % "~*Numpad" A_Index - 1, OnKeyPressed
		Hotkey, % "~*Numpad" A_Index - 1 " Up", _OnKeyUp
	}

	Otherkeys := "WheelDown|WheelUp|WheelLeft|WheelRight|XButton1|XButton2|Browser_Forward|Browser_Back|Browser_Refresh|Browser_Stop|Browser_Search|Browser_Favorites|Browser_Home|Volume_Mute|Volume_Down|Volume_Up|Media_Next|Media_Prev|Media_Stop|Media_Play_Pause|Launch_Mail|Launch_Media|Launch_App1|Launch_App2|Help|Sleep|PrintScreen|CtrlBreak|Break|AppsKey|NumpadDot|NumpadDiv|NumpadMult|NumpadAdd|NumpadSub|NumpadEnter|Tab|Enter|Esc|BackSpace"
	           . "|Del|Insert|Home|End|PgUp|PgDn|Up|Down|Left|Right|ScrollLock|CapsLock|NumLock|Pause|sc145|sc146|sc046|sc123"
	Loop, parse, Otherkeys, |
	{
		Hotkey, % "~*" A_LoopField, OnKeyPressed
		Hotkey, % "~*" A_LoopField " Up", _OnKeyUp
	}

	If ShowMouseButton {
		Loop, Parse, % "LButton|MButton|RButton", |
			Hotkey, % "~*" A_LoopField, OnKeyPressed
	}

	for i, mod in ["Ctrl", "Shift", "Alt"] {
		Hotkey, % "~*" mod, OnKeyPressed
		Hotkey, % "~*" mod " Up", OnKeyUp
	}
	for i, mod in ["LWin", "RWin"]
		Hotkey, % "~*" mod, OnKeyPressed
}

MouseHotkey_On() {
	Loop, Parse, % "LButton|MButton|RButton", |
		Hotkey, % "~*" A_LoopField, On
}

MouseHotkey_Off() {
	Loop, Parse, % "LButton|MButton|RButton", |
		Hotkey, % "~*" A_LoopField, Off
}

ShowHotkey(HotkeyStr) {
	if WinActive("ahk_id " hGUI_s) {
		ActWin_X := ActWin_Y := 0
		ActWin_W := A_ScreenWidth
		ActWin_H := A_ScreenHeight
	} else {
		WinGetPos, ActWin_X, ActWin_Y, ActWin_W, ActWin_H, A
		if !ActWin_W
			throw
	}

	text_w := (ActWin_W > A_ScreenWidth) ? A_ScreenWidth : ActWin_W
	GuiControl, 1:    , HotkeyText, %HotkeyStr%

	GuiControl, 1:Move, HotkeyText, x0 y0 w%text_w% h%GuiHeight%
	GuiControl, +0x201, HotkeyText

	if (GuiPosition = "Top")
		gui_y := ActWin_Y
	else
		gui_y := (ActWin_Y+ActWin_H) - GuiHeight - 50

	Gui, 1:Show, NoActivate x%ActWin_X% y%gui_y% h%GuiHeight% w%text_w%
}

GetKeyStr() {
	static modifiers := ["Ctrl", "Shift", "Alt", "LWin", "RWin"]
	static repeatCount := 1

	for i, mod in modifiers {
		if GetKeyState(mod)
			prefix .= mod " + "
	}

	if (!prefix && !ShowSingleKey)
		throw

	key := SubStr(A_ThisHotkey, 3)

	if (key ~= "i)^(Ctrl|Shift|Alt|LWin|RWin)$") {
		if !ShowSingleModifierKey {
			throw
		}
		key := ""
		prefix := RTrim(prefix, "+ ")

		if ShowModifierKeyCount {
			if !InStr(prefix, "+") && IsDoubleClickEx() {
				if (A_ThisHotKey != A_PriorHotKey) || ShowStickyModKeyCount {
					if (++repeatCount > 1) {
						prefix .= " ( * " repeatCount " )"
					}
				} else {
					repeatCount := 0
				}
			} else {
				repeatCount := 1
			}
		}
	} else {
		if ( StrLen(key) = 1 ) {
			key := GetKeyChar(key, "A")
		} else if ( SubStr(key, 1, 2) = "sc" ) {
			key := SpecialSC(key)
		} else if (key = "LButton") && IsDoubleClick() {
			key := "Double-Click"
		}
		_key := (key = "Double-Click") ? "LButton" : key

		static pre_prefix, pre_key, keyCount := 1
		global tickcount_start
		if (prefix && pre_prefix) && (A_TickCount-tickcount_start < 300) {
			if (prefix != pre_prefix) {
				result := pre_prefix pre_key ", " prefix key
			} else {
				keyCount := (key=pre_key) ? (keyCount+1) : 1
				key := (keyCount>2) ? (key " (" keyCount ")") : (pre_key ", " key)
			}
		} else {
			keyCount := 1
		}

		pre_prefix := prefix
		pre_key := _key

		repeatCount := 1
	}
	return result ? result : prefix . key
}

SpecialSC(sc) {
	static k := {sc046: "ScrollLock", sc145: "NumLock", sc146: "Pause", sc123: "Genius LuxeMate Scroll"}
	return k[sc]
}

; by Lexikos -- https://autohotkey.com/board/topic/110808-getkeyname-for-other-languages/#entry682236
GetKeyChar(Key, WinTitle:=0) {
	thread := WinTitle=0 ? 0
		: DllCall("GetWindowThreadProcessId", "ptr", WinExist(WinTitle), "ptr", 0)
	hkl := DllCall("GetKeyboardLayout", "uint", thread, "ptr")
	vk := GetKeyVK(Key), sc := GetKeySC(Key)
	VarSetCapacity(state, 256, 0)
	VarSetCapacity(char, 4, 0)
	n := DllCall("ToUnicodeEx", "uint", vk, "uint", sc
		, "ptr", &state, "ptr", &char, "int", 2, "uint", 0, "ptr", hkl)
	return StrGet(&char, n, "utf-16")
}

IsDoubleClick(MSec = 300) {
	Return (A_ThisHotKey = A_PriorHotKey) && (A_TimeSincePriorHotkey < MSec)
}

IsDoubleClickEx(MSec = 300) {
	preHotkey := RegExReplace(A_PriorHotkey, "i) Up$")
	Return (A_ThisHotKey = preHotkey) && (A_TimeSincePriorHotkey < MSec)
}

HideGUI() {
	Gui, Hide
}

; -------------------------------------------------------------------

ReadSettings() {
	IniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniRead, TransN               , %IniFile%, Settings, TransN               , 200
	IniRead, ShowSingleKey        , %IniFile%, Settings, ShowSingleKey        , 1
	IniRead, ShowMouseButton      , %IniFile%, Settings, ShowMouseButton      , 1
	IniRead, ShowSingleModifierKey, %IniFile%, Settings, ShowSingleModifierKey, 1
	IniRead, ShowModifierKeyCount , %IniFile%, Settings, ShowModifierKeyCount , 1
	IniRead, ShowStickyModKeyCount, %IniFile%, Settings, ShowStickyModKeyCount, 0
	IniRead, DisplayTime          , %IniFile%, Settings, DisplayTime          , 2000
	IniRead, GuiPosition          , %IniFile%, Settings, GuiPosition          , Bottom
	IniRead, FontSize             , %IniFile%, Settings, FontSize             , 50
	IniRead, GuiHeight            , %IniFile%, Settings, GuiHeight            , 115
	IniRead, BkColor              , %IniFile%, Settings, BkColor              , Black
	IniRead, FontColor            , %IniFile%, Settings, FontColor            , White
	IniRead, FontStyle            , %IniFile%, Settings, FontStyle            , w700
	IniRead, FontName             , %IniFile%, Settings, FontName             , Arial
}

SaveSettings() {
	IniFile := SubStr(A_ScriptFullPath, 1, -4) ".ini"

	IniWrite, %TransN%               , %IniFile%, Settings, TransN
	IniWrite, %ShowSingleKey%        , %IniFile%, Settings, ShowSingleKey
	IniWrite, %ShowMouseButton%      , %IniFile%, Settings, ShowMouseButton
	IniWrite, %ShowSingleModifierKey%, %IniFile%, Settings, ShowSingleModifierKey
	IniWrite, %ShowModifierKeyCount% , %IniFile%, Settings, ShowModifierKeyCount
	IniWrite, %ShowStickyModKeyCount%, %IniFile%, Settings, ShowStickyModKeyCount
	IniWrite, %DisplayTime%          , %IniFile%, Settings, DisplayTime
	IniWrite, %GuiPosition%          , %IniFile%, Settings, GuiPosition
	IniWrite, %FontSize%             , %IniFile%, Settings, FontSize
	IniWrite, %GuiHeight%            , %IniFile%, Settings, GuiHeight
	IniWrite, %BkColor%              , %IniFile%, Settings, BkColor
	IniWrite, %FontColor%            , %IniFile%, Settings, FontColor
	IniWrite, %FontStyle%            , %IniFile%, Settings, FontStyle
	IniWrite, %FontName%             , %IniFile%, Settings, FontName
}

CreateTrayMenu() {
	Menu, Tray, NoStandard
	Menu, Tray, Add, Settings, ShowSettingsGUI
	Menu, Tray, Add, About, ShowAboutGUI
	Menu, Tray, Add
	Menu, Tray, Add, Exit, _ExitApp
}

ShowAboutGUI() {
	Gui, a:Font, s12 bold
	Gui, a:Add, Text, , KeypressOSD v2.30
	Gui, a:Add, Link, gOpenUrl, <a>https://github.com/tmplinshi/KeypressOSD</a>
	Gui, a:Show,, About
	Return

	OpenUrl:
		Run, https://github.com/tmplinshi/KeypressOSD
	return
}

_ExitApp() {
	ExitApp
}

ShowSettingsGUI() {
	global

	Gui, s:Destroy
	Gui, s:+HWNDhGUI_s
	Gui, s:Font, s12
	Gui, s:Add, Text, , Transparency:
	Gui, s:Add, Text, x+10 w100 vTransNVal, %TransN%
	Gui, s:Add, Slider, xm+10 vTransN Range0-255 ToolTip gUpdateTransVal, %TransN%
	Gui, s:Add, Checkbox, xm h24 vShowSingleKey Checked%ShowSingleKey%, Show Single Key
	Gui, s:Add, Checkbox, xm h24 vShowMouseButton Checked%ShowMouseButton%, Show Mouse Button
	Gui, s:Add, Checkbox, xm h24 vShowSingleModifierKey Checked%ShowSingleModifierKey%, Show Single Modifier Key
	Gui, s:Add, Checkbox, xm h24 vShowModifierKeyCount Checked%ShowModifierKeyCount%, Show Modifier Key Count
	Gui, s:Add, Checkbox, xm h24 vShowStickyModKeyCount Checked%ShowStickyModKeyCount%, Show Sticky Modifier Key Count
	Gui, s:Add, Text, xm, Display
	Gui, s:Add, Edit, x+10 w100 Number Center vDisplayTime, %DisplayTime%
	Gui, s:Add, Text, x+10, Milliseconds
	Gui, s:Add, Text, xm, Gui Position:
	Gui, s:Add, DDL, x+10 w150 Center vGuiPosition gUpdateGuiPosition, Bottom||Top
	GuiControl, s:Choose, GuiPosition, %GuiPosition%
	Gui, s:Add, Text, xm, Font Size:
	Gui, s:Add, Edit, x+10 w100 Number Center vFontSize gUpdateFontSize, %FontSize%
	Gui, s:Add, UpDown, Range1-1000 gUpdateFontSize, %fontSize%
	Gui, s:Add, Text, xm, Gui Height:
	Gui, s:Add, Edit, x+10 w100 Number Center vGuiHeight gUpdateGuiHeight, %GuiHeight%
	Gui, s:Add, UpDown, Range5-1000 gUpdateGuiHeight, %GuiHeight%
	Gui, s:Add, Button, xm gChangeBkColor, Change Background Color
	Gui, s:Add, Button, xm gChangeFont, Change Font
	Gui, s:Add, Button, x+50 gChangeFontColor, Change Font Color

	Gui, s:Show,, Settings - KeypressOSD
	ShowHotkey("KeypressOSD")
	SetTimer, HideGUI, Off
	return

	UpdateGuiPosition:
		GuiControlGet, GuiPosition
		ShowHotkey("KeypressOSD")
	return

	UpdateGuiHeight:
		GuiControlGet, newH,, GuiHeight
		if newH {
			GuiHeight := newH
			ShowHotkey("KeypressOSD")
		}
	return

	UpdateTransVal:
		GuiControlGet, TransN
		GuiControl,, TransNVal, % TransN

		Gui, 1:+LastFound
		WinSet, Transparent, %TransN%
	return

	UpdateFontSize:
		GuiControlGet, FontSize
		Gui, 1:Font, s%FontSize%
		GuiControl, 1:Font, HotkeyText
	return

	sGuiClose:
		FontSize_pre := FontSize

		Gui, s:Submit

		ShowMouseButton ? MouseHotkey_On() : MouseHotkey_Off()

		if (FontSize_pre != FontSize) {
			Gui, 1:Font, s%FontSize%
			GuiControl, 1:Font, HotkeyText
		}

		if !GuiHeight
			GuiHeight := 115

		SaveSettings()
		Gui, s:Destroy
		Gui, 1:Hide
	return

	ChangeBkColor:
		newColor := BkColor
		if Select_Color(hGUI_s, newColor) {
			Gui, 1:Color, %newColor%
			ShowHotkey("KeypressOSD")
			SetTimer, HideGUI, Off
			BkColor := newColor
		}
	return

	ChangeFontColor:
		newColor := FontColor
		if Select_Color(hGUI_s, newColor) {
			Gui, 1:Font, c%newColor%
			GuiControl, 1:Font, HotkeyText
			ShowHotkey("KeypressOSD")
			SetTimer, HideGUI, Off
			FontColor := newColor
		}
	return

	ChangeFont:
		fStyle := FontStyle " s" FontSize
		fName  := FontName
		fColor := FontColor

		if Select_Font(hGUI_s, fStyle, fName, fColor) {
			FontStyle := fStyle
			FontName := fName
			FontColor := fColor
			if RegExMatch(FontStyle, "\bs\K\d+", FontSize) {
				FontStyle := RegExReplace(FontStyle, "\bs\K\d+")
				GuiControl,, FontSize, %FontSize%
			}

			Gui, 1:Font
			Gui, 1:Font, %fStyle% c%FontColor%, %fName%
			GuiControl, 1:Font, HotkeyText
			ShowHotkey("KeypressOSD")
			SetTimer, HideGUI, Off
		}
	return
}




; https://autohotkey.com/boards/viewtopic.php?p=112730#p112730
;-------------------------------------------------------------------------------
Select_Font(hGui, ByRef Style, ByRef Name, ByRef Color) { ; using comdlg32.dll
;-------------------------------------------------------------------------------
    static SubKey := "SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontDPI"


    ;-----------------------------------
    ; LOGFONT structure
    ;-----------------------------------
    VarSetCapacity(LOGFONT, 128, 0)

    If RegExMatch(Style, "s\K\d+", s) {
        RegRead, LogPixels, HKLM, %SubKey%, LogPixels
        NumPut(s * LogPixels // 72, LOGFONT, 0, "Int")
    }

    If RegExMatch(Style, "w\K\d+", w)
        NumPut(w, LOGFONT, 16, "Int")

    If InStr(Style, "italic")
        NumPut(255, LOGFONT, 20, "Int")

    If InStr(Style, "underline")
        NumPut(1, LOGFONT, 21, "Int")

    If InStr(Style, "strikeout")
        NumPut(1, LOGFONT, 22, "Int")

    StrPut(Name, &LOGFONT + 28, StrLen(Name) + 1)


    ;-----------------------------------
    ; CHOOSEFONT structure
    ;-----------------------------------

    ; CHOOSEFONT structure expects text color in BGR format
    BGR := convert_Color(Color)

    If (A_PtrSize = 8) { ; 64 bit
        VarSetCapacity(CHOOSEFONT, 104, 0)
        NumPut(     104, CHOOSEFONT,  0, "UInt") ; StructSize
        NumPut(    hGui, CHOOSEFONT,  8, "UInt") ; hwndOwner
        NumPut(&LOGFONT, CHOOSEFONT, 24, "UInt") ; lpLogFont
        NumPut(   0x141, CHOOSEFONT, 36, "UInt") ; Flags
        NumPut(     BGR, CHOOSEFONT, 40, "UInt") ; bgrColor
    }

    Else { ; 32 bit
        VarSetCapacity(CHOOSEFONT, 60, 0)
        NumPut(      60, CHOOSEFONT,  0, "UInt") ; StructSize
        NumPut(    hGui, CHOOSEFONT,  4, "UInt") ; hwndOwner
        NumPut(&LOGFONT, CHOOSEFONT, 12, "UInt") ; lpLogFont
        NumPut(   0x141, CHOOSEFONT, 20, "UInt") ; Flags
        NumPut(     BGR, CHOOSEFONT, 24, "UInt") ; bgrColor
    }


    ;-----------------------------------
    ; call ChooseFont function
    ;-----------------------------------
    FuncName := "comdlg32\ChooseFont" (A_IsUnicode ? "W" : "A")
    If Not DllCall(FuncName, "UInt", &CHOOSEFONT)
        Return, False


    ;-----------------------------------
    ; results to return
    ;-----------------------------------

    ; style
    Style := "s" NumGet(CHOOSEFONT, A_PtrSize = 8 ? 32 : 16, "Int") // 10
    Style .= " w" NumGet(LOGFONT, 16)
    If NumGet(LOGFONT, 20, "UChar")
        Style .= " italic"
    If NumGet(LOGFONT, 21, "UChar")
        Style .= " underline"
    If NumGet(LOGFONT, 22, "UChar")
        Style .= " strikeout"

    ; name
    Name := StrGet(&LOGFONT + 28)

    ; chosen color
    RGB := convert_Color(NumGet(CHOOSEFONT, A_PtrSize = 8 ? 40 : 24, "UInt"))
    Color := SubStr("0x00000", 1, 10 - StrLen(RGB)) SubStr(RGB, 3)
    Return, True
}



;-------------------------------------------------------------------------------
Select_Color(hGui, ByRef Color) { ; using comdlg32.dll
;-------------------------------------------------------------------------------

    ; CHOOSECOLOR structure expects text color in BGR format
    BGR := convert_Color(Color)

    ; unused, but a valid pointer to the structure
    VarSetCapacity(CUSTOM, 64, 0)


    ;-----------------------------------
    ; CHOOSECOLOR structure
    ;-----------------------------------

    If (A_PtrSize = 8) { ; 64 bit
        VarSetCapacity(CHOOSECOLOR, 72, 0)
        NumPut(     72, CHOOSECOLOR,  0) ; StructSize
        NumPut(   hGui, CHOOSECOLOR,  8) ; hwndOwner
        NumPut(    BGR, CHOOSECOLOR, 24) ; bgrColor
        NumPut(&CUSTOM, CHOOSECOLOR, 32) ; lpCustColors
        NumPut(  0x103, CHOOSECOLOR, 40) ; Flags
    }

    Else { ; 32 bit
        VarSetCapacity(CHOOSECOLOR, 36, 0)
        NumPut(     36, CHOOSECOLOR,  0) ; StructSize
        NumPut(   hGui, CHOOSECOLOR,  4) ; hwndOwner
        NumPut(    BGR, CHOOSECOLOR, 12) ; bgrColor
        NumPut(&CUSTOM, CHOOSECOLOR, 16) ; lpCustColors
        NumPut(  0x103, CHOOSECOLOR, 20) ; Flags
    }


    ;-----------------------------------
    ; call ChooseColorA function
    ;-----------------------------------

    If Not DllCall("comdlg32\ChooseColorA", "UInt", &CHOOSECOLOR)
        Return, False


    ;-----------------------------------
    ; result to return
    ;-----------------------------------

    ; chosen color
    RGB := convert_Color(NumGet(CHOOSECOLOR, A_PtrSize = 8 ? 24 : 12, "UInt"))
    Color := SubStr("0x00000", 1, 10 - StrLen(RGB)) SubStr(RGB, 3)
    Return, True
}



;-------------------------------------------------------------------------------
convert_Color(Color) { ; convert RGB <--> BGR
;-------------------------------------------------------------------------------
    $_FormatInteger := A_FormatInteger
    SetFormat, Integer, Hex
    Result := (Color & 0xFF) << 16 | Color & 0xFF00 | (Color >> 16) & 0xFF
    SetFormat, Integer, % $_FormatInteger
    Return, Result
}
