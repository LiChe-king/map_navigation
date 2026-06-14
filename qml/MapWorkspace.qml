import QtQuick

Item {
    id: root

    property var backend: null
    property var pathResult: ({})
    property int focusSpotId: -1
    property var popupSpot: ({})
    property bool editMode: false
    property string editTool: "select"
    property int tempEdgeFrom: -1
    property string pickingMode: ""
    property string originalMenu: ""
    property real mapLayerScale: mapPage.mapLayerScale

    signal nodeMoved(int nodeId, double newX, double newY)
    signal nodePreviewMoved(int nodeId, double newX, double newY)
    signal edgeAdded(int fromId, int toId)
    signal edgeRemoved(int fromId, int toId)
    signal nodeSelected(var node)
    signal tempEdgeChanged(var fromId)
    signal spotPicked(string mode, string spotName, string originalMenu)
    signal mapPickCanceled(string originalMenu)
    signal editMapClicked(double mapX, double mapY)

    MapPage {
        id: mapPage
        anchors.fill: parent
        spotsModel: root.backend ? root.backend.spots : []
        pathResult: root.pathResult
        focusSpotId: root.focusSpotId
        popupSpot: root.popupSpot
        editMode: root.editMode
        editTool: root.editTool
        allNodes: root.getAllNodesData()
        edges: root.getAllEdgesData()
        tempEdgeFrom: root.tempEdgeFrom

        onNodeMoved: function(nodeId, newX, newY) {
            root.nodeMoved(nodeId, newX, newY)
        }
        onNodePreviewMoved: function(nodeId, newX, newY) {
            root.nodePreviewMoved(nodeId, newX, newY)
        }
        onEdgeAdded: function(fromId, toId) {
            root.edgeAdded(fromId, toId)
        }
        onEdgeRemoved: function(fromId, toId) {
            root.edgeRemoved(fromId, toId)
        }
        onNodeSelected: function(nodeId) {
            root.nodeSelected(root.findNodeById(nodeId))
        }
        onTempEdgeChanged: function(fromId) {
            root.tempEdgeChanged(fromId)
        }
        onMapClicked: function(mapX, mapY) {
            root.editMapClicked(mapX, mapY)
        }
    }

    MouseArea {
        id: mapPickArea
        anchors.fill: parent
        enabled: !root.editMode && root.pickingMode !== ""
        cursorShape: Qt.CrossCursor
        z: 100

        onEnabledChanged: {
            if (!enabled) {
                cursorShape = Qt.ArrowCursor
            } else {
                cursorShape = Qt.CrossCursor
            }
        }

        onClicked: function(mouse) {
            if (!root.backend) {
                root.mapPickCanceled(root.originalMenu)
                return
            }

            var scenePos = mapPage.viewportToMap(mouse.x, mouse.y)
            var nearest = root.findNearestSpot(scenePos.x, scenePos.y)
            if (nearest.id !== -1) {
                root.spotPicked(root.pickingMode, nearest.name, root.originalMenu)
            } else {
                root.mapPickCanceled(root.originalMenu)
            }
        }
    }

    function refreshGraph() {
        mapPage.allNodes = getAllNodesData()
        mapPage.edges = getAllEdgesData()
    }

    function jumpToSpot(spotX, spotY) {
        mapPage.jumpToSpot(spotX, spotY)
    }

    function getAllNodesData() {
        var nodes = []
        if (!root.backend) return nodes

        for (var i = 0; i < root.backend.spots.length; i++) {
            nodes.push(JSON.parse(JSON.stringify(root.backend.spots[i])))
        }
        for (var j = 0; j < root.backend.nodes.length; j++) {
            nodes.push(JSON.parse(JSON.stringify(root.backend.nodes[j])))
        }
        return nodes
    }

    function getAllEdgesData() {
        return root.backend ? (root.backend.edges || []) : []
    }

    function findNodeById(id) {
        var nodes = getAllNodesData()
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].id === id) return nodes[i]
        }
        return null
    }

    function findNearestSpot(x, y) {
        var spots = root.backend ? root.backend.spots : []
        var nearestId = -1
        var nearestName = ""
        var minDist = 40

        for (var i = 0; i < spots.length; i++) {
            var dx = spots[i].x - x
            var dy = spots[i].y - y
            var dist = Math.sqrt(dx * dx + dy * dy)
            if (dist < minDist) {
                minDist = dist
                nearestId = spots[i].id
                nearestName = spots[i].name
            }
        }

        return { id: nearestId, name: nearestName }
    }
}
