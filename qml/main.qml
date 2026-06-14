import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window

    width: 1280
    height: 820
    visible: true
    title: "广西大学校园导游系统"
    color: "#e8efe4"

    property string pickingMode: ""
    property string originalMenu: ""
    property var currentPathResult: ({})
    property int currentFocusSpotId: -1
    property var currentPopupSpot: ({})
    property bool editMode: false
    property var selectedNode: null
    property int tempEdgeFrom: -1
    property bool hasUnsavedChanges: false

    MapWorkspace {
        id: mapWorkspace
        anchors.fill: parent
        backend: campusBackend
        pathResult: window.currentPathResult
        focusSpotId: window.currentFocusSpotId
        popupSpot: window.currentPopupSpot
        editMode: window.editMode
        tempEdgeFrom: window.tempEdgeFrom
        pickingMode: window.pickingMode
        originalMenu: window.originalMenu

        onNodeMoved: function(nodeId, newX, newY) {
            if (nodeId < 1000) {
                var spot = campusBackend.spotDetail(nodeId)
                if (spot.id) {
                    campusBackend.updateSpotOnly(nodeId, spot.name, spot.type, spot.intro, newX, newY)
                }
            } else {
                campusBackend.updateNodeOnly(nodeId, newX, newY)
            }
            window.hasUnsavedChanges = true
        }
        onEdgeAdded: function(fromId, toId) {
            campusBackend.addEdgeOnly(fromId, toId)
            mapWorkspace.refreshGraph()
            window.hasUnsavedChanges = true
        }
        onEdgeRemoved: function(fromId, toId) {
            campusBackend.removeEdgeOnly(fromId, toId)
            mapWorkspace.refreshGraph()
            window.hasUnsavedChanges = true
        }
        onNodeSelected: function(node) {
            window.selectedNode = node
        }
        onTempEdgeChanged: function(fromId) {
            window.tempEdgeFrom = (fromId !== undefined && fromId !== -1) ? fromId : -1
        }
        onSpotPicked: function(mode, spotName, menuName) {
            navigationPopups.setPickedSpot(mode, spotName)
            window.pickingMode = ""
            navigationPopups.reopen(menuName)
            window.originalMenu = ""
        }
    }

    CustomMenuBar {
        id: menuBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        editMode: window.editMode

        onQueryClicked: {
            if (window.editMode) window.editMode = false
            navigationPopups.openPopup("query")
        }
        onPathClicked: {
            if (window.editMode) window.editMode = false
            navigationPopups.openPopup("path")
        }
        onNearbyClicked: {
            if (window.editMode) window.editMode = false
            navigationPopups.openPopup("nearby")
        }
        onAdminClicked: window.toggleEditMode()
    }

    EditorPanel {
        id: editorPanel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        editMode: window.editMode
        hasUnsavedChanges: window.hasUnsavedChanges
        selectedNode: window.selectedNode
        mapLayerScale: mapWorkspace.mapLayerScale
        z: 200

        onSaveRequested: window.saveChanges()
        onUndoRequested: {
            campusBackend.load()
            window.hasUnsavedChanges = false
            mapWorkspace.refreshGraph()
        }
        onRefreshRequested: mapWorkspace.refreshGraph()
        onUpdateSpotName: function(nodeId, newName) {
            window.updateSpotName(nodeId, newName)
        }
        onDeleteNodeRequested: function(nodeId) {
            campusBackend.removeNodeOnly(nodeId)
            window.selectedNode = null
            mapWorkspace.refreshGraph()
            window.hasUnsavedChanges = true
        }
        onAddNodeRequested: window.addRoadNode()
    }

    NavigationPopups {
        id: navigationPopups
        popupX: menuBar.x
        popupY: menuBar.y + menuBar.height + 10
        spotsModel: campusBackend.spots
        backend: campusBackend
        getSpotIdByNameFn: window.getSpotIdByName

        onSpotSelected: function(spot) {
            window.currentPopupSpot = spot
            window.currentFocusSpotId = spot.id
            mapWorkspace.jumpToSpot(spot.x, spot.y)
        }
        onPathCalculated: function(result) {
            window.currentPathResult = result
        }
        onMapPickRequested: function(mode, menuName) {
            window.pickingMode = mode
            window.originalMenu = menuName
        }
    }

    function toggleEditMode() {
        if (window.editMode) {
            window.editMode = false
            window.selectedNode = null
            window.tempEdgeFrom = -1
            if (window.hasUnsavedChanges) saveChanges()
        } else {
            navigationPopups.closeAll()
            window.editMode = true
        }
    }

    function saveChanges() {
        campusBackend.save()
        window.hasUnsavedChanges = false
    }

    function updateSpotName(nodeId, newName) {
        var spot = campusBackend.spotDetail(nodeId)
        if (!spot.id) return

        campusBackend.updateSpotOnly(nodeId, newName, spot.type, spot.intro, spot.x, spot.y)
        if (window.selectedNode) window.selectedNode.name = newName
        mapWorkspace.refreshGraph()
        window.hasUnsavedChanges = true
    }

    function addRoadNode() {
        var maxId = 1000
        var nodes = campusBackend.nodes
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].id > maxId) maxId = nodes[i].id
        }

        var newNodeId = Math.max(maxId + 1, 1000)
        var centerX = mapWorkspace.width / 2 / (mapWorkspace.mapLayerScale || 1)
        var centerY = mapWorkspace.height / 2 / (mapWorkspace.mapLayerScale || 1)
        campusBackend.addNodeOnly(newNodeId, centerX, centerY)
        mapWorkspace.refreshGraph()
        window.hasUnsavedChanges = true
    }

    function getSpotIdByName(name) {
        var spots = campusBackend.spots
        for (var i = 0; i < spots.length; i++) {
            if (spots[i].name === name || (spots[i].id + " " + spots[i].name) === name) {
                return spots[i].id
            }
        }

        var num = parseInt(name)
        return isNaN(num) ? 1 : num
    }
}
