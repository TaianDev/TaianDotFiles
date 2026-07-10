//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import "core"
import "services"
import "./modules"
import "modules/launcher"
import "components/theme"

ShellRoot {
    ThemeLoader { }

    Item {
        visible: false
        Component.onCompleted: NetworkStatusService.refresh()
    }

    Variants {
        model: Quickshell.screens

        Bar { }
    }

    AppLauncher {
        id: globalLauncher
    }

    ThemeChanger {
        id: themeChanger
    }
}
