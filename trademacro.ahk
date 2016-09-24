; https://github.com/thirdy/trademacro
; based on Pete's Price Macro https://github.com/trackpete/exiletools-price-macro/blob/master/poe_price_macro.ahk
; as well as POE Item Info https://github.com/aRTy42/POE-ItemInfo

; Trade Macro
; Version: 0.1 (2016/09/23)
; Tested with AutoHotkey112401_Install, Unicode 64-bit
; Windows 7
;
; Written by /u/ProFalseIdol on reddit, ManicCompression in game
;
; CONFIGURATION NOTE: You must configure the LeagueName properly. Otherwise it will default to
; "Standard" - press ^F and search for LeagueName and you will find where to set it.
;
; USAGE NOTE: This requires your Path of Exile to be in Windowed (or Windowed Full Screen) 
; to work properly, otherwise the popup will just show in the background and you won't
; see it. Also, you *must* use the AHK from http://ahkscript.org NOT NOT autohotkey.com!
;
; WINDOWS 10 NOTE: You may need to run this .ahk file as an Administrator in order for the popups
; to show properly.
;
; AUTHOR'S NOTE: I'm not an AHK programmer, I learned everything on by Google only. Certainly this code will look sloppy to experienced AHK programmers, if you have any
; advice or would like to re-write it, please feel free and let me know. 
;
; ===================================================
; Change Log
; 0.1 (2016/09/23): Re-write to use pure AHK, previous version used Java, project called "longan"
;

; == Startup Options ===========================================
#SingleInstance force
#NoEnv 
#Persistent ; Stay open in background
SendMode Input 
StringCaseSense, On ; Match strings with case.
Menu, tray, Tip, Trade Macro

If (A_AhkVersion <= "1.1.22")
{
    msgbox, You need AutoHotkey v1.1.22 or later to run this script. `n`nPlease go to http://ahkscript.org/download and download a recent version.
    exit
}

; Windows system tray icon
IfExist, %A_ScriptDir%\icon.ico
    Menu, Tray, Icon, %A_ScriptDir%\icon.ico
else
{
    UrlDownloadToFile, https://raw.githubusercontent.com/thirdy/trademacro/master/icon.ico, %A_ScriptDir%\icon.ico
    Menu, Tray, Icon, %A_ScriptDir%\icon.ico
}

; == Variables and Options and Stuff ===========================

; *******************************************************************
; *******************************************************************
;                      SET LEAGUENAME BELOW!!
; *******************************************************************
; *******************************************************************
; Option for LeagueName - this must be specified.
; Remove the ; from in front of the line that has the leaguename you
; want, or just change the uncommented line to say what you want.
; Make sure all other LeagueName lines have a ; in front of them (commented)
; or are removed

global LeagueName := "Essence"
;global LeagueName := "Hardcore Essence"
;global LeagueName := "Standard"
;global LeagueName := "Hardcore"

; How much the mouse needs to move before the hotkey goes away, not a big deal, change to whatever
MouseMoveThreshold := 40
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

; There are multiple hotkeys to run this script now, defaults set as follows:
; ^p (CTRL-p) - Sends the item information to my server, where a price check is performed. Levels and quality will be automatically processed.
; ^i (CTRL-i) - Pulls up an interactive search box that goes away after 30s or when you hit enter/ok
;
; To modify these, you will need to modify the function call headers below
; see http://www.autohotkey.com/docs/Hotkeys.htm for hotkey options

; Price check w/ auto filters
^p::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
  FunctionReadItemFromClipboard()
}
return

; Custom Input String Search
^i::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{   
  Global X
  Global Y
  MouseGetPos, X, Y	
  InputBox,ItemName,Price Check,Item Name,,250,100,X-160,Y - 250,,30,
  if ItemName {
	PostData := "league=" . LeagueName . "&type=&base=&name=" . ItemName . "&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&q_min=&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=&online=x&buyout=x&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
    
    FunctionPostItemData(PostData)
  }
}
return

; == Function Stuff =======================================

