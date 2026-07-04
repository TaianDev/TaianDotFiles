import QtQuick
import Quickshell
import "./modules"
import "modules/launcher"
import "components/theme"

ShellRoot {
  Variants {
    model: Quickshell.screens
    
    Bar {
      required property var modelData
      screen: modelData
    }
  }
  // ── 2. El Lanzador de Aplicaciones (Instancia única y global) ──
    AppLauncher {
        id: globalLauncher
    }

    // ── 3. El Gatillo Invisible (Uno en la base de cada monitor) ──
    Variants {
        model: Quickshell.screens
        
        LauncherTrigger {
            required property var modelData
            screen: modelData
            targetLauncher: globalLauncher
        }
    }
}
