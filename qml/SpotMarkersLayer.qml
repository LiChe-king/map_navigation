import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var spotsModel: []
    property bool editMode: false
    property int focusSpotId: -1
    property int previewSpotId: -1
    property real previewSpotX: 0
    property real previewSpotY: 0

    signal spotClicked(var spot)

    Repeater {
        model: root.spotsModel

        delegate: Item {
            id: markerContainer

            x: markerContainer.effectiveX - markerRect.width / 2
            y: markerContainer.effectiveY - markerRect.height - 6
            opacity: root.editMode ? 0.6 : 1.0

            property bool isSchoolGate: modelData.type === "校门" || modelData.type === "鏍￠棬"
            property int textWidth: markerText.implicitWidth + (markerContainer.isSchoolGate ? 44 : 32)
            property real effectiveX: modelData.id === root.previewSpotId ? root.previewSpotX : modelData.x
            property real effectiveY: modelData.id === root.previewSpotId ? root.previewSpotY : modelData.y

            Rectangle {
                id: markerRect
                width: markerContainer.isSchoolGate ? markerContainer.textWidth + 10 : markerContainer.textWidth - 10
                height: markerContainer.isSchoolGate ? 70 : 40
                radius: markerContainer.isSchoolGate ? 30 : 15
                color: "#ffffff"
                border.color: modelData.id === root.focusSpotId ? "#ffcf33" : "#d0d5cc"
                border.width: markerContainer.isSchoolGate ? 2 : 1.5

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
                    font.pixelSize: markerContainer.isSchoolGate ? 50 : 30
                    font.letterSpacing: markerContainer.isSchoolGate ? 5 : 2
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
