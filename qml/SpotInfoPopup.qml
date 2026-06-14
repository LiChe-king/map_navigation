import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Popup {
    id: root

    property var popupSpot: ({})

    width: 320
    modal: false
    visible: root.popupSpot && root.popupSpot.name ? true : false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: "#ffffff"
        radius: 16
        border.color: "#e0e5dc"
        border.width: 1

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 12
            samples: 16
            color: "#30000000"
        }
    }

    Column {
        spacing: 8
        width: parent.width
        padding: 16

        Label {
            text: root.popupSpot.name || ""
            font.pixelSize: 20
            font.bold: true
            color: textColor(root.popupSpot.type)
        }

        Label {
            text: root.popupSpot.type || ""
            color: "#8f9b8a"
            font.pixelSize: 14
        }

        Label {
            width: parent.width
            text: root.popupSpot.intro || ""
            wrapMode: Text.WordWrap
            color: "#555"
            font.pixelSize: 13
        }
    }

    function textColor(type) {
        var colors = {
            "校门": "#4c84e1",
            "餐饮食堂": "#5f80b4",
            "公共教学楼": "#16a085",
            "学院专业楼": "#9b59b6",
            "体育场地": "#27ae60",
            "宿舍": "#1abc9c",
            "图书馆": "#3498db",
            "诊所": "#e74c3c",
            "景点": "#69806e",
            "活动场地": "#f1c40f"
        }
        return colors[type] || "#69806e"
    }
}
