#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

###############################################################################
#
# Create undimensioned connectors for an ellipse.
#
# Author:  Kasey Tillema
# Date:    June 2012
#
###############################################################################

package require PWI_Glyph 2.3

pw::Script loadTk

# initialize global variables to default values

# major axis along x of length 2A
set A 10.0

# minor axis along y of length 2B
set B 5.0

# eccentricity as calculated from A and B
set ecc [expr {sqrt(1.0 - ($B/$A) * ($B/$A))}]

# center point
set center [list 0.0 0.0 0.0]


proc checkValidity { } {
  global validInput
  global okButton

  foreach var [array names validInput] {
    if { $validInput($var) == 0 } {
      $okButton configure -state disabled
      return 0
    }
  }

  $okButton configure -state normal
  return 1
}


proc checkABInput { w var value } {
  global validInput myColors

  if { ! [string is double -strict $value] || $value == 0.0 } {
    $w configure -bg $myColors(invalid)
    set validInput($var) 0
  } else {
    $w configure -bg $myColors(valid)
    set validInput($var) 1
  }

  checkValidity

  return 1
}


proc checkEccInput { w var value } {
  global validInput myColors

  if {![string is double -strict $value] || $value >= 1.0 || $value < 0.0} {
    $w configure -bg $myColors(invalid)
    set validInput($var) 0
  } else {
    $w configure -bg $myColors(valid)
    set validInput($var) 1
  }

  checkValidity

  return 1
}


proc checkOriginInput { w var xyz } {
  global validInput myColors

  if [catch { eval [concat pwu::Vector3 set $xyz] }] {
    $w configure -bg $myColors(invalid)
    set validInput($var) 0
  } else {
    $w configure -bg $myColors(valid)
    set validInput($var) 1
  }

  checkValidity

  return 1
}


proc updateInputs { } {
  global myVars selection

  if {[catch {
    set Aval1 [format "%6.5f" $myVars(aVal)]
    set Bval1 [format "%6.5f" $myVars(bVal)]
    set EccVal1 [format "%9.8f" $myVars(eccentric)]

    switch -exact $selection {
      "B" {
        set myVars(aVal) \
            [format "%6.5f" [expr $Bval1 / sqrt(1.0 - $EccVal1 ** 2)]]
      }

      "A" {
        set myVars(bVal) \
            [format "%6.5f" [expr $Aval1 * sqrt(1.0 - $EccVal1 ** 2)]]
      }

      "AB" {
         if { abs($Aval1) < abs($Bval1)} {
           set value1 $Aval1
           set Aval1  $Bval1
           set Bval1  $value1
         }

         set EccVal1 \
             [format "%9.8f" [expr sqrt(1.0 - ($Bval1/$Aval1) ** 2)]]

         # Prevent EccVal from reaching 1.0
         if { abs($EccVal1 - 1.0) < 0.000001 } {
           set EccVal1 0.999999
         }
         set myVars(eccentric) $EccVal1
      }
    }
  } msg]} {
    puts $msg
    tk_messageBox -icon warning -message "Invalid input." \
        -title "Create an Elliptic Connector" -type ok
  }
}


proc rotationMatrix { theta axis vector } {
  set xform [pwu::Transform rotation $axis [expr -1 * $theta]]
  return [pwu::Transform apply $xform $vector]
}


proc useViewPoint { } {
  global x1Axis y1Axis

  set view1 [pw::Display getCurrentView]
  set rotateVector [lindex $view1 2]
  set rotateAngle [lindex $view1 3]

  # Transform x and y axes to unit vectors in the screen horizontal and
  # vertical
  set x1Axis [rotationMatrix $rotateAngle $rotateVector {1 0 0}]
  set y1Axis [rotationMatrix $rotateAngle $rotateVector {0 1 0}]
}