FunctionPostItemData(Payload)
{  
  temporaryContent = Submitting...
  FunctionShowToolTipPriceInfo(temporaryContent)
  
  ; Send the PostData and parse the response
  html := FunctionDoPostRequest(Payload)
  result := FunctionParseHtml(html, Payload)
  
  ;FileDelete, result.txt
  ;FileAppend, %result%, result.txt
  FunctionShowToolTipPriceInfo(result)    
}

; This is for the tooltip, so it shows it and starts a timer that watches mouse movement.
; I imagine there's a better way of doing this. The crazy long name is to avoid
; overlap with other scripts in case people try to combine these into one big script.

FunctionShowToolTipPriceInfo(responsecontent)
{
    ; Get position of mouse cursor
    Sleep, 2
	Global X
    Global Y
    MouseGetPos, X, Y	
	gui, font, s15, Lucida Console
    ToolTip, %responsecontent%, X - 135, Y + 30
    SetTimer, SubWatchCursorPrice, 100     

}

; == The Goods =====================================

; Watches the mouse cursor to get rid of the tooltip after too much movement
SubWatchCursorPrice:
  MouseGetPos, CurrX, CurrY
  MouseMoved := (CurrX - X)**2 + (CurrY - Y)**2 > MouseMoveThreshold**2
  If (MouseMoved)
  {
    SetTimer, SubWatchCursorPrice, Off
    ToolTip
  }
return


