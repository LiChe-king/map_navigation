import QtQuick

Canvas {
    id: root
    property var pathPoints: []
    property bool animated: true
    property real animationProgress: 0

    SequentialAnimation on animationProgress {
        id: drawAnimation
        running: false
        NumberAnimation { from: 0; to: 1; duration: 800; easing.type: Easing.InOutCubic }
    }

    onPathPointsChanged: {
        if (animated && pathPoints.length >= 2) {
            animationProgress = 0
            drawAnimation.start()
        }
        requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (!pathPoints || pathPoints.length < 2) return

        var drawToIndex = animated ? Math.floor(animationProgress * pathPoints.length) : pathPoints.length
        if (drawToIndex < 2) return

        // 外发光效果（阴影）
        ctx.shadowBlur = 8
        ctx.shadowColor = "#ffcf33"

        // 底层粗线（光晕）
        ctx.lineWidth = 12
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.strokeStyle = "rgba(255, 207, 51, 0.35)"
        ctx.beginPath()
        ctx.moveTo(pathPoints[0].x, pathPoints[0].y)
        for (var i = 1; i < drawToIndex; i++) {
            ctx.lineTo(pathPoints[i].x, pathPoints[i].y)
        }
        ctx.stroke()

        // 主线条
        ctx.shadowBlur = 0
        ctx.lineWidth = 5
        ctx.strokeStyle = "#e67e22"
        ctx.beginPath()
        ctx.moveTo(pathPoints[0].x, pathPoints[0].y)
        for (var j = 1; j < drawToIndex; j++) {
            ctx.lineTo(pathPoints[j].x, pathPoints[j].y)
        }
        ctx.stroke()

        // 路径点标记（小圆点）
        if (drawToIndex === pathPoints.length) {
            ctx.fillStyle = "#e67e22"
            for (var k = 0; k < pathPoints.length; k++) {
                ctx.beginPath()
                ctx.arc(pathPoints[k].x, pathPoints[k].y, 4, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }
}