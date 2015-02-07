#SingleInstance force
#Include <CScrollGUI>
#Include <AutoXYWH>

Gui, +Resize hwndHGUI
Gui, Add, Edit  ,    w200 h200    hwndhEdit
Gui, Add, Button, ys w40 hp vBtn1
Gui, Add, Button, ys wp  hp vBtn2
Gui, Add, Text, ,Hello
Gui, Add, Text, ,Hello
Gui, Add, Text, ,Hello
Gui, Add, Text, ,Hello
Gui, Add, Text, ,Hello
Gui, Add, Text, ,Hello

; Create ScrollGUI1 with both horizontal and vertical scrollbars and mouse wheel capturing
SG1 := New ScrollGUI(HGUI, 0, 0, "+Resize +LabelGui1", 3, 3)
; Show ScrollGUI1
SG1.Show("ScrollGUI1 Title", "")
;Gui, Show
Return

GuiSize:
    AutoXYWH(hEdit, "w")
    AutoXYWH("Btn1|Btn2", "x")
Return

GuiClose:
ExitApp