FunctionReadItemFromClipboard() {
  ; Only does anything if POE is the window with focus
  IfWinActive, Path of Exile ahk_class Direct3DWindowClass
  {
    ; Send a ^C to copy the item information to the clipboard
	; Note: This will trigger any Item Info/etc. script that monitors the clipboard
    Send ^c
    ; Wait 250ms - without this the item information doesn't get to the clipboard in time
    Sleep 250
	; Get what's on the clipboard
    ClipBoardData = %clipboard%
    ; Split the clipboard data into strings to make sure it looks like a properly
	; formatted item, looking for the Rarity: tag in the first line. Just in case
	; something weird got copied to the clipboard.
	StringSplit, data, ClipBoardData, `n, `r
		
	; Strip out extra CR chars
	StringReplace RawItemData, ClipBoardData, `r, , A

	;Makes it work when someone else links an item
	SecLine = %data2%
	Control = <<set:MS>><<set:M>><<set:S>>
	IfInString, SecLine, %Control%
	{
	StringTrimLeft, data2, data2, 28
	}
	ItemName = %data2%
	
	; If the first line on the clipboard has Rarity: it is probably some item
	; information from POE, so we'll send it to my server to process. Otherwise
	; we just don't do anything at all.
    IfInString, data1, Rarity:
    {
        ; TODO, write a better code for all this
        
        ItemName := data2 . " " . data3
        IfInString, data3, ---
        {
            ItemName := data2
        }
        ;MsgBox % ItemName
        
        QualityParam := "q_min="
        IfInString, data1, Rarity: Gem
        {
            IfInString, RawItemData, Quality: 
            {
                QualityParam .= StrX(RawItemData, "Quality: +", 1,10, "%",1,1 )
            }
        }
    
        Payload := "league=" . LeagueName . "&type=&base=&name=" . ItemName . "&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&" . QualityParam . "&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=&online=x&buyout=x&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
         
	  FunctionPostItemData(Payload)
	} 	
  }  
}

StrPutVar(Str, ByRef Var, Enc = "")
{
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}

FunctionDoPostRequest(payload)
{
	;FileDelete, payload.txt
    ;FileAppend, %payload%, payload.txt
    
    ; TODO: split this function, HTTP POST and Html parsing should be separate
    ; Reference in making POST requests - http://stackoverflow.com/questions/158633/how-can-i-send-an-http-post-request-to-a-server-from-excel-using-vba
    HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    ;HttpObj := ComObjCreate("MSXML2.ServerXMLHTTP") 
    ; We use this instead of WinHTTP to support gzip and deflate - http://microsoft.public.winhttp.narkive.com/NDkh5vEw/get-request-for-xml-gzip-file-winhttp-wont-uncompress-automagically
    HttpObj.Open("POST","http://poe.trade/search")
    HttpObj.SetRequestHeader("Host","poe.trade")
    HttpObj.SetRequestHeader("Connection","keep-alive")
    HttpObj.SetRequestHeader("Content-Length",StrLen(payload))
    HttpObj.SetRequestHeader("Cache-Control","max-age=0")
    HttpObj.SetRequestHeader("Origin","http://poe.trade")
    HttpObj.SetRequestHeader("Upgrade-Insecure-Requests","1")
    HttpObj.SetRequestHeader("User-Agent","Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36")
    HttpObj.SetRequestHeader("Content-type","application/x-www-form-urlencoded")
    HttpObj.SetRequestHeader("Accept","text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8")
    HttpObj.SetRequestHeader("Referer","http://poe.trade/")
    HttpObj.SetRequestHeader("Accept-Encoding","gzip;q=0,deflate;q=0") ; disables compression
    ;HttpObj.SetRequestHeader("Accept-Encoding","gzip, deflate")
    HttpObj.SetRequestHeader("Accept-Language","en-US,en;q=0.8")

    HttpObj.Send(payload)
    HttpObj.WaitForResponse()

    ;MsgBox % HttpObj.StatusText . HttpObj.GetAllResponseHeaders()
    ;MsgBox % HttpObj.ResponseText
    ; Dear GGG, it would be nice if you can provide an API like http://pathofexile.com/trade/search?name=Veil+of+the+night&links=4
    ; Pete's indexer is open sourced here - https://github.com/trackpete/exiletools-indexer you can use this to provide this api
    html := HttpObj.ResponseText
    ;FileRead, html, Test1.txt
    ;FileDelete, html.htm
    ;FileAppend, %html%, html.htm
    
    Return, html
}

FunctionParseHtml(html, payload)
{
    ; Target HTML Looks like the ff:
    ;<tbody id="item-container-97" class="item" data-seller="Jobo" data-sellerid="458008" data-buyout="15 chaos" data-ign="Lolipop_Slave" data-league="Essence" data-name="Tabula Rasa Simple Robe" data-tab="This is a buff" data-x="10" data-y="9"> <tr class="first-line">
    ; TODO: grab more data like corruption found inside <tbody>
    
    ItemName := StrX( payload,  "&name=",  1,6, "&",1,1 )
    StringReplace, ItemName, ItemName, +, %A_SPACE%, All
    Quality  := StrX( payload,  "&q_min=", 1,7, "&",1,1 )
    
    ; TODO Refactor this
    IfInString, Quality, q_max
    {
        Quality = 
    }
    Text := ItemName " " Quality "`n ---------- `n"

    ; Text .= StrX( html,  "<tbody id=""item-container-0",          N,0, "<tr class=""first-line"">",1,28, N )

    NoOfItemsToShow = 15
    While A_Index < NoOfItemsToShow
          Item        := StrX( html,  "<tbody id=""item-container-" . %A_Index%,  N,0,  "<tr class=""first-line"">", 1,23, N )
        , AccountName := StrX( Item,  "data-seller=""",                           1,13, """"  ,                      1,1,  T )
        , Buyout      := StrX( Item,  "data-buyout=""",                           T,13, """"  ,                      1,1,  T )
        , IGN         := StrX( Item,  "data-ign=""",                              T,10, """"  ,                      1,1     )
        ;, Text .= StrPad(IGN, 30) StrPad(AccountName, 30) StrPad(Buyout,30) "`n"
        , Text .= StrPad(IGN,20) StrPad(Buyout,20,"left") "`n"
    
    Return, Text
}

; Taken from Poe-Item-Info
; Pads a string with a multiple of PadChar to become a wanted total length.
; Note that Side is the side that is padded not the anchored side.
; Meaning, if you pad right side, the text will move left. If Side was an 
; anchor instead, the text would move right if anchored right.
StrPad(String, Length, Side="right", PadChar=" ")
{
    StringLen, Len, String
    AddLen := Length-Len
    If (AddLen <= 0)
    {
        return String
    }
    Pad := StrMult(PadChar, AddLen)
    If (Side == "right")
    {
        Result := String . Pad
    }
    Else
    {
        Result := Pad . String
    }
    return Result
}
StrMult(Char, Times)
{
    Result =
    Loop, %Times%
    {
        Result := Result . Char
    }
    return Result
}

; ------------------------------------------------------------------------------------------------------------------ ;
; StrX function for parsing html, see simple example usage at https://gist.github.com/thirdy/9cac93ec7fd947971721c7bdde079f94
; ------------------------------------------------------------------------------------------------------------------ ;

; Cleanup StrX function and Google Example from https://autohotkey.com/board/topic/47368-strx-auto-parser-for-xml-html
; By SKAN

;1 ) H = HayStack. The "Source Text"
;2 ) BS = BeginStr. Pass a String that will result at the left extreme of Resultant String
;3 ) BO = BeginOffset. 
; Number of Characters to omit from the left extreme of "Source Text" while searching for BeginStr
; Pass a 0 to search in reverse ( from right-to-left ) in "Source Text"
; If you intend to call StrX() from a Loop, pass the same variable used as 8th Parameter, which will simplify the parsing process.
;4 ) BT = BeginTrim. 
; Number of characters to trim on the left extreme of Resultant String
; Pass the String length of BeginStr if you want to omit it from Resultant String
; Pass a Negative value if you want to expand the left extreme of Resultant String
;5 ) ES = EndStr. Pass a String that will result at the right extreme of Resultant String
;6 ) EO = EndOffset. 
; Can be only True or False. 
; If False, EndStr will be searched from the end of Source Text. 
; If True, search will be conducted from the search result offset of BeginStr or from offset 1 whichever is applicable.
;7 ) ET = EndTrim. 
; Number of characters to trim on the right extreme of Resultant String
; Pass the String length of EndStr if you want to omit it from Resultant String
; Pass a Negative value if you want to expand the right extreme of Resultant String
;8 ) NextOffset : A name of ByRef Variable that will be updated by StrX() with the current offset, You may pass the same variable as Parameter 3, to simplify data parsing in a loop

