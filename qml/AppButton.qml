import QtQuick
import QtQuick.Controls

Button {
    id: control

    property color buttonColor: "#5f80b4"
    property color buttonTextColor: "white"
    property color borderColor: "transparent"

    implicitHeight: 40

    background: Rectangle {
        radius: 8
        color: control.enabled
            ? (control.down ? Qt.darker(control.buttonColor, 1.12)
                            : control.hovered ? Qt.lighter(control.buttonColor, 1.08)
                                              : control.buttonColor)
            : "#c7cec4"
        border.color: control.borderColor
        border.width: control.borderColor === "transparent" ? 0 : 1
    }

    contentItem: Text {
        text: control.text
        color: control.enabled ? control.buttonTextColor : "#eef2eb"
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
