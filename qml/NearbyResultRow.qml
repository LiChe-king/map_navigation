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
    signal navigateClicked()

    height: 54
    radius: 10
    color: rowMouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"

    RowLayout {
        z: 1
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
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
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: root.spotName
                font.bold: true
                color: "#2c3e2f"
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Label {
                text: root.spotType
                color: "#8f9b8a"
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Rectangle {
            Layout.preferredWidth: 66
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            radius: 14
            color: Qt.rgba(224, 229, 216, 0.8)

            Label {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                text: root.distance + "米"
                color: "#de4d3f"
                font.pixelSize: 11
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Button {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            text: "➤"
            onClicked: root.navigateClicked()
            background: Rectangle {
                radius: 10
                color: parent.hovered ? Qt.rgba(224, 229, 216, 0.9) : "#f8faf5"
                border.color: "#d2dacb"
                border.width: 1.5
            }
            contentItem: Text {
                text: parent.text
                color: "#3498db"
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                rotation: -90
            }
            ToolTip.text: "规划路线"
            ToolTip.visible: hovered
        }
    }

    MouseArea {
        id: rowMouseArea
        anchors.fill: parent
        z: 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
