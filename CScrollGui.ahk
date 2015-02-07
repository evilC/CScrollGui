#include <_Struct>
#include <WinStructs>
; ======================================================================================================================
; Namepace:       ScrollGUI
; Function:       Create a scrollable GUI as a parent for GUI windows.
; Tested with:    AHK 1.1.19.02
; Tested on:      Win 8.1 (x64)
; Change log:     1.0.00.00/2015-02-06/just me        -  initial release on ahkscript.org
; License:        The Unlicense -> http://unlicense.org
; ======================================================================================================================
Class ScrollGUI {
   Static Instances := []
   ; ===================================================================================================================
   ; __New          Creates a scrollable parent window (ScrollGUI) for the passed GUI.
   ; Parameters:
   ;    HGUI        -  HWND of the GUI child window.
   ;    Width       -  Width of the client area of the ScrollGUI.
   ;                   Pass 0 to set the client area to the width of the child GUI.
   ;    Height      -  Height of the client area of the ScrollGUI.
   ;                   Pass 0 to set the client area to the height of the child GUI.
   ;    ----------- Optional:
   ;    GuiOptions  -  GUI options to be used when creating the ScrollGUI (e.g. +LabelMyLabel).
   ;                   Default: empty (no options)
   ;    ScrollBars  -  Scroll bars to register:
   ;                   1 : horizontal
   ;                   2 : vertical
   ;                   3 : both
   ;                   Default: 3
   ;    Wheel       -  Register WM_MOUSEWHEEL / WM_MOUSEHWHEEL messages:
   ;                   1 : horizontal
   ;                   2 : vertical
   ;                   3 : both
   ;                   Default: 0
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; Remarks:
   ;    The rect of the child GUI is determined using the 'AutoSize' option of the 'Gui, Show' command, after
   ;    '-Caption' is applied to the child GUI.
   ;    The maximum width and height of the parent GUI will be restricted to the dimensions of the child GUI.
   ;    If you register mouse wheel messages, the messages will be captured solely to scroll the ScrollGUI.
   ;    You won't be able to use the wheel to scroll child GUI controls.
   ; ===================================================================================================================
   __New(HGUI, Width, Height, GuiOptions := "", ScrollBars := 3, Wheel := 0) {
      Static SB_HORZ := 0, SB_VERT = 1
      Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
      Static WM_MOUSEWHEEL := 0x020A, WM_MOUSEHWHEEL := 0x020E
      Static WS_HSCROLL := "0x100000", WS_VSCROLL := "0x200000"
      If ((ScrollBars <> 1) && (ScrollBars <> 2) && (ScrollBars <> 3))
      || ((Wheel <> 0) && (Wheel <> 1) && (Wheel <> 2) && (Wheel <> 3))
         Return False
      If !DllCall("User32.dll\IsWindow", "Ptr", HGUI, "UInt")
         Return False
      ; Child GUI
      Gui, %HGUI%:-Caption
      Gui, %HGUI%:Show, AutoSize Hide
      Rect := new _Struct(WinStructs.RECT)
      VarSetCapacity(RC, 16, 0)
      /*
      DllCall("User32.dll\GetWindowRect", "Ptr", HGUI, "Ptr", &RC)
      MaxH := NumGet(RC, 8, "Int") - NumGet(RC, 0, "Int")
      MaxV := Numget(RC, 12, "Int") - NumGet(RC, 4, "Int")
      */
      RECT := new _Struct(WinStructs.RECT)
      DllCall("User32.dll\GetWindowRect", "Ptr", HGUI, "Ptr", RECT[])
      MaxH := RECT.Right - RECT.Left
      MaxV := RECT.Bottom - RECT.Top
      
      LineH := Ceil(MaxH / 20)
      LineV := Ceil(MaxV / 20)
      ; ScrollGUI
      If (Width = 0)
         Width := MaxH
      If (Height = 0)
         Height := MaxV
      MX := MY := Styles := ""
      If (ScrollBars & 1) {
         MX := MaxH + 1
         Styles .= " +" . WS_HSCROLL
      }
      If (ScrollBars & 2) {
         Styles .= " +" . WS_VSCROLL
         MY := MaxV + 1
      }
      Gui, New, %GuiOptions% %Styles% +hwndHWND
      If (MX <> "") || (MY <> "")
         Gui, %HWND%:+MaxSize%MX%x%MY%
      Gui, %HWND%:Show, w%Width% h%Height% Hide
      /*
      DllCall("User32.dll\GetClientRect", "Ptr", HWND, "Ptr", &RC)
      PageH := NumGet(RC, 8, "Int")
      PageV := Numget(RC, 12, "Int")
      */
      DllCall("User32.dll\GetClientRect", "Ptr", HWND, "Ptr", RECT[])
      PageH := RECT.Right
      PageV := RECT.Bottom
      ; Instance variables
      This.HWND := HWND
      This.HGUI := HGUI
      This.Width := Width
      This.Height := Height
      If (ScrollBars & 1) {
         This.SetScrollInfo(SB_HORZ, {Max: MaxH, Page: PageH, Pos: 0})
         OnMessage(WM_HSCROLL, "ScrollGUI.On_WM_Scroll")
         If (Wheel & 1)
            OnMessage(WM_MOUSEHWHEEL, "ScrollGUI.On_WM_Wheel")
         This.MaxH := MaxH
         This.LineH := LineH
         This.PageH := PageH
         This.PosH := 0
         This.ScrollH := True
         If (Wheel)
            This.WheelH := True
      }
      If (ScrollBars & 2) {
         This.SetScrollInfo(SB_VERT, {Max: MaxV, Page: PageV, Pos: 0})
         OnMessage(WM_VSCROLL, "ScrollGUI.On_WM_Scroll")
         If (Wheel & 2)
            OnMessage(WM_MOUSEWHEEL, "ScrollGUI.On_WM_Wheel")
         This.MaxV := MaxV
         This.LineV := LineV
         This.PageV := PageV
         This.PosV := 0
         This.ScrollV := True
         If (Wheel)
            This.WheelV := True
      }
      ; Set the position of the child GUI
      Gui, %HGUI%:+parent%HWND%
      Gui, %HGUI%:Show, x0 y0
      This.Instances[HWND] := &This
   }
   ; ===================================================================================================================
   ; __Delete       Destroy the GUIs, if they still exist.
   ; ===================================================================================================================
   __Delete() {
      This.Destroy()
   }
   ; ===================================================================================================================
   ; Show           Shows the ScrollGUI.
   ; Parameters:
   ;    Title       -  Title of the ScrollGUI window
   ;    ShowOptions -  Gui, Show command options, width or height options are ignored
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; ===================================================================================================================
   Show(Title := "", ShowOptions := "") {
      ShowOptions := RegExReplace(ShowOptions, "i)AutoSize")
      W := This.Width
      H := This.Height
      Gui, % This.HWND . ":Show", %ShowOptions% w%W% h%H%, %Title%
      Return True
   }
   ; ===================================================================================================================
   ; Destroy        Destroys the ScrollGUI and the associated child GUI.
   ; Parameters:
   ;    None.
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; Remarks:
   ;    Use this method instead of 'Gui, Destroy' to remove the ScrollGUI from the 'Instances' object.
   ; ===================================================================================================================
   Destroy() {
      If This.Instances.HasKey(This.HWND) {
         Gui, % This.HWND . ":Destroy"
         This.Instances.Remove(This.HWND, "")
         Return True
      }
   }
   ; ===================================================================================================================
   ; AdjustToParent Adjust the scroll bars to the new parent dimensions.
   ; Parameters:
   ;    Width       -  New width of the client area of the ScrollGUI in pixels.
   ;                   Default: 0 -> current width
   ;    Height      -  New height of the client area of the ScrollGUI in pixels.
   ;                   Default: 0 -> current height
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; Remarks:
   ;    Call this method whenever the dimensions of the parent GUI have changed, e.g. after the GUI was resized,
   ;    restored or maximized. If either Width or Height is zero, both values will be set to the current dimensions.
   ; ===================================================================================================================
   AdjustToParent(Width := 0, Height := 0) {
      If (Width = 0) || (Height = 0) {
         VarSetCapacity(RC, 16, 0)
         
         RECT := new _Struct(WinStructs.RECT)
         /*
         DllCall("User32.dll\GetClientRect", "Ptr", This.HWND, "Ptr", &RC)
         Width := NumGet(RC, 8, "Int")
         Height := Numget(RC, 12, "Int")
         */
         DllCall("User32.dll\GetClientRect", "Ptr", This.HWND, "Ptr", RECT[])
         Width := NumGet(RC, 8, "Int")
         Height := Numget(RC, 12, "Int")
         Width := RECT.Right
         Height := RECT.Bottom
      }
      SH := SV := 0
      If This.ScrollH {
         If (Width <> This.Width) {
            This.SetScrollInfo(0, {Page: Width})
            This.Width := Width
            This.GetScrollInfo(0, SI)
            PosH := NumGet(SI, 20, "Int")
            SH := This.PosH - PosH
            This.PosH := PosH
         }
      }
      If This.ScrollV {
         If (Height <> This.Height) {
            This.SetScrollInfo(1, {Page: Height})
            This.Height := Height
            This.GetScrollInfo(1, SI)
            PosV := NumGet(SI, 20, "Int")
            SV := This.PosV - PosV
            This.PosV := PosV
         }
      }
      If (SH) || (SV)
         DllCall("User32.dll\ScrollWindow", "Ptr", This.HWND, "Int", SH, "Int", SV, "Ptr", 0, "Ptr", 0)
      Return True
   }
   ; ===================================================================================================================
   ; AdjustToChild  Adjust the scroll bars to the new child dimensions.
   ; Parameters:
   ;    None.
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; Remarks:
   ;    Call this method whenever the visible area of the child GUI has to be changed, e.g. after adding, hiding,
   ;    unhiding, resizing, or repositioning controls.
   ;    The client area of the child GUI is determined using the 'AutoSize' option of a 'Gui, Show' command.
   ; ===================================================================================================================
   AdjustToChild() {
      Static WS_HSCROLL := 0x100000, WS_VSCROLL := 0x200000
      VarSetCapacity(RC, 16, 0)
      DllCall("User32.dll\GetWindowRect", "Ptr", This.HGUI, "Ptr", &RC)
      DllCall("User32.dll\ScreenToClient", "Ptr", This.HWND, "Ptr", &RC)
      MX := MY := ""
      XC := XN := NumGet(RC, 0, "Int")
      YC := YN := NumGet(RC, 4, "Int")
      Gui, % This.HGUI . ":Show", x%XC% y%YC% AutoSize
      DllCall("User32.dll\GetWindowRect", "Ptr", This.HGUI, "Ptr", &RC)
      MaxH := NumGet(RC, 8, "Int") - NumGet(RC, 0, "Int")
      MaxV := Numget(RC, 12, "Int") - NumGet(RC, 4, "Int")
      LineH := Ceil(MaxH / 20)
      LineV := Ceil(MaxV / 20)
      If This.ScrollH {
         MX := MaxH + 1
         This.SetMax(1, MaxH)
         This.LineH := LineH
         If (XC + MaxH) < This.Width {
            XN += This.Width - (XC + MaxH)
            If (XN > 0)
               XN := 0
            This.SetScrollInfo(0, {Pos: XN * -1})
         }
      }
      If This.ScrollV {
         MY := MaxV + 1
         This.SetMax(2, MaxV)
         This.LineV := LineV
         If (YC + MaxV) < This.Height {
            YN += This.Height - (YC + MaxV)
            If (YN > 0)
               YN := 0
            This.SetScrollInfo(1, {Pos: YN * -1})
         }
      }
      If (MX <> "") || (MY <> "")
         Gui, % This.HWND . ":+MaxSize" . MX . "x" . MY
      If (XC <> XN) || (YC <> YN)
         DllCall("User32.dll\ScrollWindow", "Ptr", This.HWND, "Int", XN - XC, "Int", YN - YC, "Ptr", 0, "Ptr", 0)
      Return True
   }
   ; ===================================================================================================================
   ; SetMax         Sets the width or height of the scrolling area.
   ; Parameters:
   ;    SB          -  Scroll bar to set the value for:
   ;                   1 = horizontal
   ;                   2 = vertical
   ;    Max         -  Width respectively height of the scrolling area in pixels
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; ===================================================================================================================
   SetMax(SB, Max) {
      Static SB_HORZ := 0, SB_VERT = 1
      SB--
      If (SB <> SB_HORZ) && (SB <> SB_VERT)
         Return False
      If (SB = SB_HORZ)
         This.MaxH := Max
      Else
         This.MaxV := Max
      Return This.SetScrollInfo(SB, {Max: Max})
   }
   ; ===================================================================================================================
   ; SetLine        Sets the number of pixels to scroll by line.
   ; Parameters:
   ;    SB          -  Scroll bar to set the value for:
   ;                   1 = horizontal
   ;                   2 = vertical
   ;    Line        -  Number of pixels.
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; ===================================================================================================================
   SetLine(SB, Line) {
      Static SB_HORZ := 0, SB_VERT = 1
      SB--
      If (SB <> SB_HORZ) && (SB <> SB_VERT)
         Return False
      If (SB = SB_HORZ)
         This.LineH := Line
      Else
         This.LineV := Line
      Return True
   }
   ; ===================================================================================================================
   ; SetPage        Sets the number of pixels to scroll by page.
   ; Parameters:
   ;    SB          -  Scroll bar to set the value for:
   ;                   1 = horizontal
   ;                   2 = vertical
   ;    Page        -  Number of pixels.
   ; Return values:
   ;    On success: True
   ;    On failure: False
   ; Remarks:
   ;    If the ScrollGUI is resizable, the page size will be recalculated automatically while resizing.
   ; ===================================================================================================================
   SetPage(SB, Page) {
      Static SB_HORZ := 0, SB_VERT = 1
      SB--
      If (SB <> SB_HORZ) && (SB <> SB_VERT)
         Return False
      If (SB = SB_HORZ)
         This.PageH := Page
      Else
         This.PageV := Page
      Return This.SetScrollInfo(SB, {Page: Page})
   }
   ; ===================================================================================================================
   ; Methods for internal or system use!!!
   ; ===================================================================================================================
   GetScrollInfo(SB, ByRef SI) {
      Static SI_SIZE := 28
      Static SIF_ALL := 0x17
      VarSetCapacity(SI, SI_SIZE, 0)
      NumPut(SI_SIZE, SI, 0, "UInt")
      NumPut(SIF_ALL, SI, 4, "UInt")
      Return DllCall("User32.dll\GetScrollInfo", "Ptr", This.HWND, "Int", SB, "Ptr", &SI, "UInt")
   }
   ; ===================================================================================================================
   SetScrollInfo(SB, Values) {
      Static SI_SIZE := 28
      Static SIF := {Max: 0x01, Page: 0x02, Pos: 0x04}
      Static Off := {Max: 12, Page: 16, Pos: 20}
      Static SIF_DISABLENOSCROLL := 0x08
      Mask := 0
      VarSetCapacity(SI, SI_SIZE, 0)
      NumPut(SI_SIZE, SI, 0, "UInt")
      For Key, Value In Values {
         If SIF.HasKey(Key) {
            Mask |= SIF[Key]
            NumPut(Value, SI, Off[Key], "UInt")
         }
      }
      If (Mask) {
         NumPut(Mask | SIF_DISABLENOSCROLL, SI, 4, "UInt")
         Return DllCall("User32.dll\SetScrollInfo", "Ptr", This.HWND, "Int", SB, "Ptr", &SI, "UInt", 1, "UInt")
      }
      Return False
   }
   ; ===================================================================================================================
   On_WM_Scroll(LP, Msg, HWND) {
      Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
      If ScrollGUI.Instances.HasKey(HWND) {
         Instance := Object(ScrollGUI.Instances[HWND])
         If ((Msg = WM_HSCROLL) && Instance.ScrollH)
         || ((Msg = WM_VSCROLL) && Instance.ScrollV)
            Return Instance.Scroll(This, LP, Msg, HWND)
      }
   }
   ; ===================================================================================================================
   Scroll(WP, LP, Msg, HWND) {
      Static SB_LINEMINUS := 0, SB_LINEPLUS := 1, SB_PAGEMINUS := 2, SB_PAGEPLUS := 3, SB_THUMBTRACK := 5
      Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
      If (LP <> 0)
         Return
      SB := (Msg = WM_HSCROLL ? 0 : 1) ; SB_HORZ : SB_VERT
      SC := WP & 0xFFFF
      SD := (Msg = WM_HSCROLL ? This.LineH : This.LineV)
      SI := 0
      If !This.GetScrollInfo(SB, SI)
         Return
      PA := PN := NumGet(SI, 20, "Int")
      If (SC = SB_LINEMINUS)
         PN := PA - SD
      Else If (SC = SB_LINEPLUS)
         PN := PA + SD
      Else If (SC = SB_PAGEMINUS)
         PN := PA - NumGet(SI, 16, "UInt")
      Else If (SC = SB_PAGEPLUS)
         PN := PA + NumGet(SI, 16, "UInt")
      Else If (SC = SB_THUMBTRACK)
         PN := NumGet(SI, 24, "Int")
      If (PA = PN)
         Return 0
      This.SetScrollInfo(SB, {Pos: PN})
      This.GetScrollInfo(SB, SI)
      PN := NumGet(SI, 20, "Int")
      If (SB = 0)
         This.PosH := PN
      Else
         This.PosV := PN
      If (PA <> PN) {
         HS := VS := 0
         If (Msg = WM_HSCROLL)
            HS := PA - PN
         Else
            VS := PA - PN
         DllCall("User32.dll\ScrollWindow", "Ptr", This.HWND, "Int", HS, "Int", VS, "Ptr", 0, "Ptr", 0)
      }
      Return 0
   }
   ; ===================================================================================================================
   On_WM_Wheel(LP, Msg, H) {
      Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
      Static WM_MOUSEWHEEL := 0x020A, WM_MOUSEHWHEEL := 0x020E
      HWND := WinExist("A")
      If ScrollGUI.Instances.HasKey(HWND) {
         Instance := Object(ScrollGUI.Instances[HWND])
         If ((Msg = WM_MOUSEHWHEEL) && Instance.WheelH)
         || ((Msg = WM_MOUSEWHEEL)  && Instance.WheelV)
            Return Instance.Wheel(This, LP, Msg, HWND)
      }
   }
   ; ===================================================================================================================
   Wheel(WP, LP, Msg, H) {
      Static MK_SHIFT := 0x0004
      Static SB_LINEMINUS := 0, SB_LINEPLUS := 1
      Static WM_MOUSEWHEEL := 0x020A, WM_MOUSEHWHEEL := 0x020E
      Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
      MSG := (Msg = WM_MOUSEWHEEL ? WM_VSCROLL : WM_HSCROLL)
      SB := ((WP >> 16) > 0x7FFF) || (WP < 0) ? SB_LINEPLUS : SB_LINEMINUS
      Return This.Scroll(SB, 0, MSG, H)
   }
}