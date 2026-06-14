import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property int spotId: 0
    property string spotName: ""
    property string spotType: ""
    property string intro: ""

    signal clicked()

    height: 52
    radius: 10
    color: mouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: root.typeColor(root.spotType)

            Text {
                anchors.centerIn: parent
                text: root.spotId
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
                text: root.spotType + (root.intro ? " · " + root.intro : "")
                color: "#8f9b8a"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.fillWidth: true
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

    function typeColor(type) {
        var colors = {
            "校门": "#f39c12",
            "餐饮食堂": "#e67e22",
            "公共教学楼": "#1abc9c",
            "学院专业楼": "#9b59b6",
            "体育场地": "#27ae60",
            "宿舍": "#16a085",
            "图书馆": "#3498db",
            "诊所": "#e74c3c",
            "景点": "#2ecc71",
            "活动场地": "#f1c40f",
            "其他": "#7f8c8d"
        }
        return colors[type] || "#de4d3f"
    }
}
