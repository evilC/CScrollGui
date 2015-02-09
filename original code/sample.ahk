#SingleInstance force
#NoEnv
#Include Class_ScrollGUI.ahk
SetBatchLines, -1
; -------------------------------------------------------------------------------------------------------------------
; ChildGUI 1
Gui, New, +hwndHGUI
Gui, Margin, 20, 20
I := 0
Gui, Add, Text, w370 h20 0x200 Section, % "Edit " . ++I
Gui, Add, Edit, xp y+0 wp r6
Loop, 4 {
   Gui, Add, Text, xp y+0 wp h20 0x200, % "Edit " . ++I
   Gui, Add, Edit, xp y+0 wp r6
}
Gui, Add, Text, ys wp h20 0x200, % "Edit " . ++I
Gui, Add, Edit, xp y+0 wp r6
Loop, 4 {
   Gui, Add, Text, xp y+0 wp h20 0x200, % "Edit " . ++I
   Gui, Add, Edit, xp y+0 wp r6
}
; Create ScrollGUI1 with both horizontal and vertical scrollbars and mouse wheel capturing
SG1 := New ScrollGUI(HGUI, 400, 400, "+Resize +MinSize +LabelGui1", 3, 3)
; Show ScrollGUI1
SG1.Show("ScrollGUI1 Title", "y0 xcenter")
; -------------------------------------------------------------------------------------------------------------------
; ChildGUI 2
Gui, New, +hwndHGUI2
Gui, Margin, 20, 20
Gui, Font, s32
Gui, Add, Text, xm w460 h300 Center 0x200 Border Section, GUI number 2
Gui, Font
Gui, Add, Button, xm wp gShowHide, Show/Hide additional controls.
Gui, Font, s32
Gui, Add, Text, ys wp h300 Center 0x200 Border Hidden vTX2, Hidden Text 1
Gui, Add, Text, xs wp h300 Center 0x200 Border Hidden vTX3, Hidden Text 2
; Create ScrollGUI2 with both horizontal and vertical scrollbars
SG2 := New ScrollGUI(HGUI2, 600, 200, "+LabelGui2 +Resize")
; Show ScrollGUI2
SG2.Show("ScrollGUI2 Title", "x0 yCenter")
Return
; ----------------------------------------------------------------------------------------------------------------------
ShowHide:
   GuiControlGet, V, %HGUI2%:Visible, TX2
   GuiControl, %HGUI2%:Hide%V%, TX2
   GuiControlGet, V, %HGUI2%:Visible, TX3
   GuiControl, %HGUI2%:Hide%V%, TX3
   SG2.AdjustToChild()
Return
; ----------------------------------------------------------------------------------------------------------------------
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
 