proc drawCanvas { c } {
  set w [$c cget -width]
  set h [$c cget -height]
  set w2 [expr {0.5 * $w}]
  set h2 [expr {0.5 * $h}]

  # The ellipse
  set xa [expr {0.1 * $w}]
  set xb [expr {0.9 * $w}]
  set yd [expr {0.25 * ($xb - $xa)}]
  set ya [expr {$h2 - 0.5 * $yd}]
  set yb [expr {$ya + 2.0 * $yd}]
  $c create arc $xa $ya $xb $yb -start 0 -extent 180 -style arc -outline red \
      -width 3

  # The center
  set d1 3.0
  set d2 [expr {2.0 * $d1}]
  set d3 [expr {6.0 * $d1}]
  set d4 [expr {3.0 * $d1}]
  set ox [expr {int($w2)}]
  set oy [expr {int(0.5 * ($ya + $yb))}]
  $c create line [list [expr {$ox - $d1}] $oy [expr {$xb + $d3}] $oy] \
      -arrow none -fill black
  $c create line [list $ox [expr {$ya - $d3}] $ox [expr {$oy + $d1 + 1}]] \
      -arrow none -fill black

  # Vertical measurement
  set x1 [expr {$ox - $d2}]
  set x2 [expr {$x1 - $d3}]
  $c create line [list $x1 $oy $x2 $oy] -arrow none -fill black
  $c create line [list $x1 $ya $x2 $ya] -arrow none -fill black
  set xm [expr {0.5 * ($x1 + $x2)}]
  $c create line [list $xm $oy $xm $ya] -arrow both \
      -arrowshape [list $d4 $d4 $d1] -fill black

  # Horizontal measurement
  set y1 [expr {$oy + $d2}]
  set y2 [expr {$y1 + $d3}]
  $c create line [list $ox $y1 $ox $y2] -arrow none -fill black
  $c create line [list $xb $y1 $xb $y2] -arrow none -fill black
  set ym [expr {0.5 * ($y1 + $y2)}]
  $c create line [list $ox $ym $xb $ym] -arrow both \
        -arrowshape [list $d4 $d4 $d1] -fill black

  # Diagonal measurement
  set ydi1 $oy
  set ydi2 [expr {1.25 * $oy}]
  set xdi1 $ox
  set xdi2 [expr {0.75 * $ox}]
  $c create line [list $xdi1 $ydi1 $xdi2 $ydi2] -arrow first -fill black

  # B label
  set x_b [expr {.95 * $x2}]
  set y_b [expr {0.5 * ($ya - $oy) + $oy}]
  $c create text $x_b $y_b -text "B"

  # A label
  set x_a [expr {0.5 * ($xb - $ox) + $ox}]
  set y_a [expr {1.05 * $y2}]
  $c create text $x_a $y_a -text "A"

  # Origin label
  set x_or [expr {0.85 * $xdi2}]
  set y_or $ydi2
  $c create text $x_or $y_or -text "Origin"
}


