pragma Singleton

import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false

    function lock() {
        lockRunner.running = false
        lockRunner.running = true
    }

    function sleep() {
        suspendRunner.running = false
        suspendRunner.running = true
    }

    function logout() {
        logoutRunner.running = false
        logoutRunner.running = true
    }

    function poweroff() {
        poweroffRunner.running = false
        poweroffRunner.running = true
    }

    function executeCommand(cmd) {
        cmdRunner.command = cmd
        cmdRunner.running = false
        cmdRunner.running = true
    }

    Process {
        id: lockRunner
        command: ["hyprlock"]
    }

    Process {
        id: suspendRunner
        command: ["systemctl", "suspend"]
    }

    Process {
        id: logoutRunner
        command: ["hyprctl", "dispatch", "exit"]
    }

    Process {
        id: poweroffRunner
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: cmdRunner
        command: ["true"]
    }
}
