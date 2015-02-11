#SingleInstance force
#NoEnv
#Include class_scrollgui.ahk

SetBatchLines, -1
; -------------------------------------------------------------------------------------------------------------------
; ChildGUI 1
Gui, New, +hwndHGUI
Gui, Margin, 20, 20
Loop 10 {
   Gui, new, % "hwndChild -Border +Parent" HGUI
   Gui, % Child ":Add", Text, % "xm ym", Child %A_Index%
   Gui, % Child ":Show", % "h40 w380 x5 y" (A_Index - 1)*50,
}
; Create ScrollGUI1 with both horizontal and vertical scrollbars and mouse wheel capturing
SG1 := New ScrollGUI(HGUI, 400, 200, "+Resize +MinSize +LabelGui1", 3, 3)
; Show ScrollGUI1
SG1.Show("ScrollGUI1 Title", "y0 xcenter")
SG1.AdjustToChild()
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
   SG1 := ""
Return