proc buildWidgets { top } {
  global okButton myVars validInput myColors
  global ecc eccInput aInput bInput
  global selection ent_select

  wm title . ConEllipse

  if {$top == "."} {
    set parent [frame ${top}t]
  } else {
    set parent [frame ${top}.t]
  }
  pack $parent -fill both -expand 1

  # Label
  set l [label $parent.l -text "Create an Elliptic Connector"];
  set font [$l cget -font]
  set fontFamily [font actual $font -family]
  set fontSize [font actual $font -size]
  set bigLabelFont [font create -family $fontFamily -weight bold \
      -size [expr {int(1.25 * $fontSize)}]]
  $l configure -font $bigLabelFont
  pack $l -side top -fill x -expand 0 -anchor c

  # Divider rule
  set f [frame $parent.hr1 -bd 1 -height 2 -relief sunken]
  pack $f -side top -fill x -expand 0

  # Bottom frame
  set botFrame [frame $parent.bf]
  pack $botFrame -side bottom -fill x

  # Divider rule
  set f [frame $parent.hr2 -bd 1 -height 2 -relief sunken]
  pack $f -side bottom -fill x -expand 0

  # Side Frame
  set sideFrame [frame $parent.sf]
  pack $sideFrame -side left -anchor w -padx 5
  set entspacing ""

  # Parameters frame
  set parFrame [labelframe $sideFrame.parf -text "Parameters"]
  $parFrame configure -width 300 -relief sunken -bd 1
  pack $parFrame -side bottom -padx 10 -pady 10

  # Create A input
  set aFrame [frame $parFrame.a]
  pack $aFrame -side top -fill x -anchor w -padx 5 -pady 5

  set myVars(aVal) 10.0

  set aInput [entry $aFrame.aVal -textvariable myVars(aVal) -width 12]
  pack $aInput -side right
  set aLabel [label $aFrame.laVal -text "A" -anchor e]
  pack $aLabel -side left
  set validInput(aVal) 1
  $aInput configure -validate key -validatecommand \
      [list checkABInput $aInput aVal %P]

  # Create B input
  set bFrame [frame $parFrame.b]
  pack $bFrame -side top -fill x -anchor w -padx 5 -pady 5

  set myVars(bVal) 5.0

  set bInput [entry $bFrame.bVal -textvariable myVars(bVal) -width 12]
  pack $bInput -side right
  set bLabel [label $bFrame.lbVal -text "B" -anchor e]
  pack $bLabel -side left
  set validInput(bVal) 1
  $bInput configure -validate key -validatecommand \
      [list checkABInput $bInput bVal %P]

  set myColors(valid) [$bInput cget -bg]
  set myColors(invalid) "#FFCCCC"

  # Create Eccentricity Input
  set eccFrame [frame $parFrame.ecc]
  pack $eccFrame -side top -fill x -anchor w -padx 5 -pady 5

  set ecc1 $ecc
  set resultEcc [format "%1.5f" $ecc1]
  set myVars(eccentric) $resultEcc

  set eccInput [entry $eccFrame.eccentric -textvariable myVars(eccentric) \
      -width 12]
  pack $eccInput -side right -anchor e
  set eccLabel [label $eccFrame.eccLabel -text "Ecc" -anchor e]
  pack $eccLabel -side left
  set validInput(eccentric) 1
  $eccInput configure -validate key -validatecommand \
      [list checkEccInput $eccInput eccentric %P]

  $eccInput configure -state disabled

  # Create origin input
  set oFrame [frame $parFrame.o]
  pack $oFrame -side top -fill x -anchor w -padx 5 -pady 5

  set myVars(origin) [list 0.0 0.0 0.0]

  set oInput [entry $oFrame.origin -textvariable myVars(origin) -width 12]
  pack $oInput -side right
  set oLabel [label $oFrame.oLabel -text "Origin" -anchor e]
  pack $oLabel -side left
  set validInput(origin) 1
  $oInput configure -validate key -validatecommand \
      [list checkOriginInput $oInput origin %P]

  # Options frame
  set optFrame [labelframe $sideFrame.optf -text "Options"]
  $optFrame configure -height 100 -relief sunken -bd 1
  pack $optFrame -side bottom -padx 5 -pady 5
  set spacerlabel [label $optFrame.spacer -text [append $entspacing "     "]]
  pack $spacerlabel -side right

  # Radio buttons
  set opt_b 0
  set opt_args [list "A and B" "A and Eccentricity" "B and Eccentricity"]
  set opt_choice "A and B"
  foreach item $opt_args {
    radiobutton $optFrame.$opt_b -variable $opt_choice -text $item -value $item
    foreach opt_item [list nw w sw] {
      pack $optFrame.$opt_b -anchor $opt_item
    }
    incr opt_b
  }

  # Radio button commands
  set selection "AB"
  set default_b $optFrame.0
  $default_b configure -command {
    $aInput configure -state normal; \
    $bInput configure -state normal; \
    $eccInput configure -state disabled; \
    set selection AB
  }
  set eccAndA_b $optFrame.1
  $eccAndA_b configure -command {
    $aInput configure -state normal; \
    $bInput configure -state disabled; \
    $eccInput configure -state normal; \
    set selection A
  }
  set eccAndB_b $optFrame.2
  $eccAndB_b configure -command {
    $aInput configure -state disabled; \
    $bInput configure -state normal; \
    $eccInput configure -state normal; \
    set selection B
  }
  $default_b select

  # Input bindings
  bind $aFrame.aVal <Key-Return> {updateInputs}
  bind $aFrame.aVal <FocusOut> {updateInputs}
  bind $bFrame.bVal <Key-Return> {updateInputs}
  bind $bFrame.bVal <FocusOut> {updateInputs}
  bind $eccFrame.eccentric <Key-Return> {updateInputs}
  bind $eccFrame.eccentric <FocusOut> {updateInputs}

  # Entity frame
  set entFrame [labelframe $sideFrame.entf -text "Entity Type"]
  $entFrame configure -height 100 -relief sunken -bd 1
  pack $entFrame -side bottom -padx 10 -pady 10
  set spacerlabel [label $entFrame.spacer -text $entspacing]
  pack $spacerlabel -side right

  set ent_b 0
  foreach item [list "Grid" "Database"] {
    radiobutton $entFrame.$ent_b -variable "Grid" -text $item -value $item
    foreach ent_item [list right left] {
      pack $entFrame.$ent_b -side $ent_item -padx 5 -pady 5
    }
    incr ent_b
  }

  # Radio button commands
  set ent_select G
  set grid_b $entFrame.0
  $grid_b configure -command {set ent_select G}
  set database_b $entFrame.1
  $database_b configure -command {set ent_select D}
  $grid_b select

  # Canvas
  set c [canvas $parent.c -width 500 -height 300 -bd 1 \
      -highlightthickness 0 -relief sunken]
  pack $c -side left -fill none -expand 0 -anchor c -padx 40 -pady 30

  # Logo
  pack [label $botFrame.logo -image [pwLogo] -bd 0 -relief flat] \
      -side left -padx 5

  # Button frame
  set f [frame $botFrame.f]
  pack $f -side right -fill x
  set buttonWidth 10

  # Apply button
  set okButton [button $f.apply -text "OK" -width $buttonWidth \
      -command {wm iconify . ; createEllipse; exit}]
  # Cancel button
  set cancelButton [button $f.abort -text "Cancel" -width $buttonWidth \
      -command {exit}]

  grid $okButton $cancelButton -pady 10 -padx 5 -sticky nsew
  pack $f -side right -fill x -expand 0

  # Draw the canvas
  ::tk::PlaceWindow $top widget
  drawCanvas $c
}


