import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    implicitHeight: 40
    implicitWidth: 220
    padding: 0

    delegate: ItemDelegate {
        width: control.popup.width
        height: 36

        contentItem: Text {
            text: control.textRole && modelData && modelData[control.textRole] !== undefined
                ? modelData[control.textRole]
                : modelData
            color: "#21372f"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            color: highlighted ? "#e8efe4" : "white"
        }
    }

    indicator: Text {
        width: 30
        height: control.height
        x: control.width - width
        y: 0
        text: "▾"
        color: "#8f9b8a"
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    contentItem: TextInput {
        id: editor

        leftPadding: 12
        rightPadding: 34
        text: control.editable ? control.editText : control.displayText
        color: "#21372f"
        selectedTextColor: "white"
        selectionColor: "#5f80b4"
        readOnly: !control.editable
        selectByMouse: control.editable
        verticalAlignment: Text.AlignVCenter
        clip: true

        onTextEdited: {
            if (control.editable && control.editText !== text) {
                control.editText = text
            }
        }
    }

    background: Rectangle {
        radius: 8
        color: "#f8faf5"
        border.color: control.activeFocus ? "#5f80b4" : "#d2dacb"
        border.width: control.activeFocus ? 1.5 : 1
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            control.forceActiveFocus()
            if (!control.popup.opened) {
                control.popup.open()
            }
            mouse.accepted = true
        }
    }

    popup: Popup {
        x: 0
        y: control.height + 4
        width: Math.max(control.width, 240)
        implicitHeight: Math.min(contentItem.implicitHeight, 260)
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
        }

        background: Rectangle {
            color: "white"
            radius: 8
            border.color: "#d2dacb"
        }
    }
}
