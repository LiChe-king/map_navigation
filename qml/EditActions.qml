import QtQml

QtObject {
    id: root

    property var app: null
    property var backend: null
    property var workspace: null
    property var editorPanel: null

    function moveNode(nodeId, newX, newY) {
        if (backend.isSpotNode(nodeId)) {
            var spot = backend.spotDetailByNode(nodeId)
            if (spot.id) {
                backend.updateSpotOnly(spot.id, spot.name, spot.type, spot.intro, newX, newY)
            }
        } else {
            backend.updateNodeOnly(nodeId, newX, newY)
        }
        workspace.refreshGraph()
        app.hasUnsavedChanges = true
    }

    function saveChanges() {
        backend.save()
        app.hasUnsavedChanges = false
    }

    function updateSpotName(nodeId, newName) {
        var spot = backend.spotDetailByNode(nodeId)
        if (!spot.id) return

        backend.updateSpotOnly(spot.id, newName, spot.type, spot.intro, spot.x, spot.y)
        if (app.selectedNode) app.selectedNode.name = newName
        workspace.refreshGraph()
        app.hasUnsavedChanges = true
    }

    function updateSpotInfo(nodeId, newName, newType, newIntro) {
        var spot = backend.spotDetailByNode(nodeId)
        if (!spot.id) return

        backend.updateSpotOnly(spot.id, newName, newType, newIntro, spot.x, spot.y)
        app.selectedNode = {
            id: nodeId,
            isSpot: true,
            spotId: spot.id,
            nodeId: spot.nodeId,
            name: newName,
            type: newType,
            intro: newIntro,
            x: spot.x,
            y: spot.y
        }
        workspace.refreshGraph()
        app.hasUnsavedChanges = true
    }

    function addRoadNode() {
        addRoadNodeAt(
            workspace.width / 2 / (workspace.mapLayerScale || 1),
            workspace.height / 2 / (workspace.mapLayerScale || 1)
        )
    }

    function addRoadNodeAt(x, y) {
        var newNodeId = nextRoadNodeId()
        if (!backend.addNodeOnly(newNodeId, x, y)) return

        if (app.editToolMode === "drawRoad" && app.roadTailId !== -1 && app.roadTailId !== newNodeId) {
            backend.addEdgeOnly(app.roadTailId, newNodeId)
        }

        app.roadTailId = app.editToolMode === "drawRoad" ? newNodeId : -1
        app.selectedNode = { id: newNodeId, x: x, y: y }
        workspace.refreshGraph()
        app.hasUnsavedChanges = true
    }

    function continueRoadAtNode(nodeId) {
        if (app.roadTailId !== -1 && app.roadTailId !== nodeId) {
            backend.addEdgeOnly(app.roadTailId, nodeId)
            workspace.refreshGraph()
            app.hasUnsavedChanges = true
        }
        app.roadTailId = nodeId
        app.tempEdgeFrom = nodeId
    }

    function addSpotAt(x, y) {
        var newSpotId = nextSpotId()
        if (newSpotId < 1) return
        var name = editorPanel.nextSpotName()
        var type = editorPanel.nextSpotType()
        var intro = editorPanel.nextSpotIntro()

        if (!backend.addSpotOnly(newSpotId, name, type, intro, x, y)) return

        app.selectedNode = {
            id: newSpotId,
            isSpot: true,
            spotId: newSpotId,
            nodeId: newSpotId,
            name: name,
            type: type,
            intro: intro,
            x: x,
            y: y
        }
        app.currentFocusSpotId = newSpotId
        workspace.refreshGraph()
        app.hasUnsavedChanges = true
    }

    function deleteSelectedNode(nodeId) {
        if (backend.isSpotNode(nodeId)) {
            var spot = backend.spotDetailByNode(nodeId)
            if (!spot.id) return
            backend.removeSpotOnly(spot.id)
            if (app.currentFocusSpotId === spot.id) app.currentFocusSpotId = -1
            if (app.currentPopupSpot && app.currentPopupSpot.id === spot.id) app.currentPopupSpot = ({})
        } else {
            backend.removeNodeOnly(nodeId)
        }

        if (app.roadTailId === nodeId) app.roadTailId = -1
        if (app.tempEdgeFrom === nodeId) app.tempEdgeFrom = -1
        app.selectedNode = null
        workspace.refreshGraph()
        app.hasUnsavedChanges = true
    }

    function nextRoadNodeId() {
        var maxId = 1000
        var nodes = backend.nodes
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].id > maxId) maxId = nodes[i].id
        }
        return Math.max(maxId + 1, 1000)
    }

    function nextSpotId() {
        var used = {}
        var spots = backend.spots
        for (var i = 0; i < spots.length; i++) {
            if (spots[i].id > 0 && spots[i].id < 1000) used[spots[i].id] = true
        }

        for (var id = 1; id < 1000; id++) {
            if (!used[id]) return id
        }
        return -1
    }
}