StrX(H,  BS="",BO=0,BT=1,   ES="",EO=0,ET=1,  ByRef N="" ) 
{ 
        Return SubStr(H,P:=(((Z:=StrLen(ES))+(X:=StrLen(H))+StrLen(BS)-Z-X)?((T:=InStr(H,BS,0,((BO
            <0)?(1):(BO))))?(T+BT):(X+1)):(1)),(N:=P+((Z)?((T:=InStr(H,ES,0,((EO)?(P+1):(0))))?(T-P+Z
            +(0-ET)):(X+P)):(X)))-P)
}
; v1.0-196c 21-Nov-2009 www.autohotkey.com/forum/topic51354.html
; | by Skan | 19-Nov-2009

; From https://redd.it/53ml1x
;*RButton::Send {shift Down}{RButton down}
;*RButton Up::Send {shift Up}{RButton up}

F9::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f9()
}
return

^F9::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f9(true)
}
return

f9(reset = false) {
    static LineNumber = 3
    if (reset) 
        LineNumber = 3
        
    Payload := "league=" . LeagueName . "&type=Gem&base=&name=Added+Chaos+Damage&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&q_min=&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=&online=x&buyout=x&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
    
    filename := "f9-result.txt"
    FunctionDoMacroSearch(Payload, LineNumber, filename, reset)
    LineNumber += 1
}

F10::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f10()
}
return

^F10::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f10(true)
}
return

