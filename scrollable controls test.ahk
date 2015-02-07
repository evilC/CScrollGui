; an attempt at allowing controls to scroll using the mouse wheel
#SingleInstance force
#NoEnv

#Include <CScrollGUI>

SetBatchLines, -1
; -------------------------------------------------------------------------------------------------------------------
; ChildGUI 1
Gui, New, +hwndHGUI
Gui, Margin, 20, 20
Gui, Add, ListView, w380 h200 hwndLVTest, Col
Loop 20 {
	LV_ADD("", "Test")
}
; Create ScrollGUI1 with both horizontal and vertical scrollbars and mouse wheel capturing
SG1 := New NewScrollGui(HGUI, 400, 400, "+Resize +MinSize +LabelGui1", 3, 3)
; Show ScrollGUI1
SG1.Show("ScrollGUI1 Title", "y0 xcenter")

; ----------------------------------------------------------------------------------------------------------------------
ShowHide:
   GuiControlGet, V, %HGUI2%:Visible, TX2
   GuiControl, %HGUI2%:Hide%V%, TX2
   GuiControlGet, V, %HGUI2%:Visible, TX3
   GuiControl, %HGUI2%:Hide%V%, TX3
   SG2.AdjustToChild()
Return
; ----------------------------------------------------------------------------------------------------------------------
Esc::
Gui1Close:
Gui1Escape:
ExitApp
; ----------------------------------------------------------------------------------------------------------------------
Gui1Size:
   If (A_EventInfo <> 1)
      SG1.AdjustToParent()
Return
; ----------------------------------------------------------------------------------------------------------------------
Gui2Close:
Gui2Escape:
   SG2 := ""
Return

class NewScrollGui extends ScrollGUI {
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
      DllCall("User32.dll\GetClientRect", "Ptr", HWND, "Ptr", RECT[])
      PageH := RECT.Right
      PageV := RECT.Bottom
      ; Instance variables
      This.HWND := HWND
      This.HGUI := HGUI
      This.Width := Width
      This.Height := Height
      If (ScrollBars & 1) {
         ;This.SetScrollInfo(SB_HORZ, {Max: MaxH, Page: PageH, Pos: 0})
         ;SI := new 
         SI := new _Struct(WinStructs.SCROLLINFO)
         SI.nMax := MaxH
         SI.nPage := PageH
         SI.nPos := 0
         This.SetScrollInfo(SB_HORZ, SI)
         OnMessage(WM_HSCROLL, "NewScrollGUI.On_WM_Scroll")
         If (Wheel & 1)
            OnMessage(WM_MOUSEHWHEEL, "NewScrollGUI.On_WM_Wheel")
         This.MaxH := MaxH
         This.LineH := LineH
         This.PageH := PageH
         This.PosH := 0
         This.ScrollH := True
         If (Wheel)
            This.WheelH := True
      }
      If (ScrollBars & 2) {
         SI := new _Struct(WinStructs.SCROLLINFO)
         SI.nMax := MaxV
         SI.nPage := PageV
         SI.nPos := 0
         ;This.SetScrollInfo(SB_VERT, {Max: MaxV, Page: PageV, Pos: 0})
         This.SetScrollInfo(SB_VERT, SI)
         OnMessage(WM_VSCROLL, "NewScrollGUI.On_WM_Scroll")
         If (Wheel & 2)
            OnMessage(WM_MOUSEWHEEL, "NewScrollGUI.On_WM_Wheel")
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

   On_WM_Wheel(LP, Msg, H) {
		global LVTest
		MouseGetPos,tmp,tmp,tmp,hwnd,2
		if (hwnd = LVTest){
			HWND := LVTest
		} else {
			HWND := WinExist("A")	
		}
		Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
		Static WM_MOUSEWHEEL := 0x020A, WM_MOUSEHWHEEL := 0x020E
		If ScrollGUI.Instances.HasKey(HWND) {
			Instance := Object(NewScrollGUI.Instances[HWND])
			If ((Msg = WM_MOUSEHWHEEL) && Instance.WheelH) || ((Msg = WM_MOUSEWHEEL)  && Instance.WheelV){
				Return Instance.Wheel(This, LP, Msg, HWND)
			}
		}
   }
}