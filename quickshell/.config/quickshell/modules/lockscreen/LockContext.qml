import QtQuick
import Quickshell.Services.Pam

Item {
    id: root
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    signal unlocked()

    onCurrentTextChanged: {
        if (showFailure)
            showFailure = false
    }

    PamContext {
        id: pam
        // "config" es el NOMBRE del servicio pam (sin extensión .conf),
        // "configDirectory" apunta a la carpeta donde está tu archivo custom.
        config: "password"
        configDirectory: Qt.resolvedUrl("pam").toString().replace("file://", "")

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root.currentText)
            }
        }

        onCompleted: (result) => {
            root.unlockInProgress = false
            if (result === PamResult.Success) {
                root.showFailure = false
                root.unlocked()
            } else {
                root.showFailure = true
            }
        }

        onError: (err) => {
            root.unlockInProgress = false
            root.showFailure = true
        }
    }

    function tryUnlock() {
        if (root.currentText === "" || root.unlockInProgress)
            return
        root.unlockInProgress = true
        root.showFailure = false
        pam.start()
    }
}
