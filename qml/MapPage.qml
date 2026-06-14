import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var spotsModel: []
    property var pathResult: ({})
    property int focusSpotId: -1
    property int tempEdgeFrom: -1
    property var popupSpot: ({})
    property bool editMode: false
    property var allNodes: []
    property var edges: []
    property real mapLayerScale: mapLayer.scale

    signal nodeMoved(int nodeId, double newX, double newY)
    signal edgeAdded(int fromId, int toId)
    signal edgeRemoved(int fromId, int toId)
    signal nodeSelected(int nodeId)
    signal tempEdgeChanged(var fromId)

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

    Rectangle {
        anchors.fill: parent
        color: "#e8efe4"
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

            MapEdgesLayer {
                anchors.fill: parent
                editMode: root.editMode
                edges: root.edges
                allNodes: root.allNodes
                onEdgeRemoved: function(fromId, toId) {
                    root.edgeRemoved(fromId, toId)
                }
            }

            MapNodeLayer {
                anchors.fill: parent
                editMode: root.editMode
                allNodes: root.allNodes
                focusSpotId: root.focusSpotId
                tempEdgeFrom: root.tempEdgeFrom
                mapWidth: mapLayer.width
                mapHeight: mapLayer.height
                onNodeMoved: function(nodeId, newX, newY) {
                    root.nodeMoved(nodeId, newX, newY)
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
                spotsModel: root.spotsModel
                editMode: root.editMode
                focusSpotId: root.focusSpotId
                onSpotClicked: function(spot) {
                    root.popupSpot = spot
                    root.focusSpotId = spot.id
                }
            }
        }

        WheelHandler {
            target: mapLayer
            onWheel: function(event) {
                var next = mapLayer.scale + event.angleDelta.y / 1200
                mapLayer.scale = Math.max(0.35, Math.min(1.8, next))
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
}
