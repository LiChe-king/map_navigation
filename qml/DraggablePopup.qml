import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Popup {
    id: root

    property string titleText: ""
    default property alias popupContent: contentHost.data

    modal: false
    closePolicy: Popup.NoAutoClose

    background: Rectangle {
        color: Qt.rgba(255, 255, 255, 0.92)
        radius: 16
        border.color: Qt.rgba(224, 224, 224, 0.8)
        border.width: 1

        MouseArea {
            anchors.fill: parent
            property point dragStart

            onPressed: function(mouse) {
                dragStart = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    root.x += mouse.x - dragStart.x
                    root.y += mouse.y - dragStart.y
                }
            }
        }

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 6
            radius: 20
            samples: 32
            color: "#40000000"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "transparent"
            radius: 16

            Label {
                text: root.titleText
                font.pixelSize: 16
                font.bold: true
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                color: "#2c3e2f"
            }

            Button {
                flat: true
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.close()
                background: Rectangle {
                    radius: 14
                    color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent"
                }
                contentItem: Text {
                    text: "×"
                    color: "#8f9b8a"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(224, 229, 216, 0.6)
            }
        }

        ColumnLayout {
            id: contentHost
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
        }
    }
}