proc createEllipse { } {
  global myVars ent_select x1Axis y1Axis

  set A $myVars(aVal)
  set B $myVars(bVal)
  set center $myVars(origin)

  # conic rho value for an ellipse
  set R [expr sqrt(2) - 1]

  # create 1/4 ellipse in the XY quadrant
  if {[catch {
    set viewNow [pw::Display getCurrentView]
    set rotation [lindex $viewNow 2]

    if [pwu::Vector3 equal -tolerance 0.00000001 $rotation {0 0 0}] {
      set vecA "$A 0 0"
      set vecB "0 $B 0"
    } else {
      useViewPoint
      set vecA [pwu::Vector3 scale $x1Axis $A]
      set vecB [pwu::Vector3 scale $y1Axis $B]
    }

    if {$ent_select == "G"} {
      set con [pw::Connector create]
    } else {
      set con [pw::Curve create]
    }

    set seg [pw::SegmentConic create]
    $seg setRho $R
    $seg addPoint [pwu::Vector3 add $vecA $center]
    $seg addPoint [pwu::Vector3 add $vecB $center]
    $seg setIntersectPoint \
        [pwu::Vector3 add [pwu::Vector3 add $vecA $vecB] $center]

    $con addSegment $seg
    set A [expr {-1.0 * $A}]

    if {$rotation == [list 0.0 0.0 0.0]} {
      set vecA "$A 0 0"
      set vecB "0 $B 0"
    } else {
      useViewPoint
      set vecA [pwu::Vector3 scale $x1Axis $A]
      set vecB [pwu::Vector3 scale $y1Axis $B]
    }

    set seg [pw::SegmentConic create]
    $seg setRho $R
    $seg addPoint [pwu::Vector3 add $vecB $center]
    $seg addPoint [pwu::Vector3 add $vecA $center]
    $seg setIntersectPoint \
        [pwu::Vector3 add [pwu::Vector3 add $vecA $vecB] $center]

    $con addSegment $seg
  } msg]} {
    puts $msg
    tk_messageBox -icon warning -message "Ellipse could not be created." \
        -title "Create an Elliptic Connector" -type ok
    exit
  }

  return $con
}


proc pwLogo {} {

set logoData "
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs="

  return [image create photo -format GIF -data $logoData]
}



buildWidgets .
::tk::PlaceWindow . widget


#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
