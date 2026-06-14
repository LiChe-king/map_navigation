import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var spotsModel: []
    property bool editMode: false
    property int focusSpotId: -1

    signal spotClicked(var spot)

    Repeater {
        model: root.spotsModel

        delegate: Item {
            id: markerContainer

            x: modelData.x - markerRect.width / 2
            y: modelData.y - markerRect.height - 6
            opacity: root.editMode ? 0.6 : 1.0

            property int textWidth: markerText.implicitWidth + 32

            Rectangle {
                id: markerRect
                width: markerContainer.textWidth - 10
                height: 40
                radius: 15
                color: "#ffffff"
                border.color: modelData.id === root.focusSpotId ? "#ffcf33" : "#d0d5cc"
                border.width: 1.5

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: -5
                    verticalOffset: 5
                    radius: 10
                    samples: 8
                    color: "#30000000"
                }

                Text {
                    id: markerText
                    anchors.centerIn: parent
                    text: modelData.name
                    font.pixelSize: 30
                    font.family: "字魂扁桃体"
                    color: root.textColor(modelData.type)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            MouseArea {
                id: markerMouseArea
                anchors.fill: markerRect
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !root.editMode
                onClicked: root.spotClicked(modelData)
            }

            ToolTip {
                visible: markerMouseArea.containsMouse && !root.editMode
                text: modelData.name + " (" + modelData.type + ")"
                delay: 400
            }
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
