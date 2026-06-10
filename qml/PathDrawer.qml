import QtQuick

Canvas {
    id: root
    property var pathPoints: []

    onPathPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (!pathPoints || pathPoints.length < 2) {
            return
        }

        ctx.lineWidth = 9
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.strokeStyle = "rgba(255, 207, 51, 0.55)"
        ctx.beginPath()
        ctx.moveTo(pathPoints[0].x, pathPoints[0].y)
        for (var i = 1; i < pathPoints.length; ++i) {
            ctx.lineTo(pathPoints[i].x, pathPoints[i].y)
        }
        ctx.stroke()

        ctx.lineWidth = 4
        ctx.strokeStyle = "#d6332a"
        ctx.beginPath()
        ctx.moveTo(pathPoints[0].x, pathPoints[0].y)
        for (var j = 1; j < pathPoints.length; ++j) {
            ctx.lineTo(pathPoints[j].x, pathPoints[j].y)
        }
        ctx.stroke()
    }
}

