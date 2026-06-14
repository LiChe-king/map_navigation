import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string spotName: ""
    property string spotType: ""
    property string distance: ""
    property int number: 0

    signal clicked()

    height: 52
    radius: 10
    color: mouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: "#e67e22"

            Text {
                anchors.centerIn: parent
                text: root.number
                color: "white"
                font.bold: true
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Label {
                text: root.spotName
                font.bold: true
                color: "#2c3e2f"
            }

            Label {
                text: root.spotType
                color: "#8f9b8a"
                font.pixelSize: 11
            }
        }

        Rectangle {
            implicitWidth: distLabel.implicitWidth + 16
            implicitHeight: distLabel.implicitHeight + 8
            radius: 14
            color: Qt.rgba(224, 229, 216, 0.8)

            Label {
                id: distLabel
                anchors.centerIn: parent
                text: root.distance + "米"
                color: "#de4d3f"
                font.pixelSize: 11
                font.bold: true
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
