import QtQuick

Canvas {
    id: root
    property var pathPoints: []
    property var pathResults: []
    property bool animated: false
    property real animationProgress: 1
    property real lineWidth: 15
    property real borderWidth: 2
    property real vMarkSpacing: 200      // V 形标记间隔（像素）
    property real vMarkSize: 8         // V 形大小
    property real smoothAngleThreshold: 100

    antialiasing: true

    onPathPointsChanged: {
        requestPaint()
    }
    onPathResultsChanged: {
        requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (pathResults && pathResults.length > 0) {
            var basePoints = pathResults[0].points || []
            for (var i = pathResults.length - 1; i >= 1; i--) {
                drawPath(ctx, pathResults[i].points || [], "#7a4a00", "#f39c12", 10, false, i + 1, basePoints)
            }
            drawPath(ctx, basePoints, "#1a3a5c", "#3498db", lineWidth, true, "", [])
            return
        }

        drawPath(ctx, pathPoints || [], "#1a3a5c", "#3498db", lineWidth, true, "", [])
    }

    function drawPath(ctx, points, borderColor, pathColor, widthValue, showMarks, labelText, basePoints) {
        if (!points || points.length < 2) return

        var smoothPoints = generateAdaptiveSmoothPoints(points)
        if (smoothPoints.length < 2) return

        ctx.shadowBlur = 0
        ctx.lineWidth = widthValue + borderWidth * 2
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.strokeStyle = borderColor
        drawCurve(ctx, smoothPoints)
        ctx.stroke()

        ctx.lineWidth = widthValue
        ctx.strokeStyle = pathColor
        drawCurve(ctx, smoothPoints)
        ctx.stroke()

        if (showMarks) {
            drawVShapesAlongPath(ctx, smoothPoints)
        }

        if (labelText !== "") {
            drawPathLabel(ctx, points, smoothPoints, labelText, borderColor, pathColor, basePoints || [])
        }
    }

    function drawCurve(ctx, points) {
        if (points.length < 2) return
        ctx.beginPath()
        ctx.moveTo(points[0].x, points[0].y)
        for (var i = 1; i < points.length; i++) {
            ctx.lineTo(points[i].x, points[i].y)
        }
    }

    // 沿路径绘制 V 形标记
    function drawVShapesAlongPath(ctx, points) {
        if (points.length < 2) return

        var totalLength = 0
        var segments = []

        for (var i = 1; i < points.length; i++) {
            var dx = points[i].x - points[i-1].x
            var dy = points[i].y - points[i-1].y
            var segLen = Math.sqrt(dx*dx + dy*dy)
            segments.push({
                from: points[i-1],
                to: points[i],
                length: segLen,
                cumulative: totalLength,
                angle: Math.atan2(dy, dx)
            })
            totalLength += segLen
        }

        if (totalLength < vMarkSpacing) return

        // 每隔 vMarkSpacing 距离放置一个 V 形
        var distance = vMarkSpacing
        while (distance < totalLength) {
            var pos = findPositionAtDistance(segments, distance)
            if (pos) {
                drawVShape(ctx, pos.point, pos.angle)
            }
            distance += vMarkSpacing
        }
    }

    function findPositionAtDistance(segments, distance) {
        for (var i = 0; i < segments.length; i++) {
            var seg = segments[i]
            if (distance <= seg.cumulative + seg.length) {
                var t = (distance - seg.cumulative) / seg.length
                var x = seg.from.x + (seg.to.x - seg.from.x) * t
                var y = seg.from.y + (seg.to.y - seg.from.y) * t
                return { point: {x: x, y: y}, angle: seg.angle }
            }
        }
        return null
    }

    function pathSegments(points) {
        var totalLength = 0
        var segments = []
        for (var i = 1; i < points.length; i++) {
            var dx = points[i].x - points[i-1].x
            var dy = points[i].y - points[i-1].y
            var segLen = Math.sqrt(dx*dx + dy*dy)
            segments.push({
                from: points[i-1],
                to: points[i],
                length: segLen,
                cumulative: totalLength,
                angle: Math.atan2(dy, dx)
            })
            totalLength += segLen
        }
        return { totalLength: totalLength, segments: segments }
    }

    function drawPathLabel(ctx, originalPoints, smoothPoints, labelText, borderColor, fillColor, basePoints) {
        if (smoothPoints.length < 2) return

        var labelPoints = findDivergentSegmentPoints(originalPoints, basePoints)
        var points = labelPoints.length >= 2 ? labelPoints : smoothPoints
        var data = pathSegments(points)
        if (data.totalLength <= 0) return

        var pos = findPositionAtDistance(data.segments, data.totalLength * 0.5)
        if (!pos) return

        var radius = 18
        ctx.save()
        ctx.beginPath()
        ctx.arc(pos.point.x, pos.point.y, radius, 0, Math.PI * 2)
        ctx.fillStyle = fillColor
        ctx.fill()
        ctx.lineWidth = 4
        ctx.strokeStyle = borderColor
        ctx.stroke()

        ctx.fillStyle = "white"
        ctx.font = "bold 20px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(labelText, pos.point.x, pos.point.y + 1)
        ctx.restore()
    }

    function samePoint(a, b) {
        if (!a || !b) return false
        return Math.abs(a.x - b.x) < 0.001 && Math.abs(a.y - b.y) < 0.001
    }

    function hasSegment(points, fromPoint, toPoint) {
        for (var i = 1; i < points.length; i++) {
            var a = points[i - 1]
            var b = points[i]
            if ((samePoint(a, fromPoint) && samePoint(b, toPoint))
                    || (samePoint(a, toPoint) && samePoint(b, fromPoint))) {
                return true
            }
        }
        return false
    }

    function findDivergentSegmentPoints(points, basePoints) {
        if (!points || points.length < 2 || !basePoints || basePoints.length < 2) return []

        var best = []
        var current = []
        for (var i = 1; i < points.length; i++) {
            var fromPoint = points[i - 1]
            var toPoint = points[i]
            if (!hasSegment(basePoints, fromPoint, toPoint)) {
                if (current.length === 0) current.push(fromPoint)
                current.push(toPoint)
            } else {
                if (current.length > best.length) best = current
                current = []
            }
        }
        if (current.length > best.length) best = current
        return best
    }

    // 绘制 V 形（沿着前进方向开口向前）
    function drawVShape(ctx, point, angle) {
        var size = vMarkSize
        var x = point.x
        var y = point.y

        // 计算旋转后的 V 形顶点
        // 左臂终点
        var leftTipX = x + size * Math.cos(angle - Math.PI * 0.25)
        var leftTipY = y + size * Math.sin(angle - Math.PI * 0.25)
        // 右臂终点
        var rightTipX = x + size * Math.cos(angle + Math.PI * 0.25)
        var rightTipY = y + size * Math.sin(angle + Math.PI * 0.25)
        // V 的尖端（最前方）
        var frontX = x + size * 1.2 * Math.cos(angle)
        var frontY = y + size * 1.2 * Math.sin(angle)

        ctx.save()
        ctx.beginPath()
        ctx.moveTo(leftTipX, leftTipY)
        ctx.lineTo(frontX, frontY)
        ctx.lineTo(rightTipX, rightTipY)
        ctx.lineWidth = 4
        ctx.strokeStyle = "white"
        ctx.stroke()
        ctx.restore()
    }

    // 以下保持自适应平滑函数不变
    function generateAdaptiveSmoothPoints(origPoints, segmentsBetween = 6) {
        if (origPoints.length < 2) return origPoints.slice()
        if (origPoints.length === 2) return origPoints.slice()

        var result = []
        var angles = []

        for (var i = 1; i < origPoints.length - 1; i++) {
            var p0 = origPoints[i-1]
            var p1 = origPoints[i]
            var p2 = origPoints[i+1]
            var angle = calculateAngle(p0, p1, p2)
            angles.push(angle)
        }

        var segmentStart = 0
        for (var j = 0; j < angles.length; j++) {
            if (angles[j] < smoothAngleThreshold) {
                var segmentPoints = origPoints.slice(segmentStart, j+2)
                if (segmentPoints.length >= 2) {
                    var smoothed = smoothSegment(segmentPoints, segmentsBetween)
                    result = result.concat(smoothed)
                }
                result.push(origPoints[j+1])
                segmentStart = j+1
            }
        }
        if (segmentStart < origPoints.length - 1) {
            var lastSegment = origPoints.slice(segmentStart)
            if (lastSegment.length >= 2) {
                var lastSmoothed = smoothSegment(lastSegment, segmentsBetween)
                result = result.concat(lastSmoothed)
            } else if (lastSegment.length === 1) {
                result.push(lastSegment[0])
            }
        }

        var unique = []
        for (var k = 0; k < result.length; k++) {
            if (k === 0 || result[k].x !== result[k-1].x || result[k].y !== result[k-1].y) {
                unique.push(result[k])
            }
        }
        return unique
    }

    function smoothSegment(points, segmentsBetween) {
        if (points.length < 2) return points.slice()
        if (points.length === 2) return points.slice()
        var result = []
        for (var i = 0; i < points.length - 1; i++) {
            var p0 = points[Math.max(0, i-1)]
            var p1 = points[i]
            var p2 = points[i+1]
            var p3 = points[Math.min(points.length-1, i+2)]
            for (var t = 0; t <= segmentsBetween; t++) {
                var s = t / segmentsBetween
                var x = catmullRom(p0.x, p1.x, p2.x, p3.x, s)
                var y = catmullRom(p0.y, p1.y, p2.y, p3.y, s)
                result.push({x: x, y: y})
            }
        }
        result.push(points[points.length-1])
        return result
    }

    function catmullRom(p0, p1, p2, p3, t) {
        return 0.5 * ((2 * p1) +
                      (-p0 + p2) * t +
                      (2*p0 - 5*p1 + 4*p2 - p3) * t*t +
                      (-p0 + 3*p1 - 3*p2 + p3) * t*t*t)
    }

    function calculateAngle(p0, p1, p2) {
        var v1x = p0.x - p1.x
        var v1y = p0.y - p1.y
        var v2x = p2.x - p1.x
        var v2y = p2.y - p1.y
        var dot = v1x * v2x + v1y * v2y
        var len1 = Math.sqrt(v1x*v1x + v1y*v1y)
        var len2 = Math.sqrt(v2x*v2x + v2y*v2y)
        if (len1 === 0 || len2 === 0) return 180
        var rad = Math.acos(Math.min(1, Math.max(-1, dot / (len1 * len2))))
        return rad * 180 / Math.PI
    }
}
