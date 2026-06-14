import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var allNodes: []
    property bool editMode: false
    property int focusSpotId: -1
    property int tempEdgeFrom: -1
    property real mapWidth: width
    property real mapHeight: height

    signal nodeMoved(int nodeId, double newX, double newY)
    signal edgeAdded(int fromId, int toId)
    signal nodeSelected(int nodeId)
    signal tempEdgeChanged(var fromId)

    Repeater {
        model: root.editMode ? root.allNodes : []

        delegate: Item {
            id: nodeDelegate

            x: modelData.x - 16
            y: modelData.y - 16
            width: 32
            height: 32
            z: 10

            property bool isSpot: modelData.id < 1000

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: nodeDelegate.isSpot
                    ? (modelData.id === root.focusSpotId ? "#ffcf33" : "#de4d3f")
                    : "#bdc3c7"
                border.color: root.tempEdgeFrom === modelData.id ? "#e67e22" : "white"
                border.width: root.tempEdgeFrom === modelData.id ? 3 : 2

                Text {
                    anchors.centerIn: parent
                    text: nodeDelegate.isSpot ? String(modelData.id) : "•"
                    font.pixelSize: nodeDelegate.isSpot ? 12 : 18
                    color: "white"
                }
            }

            MouseArea {
                id: nodeDragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.DragMoveCursor
                drag.target: parent
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: root.mapWidth - parent.width
                drag.minimumY: 0
                drag.maximumY: root.mapHeight - parent.height
                z: 11

                onReleased: {
                    if (root.editMode && modelData) {
                        root.nodeMoved(modelData.id, parent.x + 16, parent.y + 16)
                    }
                }

                onClicked: function(mouse) {
                    if (!root.editMode) {
                        root.nodeSelected(modelData.id)
                        return
                    }

                    if (mouse.modifiers & Qt.ControlModifier) {
                        if (root.tempEdgeFrom === -1) {
                            root.tempEdgeChanged(modelData.id)
                        } else {
                            if (root.tempEdgeFrom !== modelData.id) {
                                root.edgeAdded(root.tempEdgeFrom, modelData.id)
                            }
                            root.tempEdgeChanged(-1)
                        }
                    } else {
                        root.nodeSelected(modelData.id)
                    }
                    mouse.accepted = true
                }

                ToolTip {
                    visible: nodeDragArea.containsMouse && root.editMode
                    text: root.tempEdgeFrom === modelData.id
                        ? "连线中... 点击另一个节点完成连线"
                        : "拖拽移动 | Ctrl+点击连线"
                    delay: 400
                }
            }
        }
    }
}