f10(reset = false) {
    static LineNumber = 3
    if (reset) 
        LineNumber = 3
        
    Payload := "league=" . LeagueName . "&type=Jewel&base=&name=&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=%23%25+increased+maximum+Life&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&mod_name=%28pseudo%29+%28total%29+%2B%23%25+to+Cold+Resistance&mod_min=&mod_max=&mod_name=%28pseudo%29+%28total%29+%2B%23%25+to+Lightning+Resistance&mod_min=&mod_max=&mod_name=%28pseudo%29+%28total%29+%2B%23%25+to+Fire+Resistance&mod_min=&mod_max=&group_type=Count&group_min=2&group_max=&group_count=3&q_min=&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=&online=x&buyout=x&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
    
    filename := "f10-result.txt"
    FunctionDoMacroSearch(Payload, LineNumber, filename, reset)
    LineNumber += 1
}

F11::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f11()
}
return

^F11::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f11(true)
}
return

f11(reset = false) {
    static LineNumber = 3
    if (reset) 
        LineNumber = 3
        
    Payload := "league=" . LeagueName . "&type=&base=&name=Tabula+Rasa+Simple+Robe&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&q_min=&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=0&online=x&buyout=x&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
    
    filename := "f11-result.txt"
    FunctionDoMacroSearch(Payload, LineNumber, filename, reset)
    LineNumber += 1
}

F12::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f12()
}
return

^F12::
IfWinActive, Path of Exile ahk_class Direct3DWindowClass 
{
    f12(true)
}
return

f12(reset = false) {
    static ItemName = "Lifesprig Driftwood Wand"
    static LineNumber = 3
    if (reset) {
        LineNumber = 3
        InputBox,ItemName,Search By Item Name,Item Name,,250,100,X-160,Y - 250,,30,
    }   
        
    Payload := "league=" . LeagueName . "&type=&base=&name=" . ItemName . "&dmg_min=&dmg_max=&aps_min=&aps_max=&crit_min=&crit_max=&dps_min=&dps_max=&edps_min=&edps_max=&pdps_min=&pdps_max=&armour_min=&armour_max=&evasion_min=&evasion_max=&shield_min=&shield_max=&block_min=&block_max=&sockets_min=&sockets_max=&link_min=&link_max=&sockets_r=&sockets_g=&sockets_b=&sockets_w=&linked_r=&linked_g=&linked_b=&linked_w=&rlevel_min=&rlevel_max=&rstr_min=&rstr_max=&rdex_min=&rdex_max=&rint_min=&rint_max=&mod_name=&mod_min=&mod_max=&group_type=And&group_min=&group_max=&group_count=1&q_min=&q_max=&level_min=&level_max=&ilvl_min=&ilvl_max=&rarity=&seller=&thread=&identified=&corrupted=&online=x&buyout=x&altart=&capquality=x&buyout_min=&buyout_max=&buyout_currency=&crafted=&enchanted="
    
    filename := "f12-result.txt"
    FunctionDoMacroSearch(Payload, LineNumber, filename, reset)
    LineNumber += 1
}

FunctionDoMacroSearch(Payload, LineNumber, filename, reset)
{   
    if (reset)
        FunctionDoFreshMacroSearch(Payload, filename)
    
    IfNotExist, %A_ScriptDir%\%filename%
        FunctionDoFreshMacroSearch(Payload, filename)
    
    FileReadLine, line, %A_ScriptDir%\%filename%, %LineNumber%
    FileReadLine, itemName, %A_ScriptDir%\%filename%, 1
    
    if (!line)
        result := "No more items found in " filename
    else {
        result := FunctionToWTB(itemName, line)
        clipboard = %result%
    }
    
    FunctionShowToolTipPriceInfo(result)
    
}

FunctionDoFreshMacroSearch(Payload, filename)
{
    FunctionShowToolTipPriceInfo("Running search...")
    html := FunctionDoPostRequest(Payload)
    result := FunctionParseHtml(html, Payload)
    FileDelete, %filename%
    FileAppend, %result%, %filename%
}

FunctionToWTB(itemName, line)
{
    RegExMatch(line, "([^\s]+)\s+(.+)", SubPat)
    ign    := SubPat1
    buyout := SubPat2
    msg    := "@" ign " I would like to buy your " itemName " listed for " buyout " in " LeagueName
    Return msg
}
