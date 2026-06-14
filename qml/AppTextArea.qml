import QtQuick
import QtQuick.Controls

TextArea {
    id: control

    color: "#21372f"
    placeholderTextColor: "#9aa59a"
    selectedTextColor: "white"
    selectionColor: "#5f80b4"
    padding: 10

    background: Rectangle {
        radius: 8
        color: "#f8faf5"
        border.color: control.activeFocus ? "#5f80b4" : "#d2dacb"
        border.width: control.activeFocus ? 1.5 : 1
    }
}
