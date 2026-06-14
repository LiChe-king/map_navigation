import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var spotsModel: []
    property var markerSpotsModel: spotsModel
    property var pathResult: ({})
    property int focusSpotId: -1
    property int tempEdgeFrom: -1
    property var popupSpot: ({})
    property bool editMode: false
    property string editTool: "select"
    property var allNodes: []
    property var edges: []
    property real mapLayerScale: mapLayer.scale
    property real lastMouseX: width / 2
    property real lastMouseY: height / 2
    property int previewNodeId: -1
    property real previewNodeX: 0
    property real previewNodeY: 0

    signal nodeMoved(int nodeId, double newX, double newY)
    signal nodePreviewMoved(int nodeId, double newX, double newY)
    signal edgeAdded(int fromId, int toId)
    signal edgeRemoved(int fromId, int toId)
    signal nodeSelected(int nodeId)
    signal tempEdgeChanged(var fromId)
    signal mapClicked(double mapX, double mapY)

    focus: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape && root.tempEdgeFrom !== -1) {
            root.tempEdgeChanged(-1)
            event.accepted = true
        }
    }

    onEditModeChanged: {
        if (!root.editMode) {
            root.tempEdgeChanged(-1)
        }
    }
    onSpotsModelChanged: markerSpotsModel = spotsModel

    Rectangle {
        anchors.fill: parent
        color: "#e8efe4"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 50
        onPositionChanged: function(mouse) {
            root.lastMouseX = mouse.x
            root.lastMouseY = mouse.y
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: mapLayer.width * mapLayer.scale
        contentHeight: mapLayer.height * mapLayer.scale

        Item {
            id: mapLayer
            width: Math.max(mapImage.sourceSize.width, 1536)
            height: Math.max(mapImage.sourceSize.height, 2048)
            scale: 0.58
            transformOrigin: Item.TopLeft

            Image {
                id: mapImage
                anchors.fill: parent
                source: "qrc:/qt/qml/CampusGuide/data/campus_map.jpg"
                fillMode: Image.Stretch
                smooth: true
            }

            PathDrawer {
                anchors.fill: parent
                pathPoints: root.pathResult.points || []
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.editMode && (root.editTool === "drawRoad" || root.editTool === "addSpot")
                cursorShape: root.editTool === "addSpot" ? Qt.CrossCursor : Qt.PointingHandCursor
                z: 2
                onClicked: function(mouse) {
                    root.mapClicked(mouse.x, mouse.y)
                }
            }

            MapEdgesLayer {
                anchors.fill: parent
                editMode: root.editMode && root.editTool === "select"
                edges: root.edges
                allNodes: root.allNodes
                previewNodeId: root.previewNodeId
                previewNodeX: root.previewNodeX
                previewNodeY: root.previewNodeY
                onEdgeRemoved: function(fromId, toId) {
                    root.edgeRemoved(fromId, toId)
                }
            }

            MapNodeLayer {
                anchors.fill: parent
                z: 10
                editMode: root.editMode
                allNodes: root.allNodes
                focusSpotId: root.focusSpotId
                tempEdgeFrom: root.tempEdgeFrom
                mapWidth: mapLayer.width
                mapHeight: mapLayer.height
                onNodeMoved: function(nodeId, newX, newY) {
                    root.nodeMoved(nodeId, newX, newY)
                    root.clearNodePreview()
                }
                onNodePreviewMoved: function(nodeId, newX, newY) {
                    root.previewNodeId = nodeId
                    root.previewNodeX = newX
                    root.previewNodeY = newY
                    root.nodePreviewMoved(nodeId, newX, newY)
                }
                onEdgeAdded: function(fromId, toId) {
                    root.edgeAdded(fromId, toId)
                }
                onNodeSelected: function(nodeId) {
                    root.nodeSelected(nodeId)
                    root.focusSpotId = nodeId
                }
                onTempEdgeChanged: function(fromId) {
                    root.tempEdgeChanged(fromId)
                }
            }

            TempEdgeLine {
                anchors.fill: parent
                editMode: root.editMode
                tempEdgeFrom: root.tempEdgeFrom
                allNodes: root.allNodes
            }

            SpotMarkersLayer {
                anchors.fill: parent
                z: 1
                spotsModel: root.markerSpotsModel
                editMode: root.editMode
                focusSpotId: root.focusSpotId
                previewSpotId: root.previewNodeId < 1000 ? root.previewNodeId : -1
                previewSpotX: root.previewNodeX
                previewSpotY: root.previewNodeY
                onSpotClicked: function(spot) {
                    root.popupSpot = spot
                    root.focusSpotId = spot.id
                }
            }
        }

        WheelHandler {
            id: wheelHandler
            target: null
            onWheel: function(event) {
                var oldScale = mapLayer.scale
                var nextScale = Math.max(0.35, Math.min(1.8, oldScale + event.angleDelta.y / 1200))
                if (nextScale === oldScale) return

                var anchorX = root.lastMouseX
                var anchorY = root.lastMouseY
                var anchorMapX = (flickable.contentX + anchorX) / oldScale
                var anchorMapY = (flickable.contentY + anchorY) / oldScale
                mapLayer.scale = nextScale

                flickable.contentX = clamp(anchorMapX * nextScale - anchorX, 0, Math.max(0, mapLayer.width * nextScale - flickable.width))
                flickable.contentY = clamp(anchorMapY * nextScale - anchorY, 0, Math.max(0, mapLayer.height * nextScale - flickable.height))
                event.accepted = true
            }
        }
    }

    SpotInfoPopup {
        id: infoPopup
        x: parent.width - 360
        y: 24
        z: 20
        popupSpot: root.popupSpot
    }

    function jumpToSpot(spotX, spotY) {
        var targetX = spotX * mapLayer.scale - flickable.width / 2
        var targetY = spotY * mapLayer.scale - flickable.height / 2
        targetX = Math.max(0, Math.min(targetX, flickable.contentWidth - flickable.width))
        targetY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height))
        flickable.contentX = targetX
        flickable.contentY = targetY
    }

    function viewportToMap(viewX, viewY) {
        return {
            x: (flickable.contentX + viewX) / mapLayer.scale,
            y: (flickable.contentY + viewY) / mapLayer.scale
        }
    }

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(value, maxValue))
    }

    function clearNodePreview() {
        root.previewNodeId = -1
    }
}
