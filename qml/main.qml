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
    property string editToolMode: "select"
    property var selectedNode: null
    property int tempEdgeFrom: -1
    property int roadTailId: -1
    property bool hasUnsavedChanges: false

    EditActions {
        id: editActions
        app: window
        backend: campusBackend
        workspace: mapWorkspace
        editorPanel: editorPanel
    }

    MapWorkspace {
        id: mapWorkspace
        anchors.fill: parent
        backend: campusBackend
        pathResult: window.currentPathResult
        focusSpotId: window.currentFocusSpotId
        popupSpot: window.currentPopupSpot
        editMode: window.editMode
        editTool: window.editToolMode
        tempEdgeFrom: window.tempEdgeFrom
        pickingMode: window.pickingMode
        originalMenu: window.originalMenu

        onNodeMoved: function(nodeId, newX, newY) {
            editActions.moveNode(nodeId, newX, newY)
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
            if (window.editToolMode === "drawRoad" && node) {
                editActions.continueRoadAtNode(node.id)
            }
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
        onMapPickCanceled: function(menuName) {
            window.pickingMode = ""
            navigationPopups.reopen(menuName)
            window.originalMenu = ""
        }
        onEditMapClicked: function(mapX, mapY) {
            if (window.editToolMode === "drawRoad") {
                editActions.addRoadNodeAt(mapX, mapY)
            } else if (window.editToolMode === "addSpot") {
                editActions.addSpotAt(mapX, mapY)
            }
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
        x: window.width - width - 20
        y: 20
        editMode: window.editMode
        hasUnsavedChanges: window.hasUnsavedChanges
        selectedNode: window.selectedNode
        toolMode: window.editToolMode
        z: 200

        onSaveRequested: editActions.saveChanges()
        onUndoRequested: {
            campusBackend.load()
            window.hasUnsavedChanges = false
            mapWorkspace.refreshGraph()
        }
        onRefreshRequested: mapWorkspace.refreshGraph()
        onToolModeRequested: function(mode) {
            window.editToolMode = mode
            window.tempEdgeFrom = -1
            if (mode !== "drawRoad") {
                window.roadTailId = -1
            }
        }
        onUpdateSpotName: function(nodeId, newName) {
            editActions.updateSpotName(nodeId, newName)
        }
        onUpdateSpotInfo: function(nodeId, newName, newType, newIntro) {
            editActions.updateSpotInfo(nodeId, newName, newType, newIntro)
        }
        onDeleteSelectedRequested: function(nodeId) {
            editActions.deleteSelectedNode(nodeId)
        }
        onAddNodeRequested: editActions.addRoadNode()
        onRoadDrawResetRequested: {
            window.roadTailId = -1
            window.tempEdgeFrom = -1
        }
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
            window.roadTailId = -1
            if (window.hasUnsavedChanges) editActions.saveChanges()
        } else {
            navigationPopups.closeAll()
            window.editMode = true
        }
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
