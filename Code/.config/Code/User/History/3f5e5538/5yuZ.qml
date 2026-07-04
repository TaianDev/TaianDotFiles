import QtQuick
import Quickshell
import "./modules"
import "modules/launcher"

ShellRoot {
  Variants {
    model: Quickshell.screens
    
    Bar {
      required property var modelData
      screen: modelData
    }


  }
}
