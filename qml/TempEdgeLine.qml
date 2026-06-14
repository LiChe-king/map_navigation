import QtQuick

Canvas {
    id: root

    property bool editMode: false
    property int tempEdgeFrom: -1
    property var allNodes: []
    property real tempMouseX: 0
    property real tempMouseY: 0

    visible: root.editMode && root.tempEdgeFrom !== -1
    z: 5

    onTempEdgeFromChanged: requestPaint()
    onAllNodesChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var fromNode = findNodeById(root.tempEdgeFrom)
        if (!fromNode || isNaN(fromNode.x) || isNaN(fromNode.y)) return

        ctx.beginPath()
        ctx.moveTo(fromNode.x, fromNode.y)
        ctx.lineTo(root.tempMouseX, root.tempMouseY)
        ctx.strokeStyle = "#e67e22"
        ctx.lineWidth = 3
        ctx.setLineDash([8, 6])
        ctx.stroke()
    }

    MouseArea {
        anchors.fill: parent
        onPositionChanged: function(mouse) {
            root.tempMouseX = mouse.x
            root.tempMouseY = mouse.y
            root.requestPaint()
        }
    }

    function findNodeById(id) {
        for (var i = 0; i < root.allNodes.length; i++) {
            if (root.allNodes[i].id === id) return root.allNodes[i]
        }
        return null
    }
}
