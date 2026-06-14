import QtQuick

Item {
    id: root

    property var edges: []
    property var allNodes: []
    property bool editMode: false

    signal edgeRemoved(int fromId, int toId)

    onEdgesChanged: edgesCanvas.requestPaint()
    onAllNodesChanged: edgesCanvas.requestPaint()
    onEditModeChanged: edgesCanvas.requestPaint()

    Canvas {
        id: edgesCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            if (!root.editMode || !root.edges || root.edges.length === 0) return

            for (var i = 0; i < root.edges.length; i++) {
                var edge = root.edges[i]
                var fromNode = root.findNodeById(edge.from)
                var toNode = root.findNodeById(edge.to)
                if (!fromNode || !toNode) continue
                if (isNaN(fromNode.x) || isNaN(fromNode.y) || isNaN(toNode.x) || isNaN(toNode.y)) continue

                ctx.beginPath()
                ctx.moveTo(fromNode.x, fromNode.y)
                ctx.lineTo(toNode.x, toNode.y)
                ctx.lineWidth = 3
                ctx.strokeStyle = "#3498db"
                ctx.stroke()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.editMode
        hoverEnabled: true
        propagateComposedEvents: true

        onPressed: function(mouse) {
            var clickedEdge = root.findHoveredEdge(mouse.x, mouse.y)
            if (clickedEdge !== null) {
                root.edgeRemoved(clickedEdge.from, clickedEdge.to)
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
        }

        onPositionChanged: function(mouse) {
            cursorShape = root.findHoveredEdge(mouse.x, mouse.y) !== null
                ? Qt.PointingHandCursor
                : Qt.ArrowCursor
        }
    }

    function findNodeById(id) {
        for (var i = 0; i < root.allNodes.length; i++) {
            if (root.allNodes[i].id === id) return root.allNodes[i]
        }
        return null
    }

    function findHoveredEdge(mouseX, mouseY) {
        var threshold = 8
        for (var i = 0; i < root.edges.length; i++) {
            var edge = root.edges[i]
            var fromNode = findNodeById(edge.from)
            var toNode = findNodeById(edge.to)
            if (!fromNode || !toNode) continue

            var minX = Math.min(fromNode.x, toNode.x) - threshold
            var maxX = Math.max(fromNode.x, toNode.x) + threshold
            var minY = Math.min(fromNode.y, toNode.y) - threshold
            var maxY = Math.max(fromNode.y, toNode.y) + threshold
            if (mouseX < minX || mouseX > maxX || mouseY < minY || mouseY > maxY) continue

            if (pointToSegmentDistance(mouseX, mouseY, fromNode.x, fromNode.y, toNode.x, toNode.y) < threshold) {
                return edge
            }
        }
        return null
    }

    function pointToSegmentDistance(px, py, x1, y1, x2, y2) {
        var ax = px - x1
        var ay = py - y1
        var bx = x2 - x1
        var by = y2 - y1
        var len2 = bx * bx + by * by
        if (len2 === 0) return Math.hypot(ax, ay)

        var t = Math.max(0, Math.min(1, (ax * bx + ay * by) / len2))
        var projX = x1 + t * bx
        var projY = y1 + t * by
        return Math.hypot(px - projX, py - projY)
    }
}
