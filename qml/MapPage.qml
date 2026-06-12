import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

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

    // 编辑模式信号
    signal nodeMoved(int nodeId, double newX, double newY)
    signal edgeAdded(int fromId, int toId)
    signal edgeRemoved(int fromId, int toId)
    signal nodeSelected(int nodeId)
    signal tempEdgeChanged(var fromId)

    // 按 Esc 取消连线
    focus: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape && root.tempEdgeFrom !== -1) {
            root.tempEdgeFrom = -1
            root.tempEdgeChanged(-1)
            event.accepted = true
        }
    }

    // 监听变化，重绘边
    onEdgesChanged: {
        if (edgesCanvas) edgesCanvas.requestPaint()
    }
    onAllNodesChanged: {
        if (edgesCanvas) edgesCanvas.requestPaint()
    }
    onEditModeChanged: {
        if (edgesCanvas) edgesCanvas.requestPaint()
        if (!root.editMode) {
            root.tempEdgeFrom = -1
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

            // ========== 编辑模式：绘制所有边（纯 Canvas，无拦截） ==========
            Canvas {
                id: edgesCanvas
                anchors.fill: parent
                visible: true  // 始终可见，但只在 editMode 时有数据
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    
                    if (!root.editMode) return
                    if (!root.edges || root.edges.length === 0) return
                    
                    for (var i = 0; i < root.edges.length; i++) {
                        var edge = root.edges[i]
                        var fromNode = findNodeById(edge.from)
                        var toNode = findNodeById(edge.to)
                        
                        if (fromNode && toNode && 
                            !isNaN(fromNode.x) && !isNaN(fromNode.y) &&
                            !isNaN(toNode.x) && !isNaN(toNode.y)) {
                            
                            ctx.beginPath()
                            ctx.moveTo(fromNode.x, fromNode.y)
                            ctx.lineTo(toNode.x, toNode.y)
                            ctx.lineWidth = 3
                            ctx.strokeStyle = "#3498db"
                            ctx.stroke()
                        }
                    }
                }
            }
            
            // 边的点击检测（独立的 MouseArea，通过 propagateComposedEvents 让节点也能收到事件）
            MouseArea {
                id: edgeClickArea
                anchors.fill: parent
                visible: root.editMode
                hoverEnabled: true
                propagateComposedEvents: true  // 关键：让事件透传
                
                onPressed: function(mouse) {
                    var clickedEdge = findHoveredEdge(mouse.x, mouse.y)
                    if (clickedEdge !== null) {
                        root.edgeRemoved(clickedEdge.from, clickedEdge.to)
                        mouse.accepted = true
                    } else {
                        mouse.accepted = false  // 未点到边，交给下层节点
                    }
                }
                
                onPositionChanged: function(mouse) {
                    var hovered = findHoveredEdge(mouse.x, mouse.y)
                    if (hovered !== null) {
                        cursorShape = Qt.PointingHandCursor
                        // 可选：高亮边（为了性能暂时不重绘整个 Canvas）
                    } else {
                        if (cursorShape !== Qt.ArrowCursor)
                            cursorShape = Qt.ArrowCursor
                    }
                }
            }

            // ========== 编辑模式：绘制所有节点 ==========
            Repeater {
                id: nodesRepeater
                model: root.editMode ? root.allNodes : []
                delegate: Item {
                    id: nodeDelegate
                    x: modelData.x - 16
                    y: modelData.y - 16
                    width: 32
                    height: 32
                    z: 10
                    property bool isSpot: modelData.id < 1000
                    property int nodeId: modelData.id
                    
                    Rectangle {
                        id: nodeRect
                        anchors.fill: parent
                        radius: 16
                        color: {
                            if (isSpot) {
                                return modelData.id === (root.focusSpotId !== -1 ? root.focusSpotId : -1) ? "#ffcf33" : "#de4d3f"
                            }
                            return "#bdc3c7"
                        }
                        border.color: root.tempEdgeFrom === modelData.id ? "#e67e22" : "white"
                        border.width: root.tempEdgeFrom === modelData.id ? 3 : 2
                        
                        Text {
                            anchors.centerIn: parent
                            text: isSpot ? String(modelData.id) : "●"
                            font.pixelSize: isSpot ? 12 : 10
                            color: "white"
                        }
                    }
                    
                    MouseArea {
                        id: nodeDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.DragMoveCursor
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: mapLayer.width - parent.width
                        drag.minimumY: 0
                        drag.maximumY: mapLayer.height - parent.height
                        z: 11
                        
                        onReleased: {
                            if (root.editMode && modelData) {
                                var newX = parent.x + 16
                                var newY = parent.y + 16
                                root.nodeMoved(modelData.id, newX, newY)
                            }
                        }
                        
                        onClicked: function(mouse) {
                            console.log("节点点击:", modelData.id, "tempEdgeFrom:", root.tempEdgeFrom)
                            
                            if (!root.editMode) {
                                root.nodeSelected(modelData.id)
                                return
                            }
                            
                            if (mouse.modifiers & Qt.ControlModifier) {
                                if (root.tempEdgeFrom === -1) {
                                    root.tempEdgeFrom = modelData.id
                                    root.tempEdgeChanged(modelData.id)
                                } else {
                                    if (root.tempEdgeFrom !== modelData.id) {
                                        root.edgeAdded(root.tempEdgeFrom, modelData.id)
                                    }
                                    root.tempEdgeFrom = -1
                                    root.tempEdgeChanged(-1)
                                }
                                mouse.accepted = true
                            } else {
                                root.nodeSelected(modelData.id)
                                root.focusSpotId = modelData.id
                                mouse.accepted = true
                            }
                        }
                        
                        ToolTip {
                            visible: nodeDragArea.containsMouse && root.editMode
                            text: root.tempEdgeFrom === modelData.id ? "连线中... 点击另一节点完成连线" : "拖拽移动 | Ctrl+点击连线"
                            delay: 400
                        }
                    }
                }
            }

            // ========== 临时连线 ==========
            Canvas {
                id: tempLineCanvas
                anchors.fill: parent
                visible: root.editMode && root.tempEdgeFrom !== -1
                z: 5
                
                property var fromNode: findNodeById(root.tempEdgeFrom)
                property real tempMouseX: 0
                property real tempMouseY: 0
                
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (!fromNode || isNaN(fromNode.x) || isNaN(fromNode.y)) return
                    ctx.beginPath()
                    ctx.moveTo(fromNode.x, fromNode.y)
                    ctx.lineTo(tempMouseX, tempMouseY)
                    ctx.strokeStyle = "#e67e22"
                    ctx.lineWidth = 3
                    ctx.setLineDash([8, 6])
                    ctx.stroke()
                }
                
                MouseArea {
                    anchors.fill: parent
                    onPositionChanged: function(mouse) {
                        tempLineCanvas.tempMouseX = mouse.x
                        tempLineCanvas.tempMouseY = mouse.y
                        tempLineCanvas.requestPaint()
                    }
                }
            }

            // ========== 景点标记（编辑模式也显示，但半透明便于区分） ==========
            Repeater {
                model: root.spotsModel
                z: 1

                Item {
                    id: markerContainer
                    x: modelData.x - (markerRect.width / 2)
                    y: modelData.y - markerRect.height - 6
                    opacity: root.editMode ? 0.6 : 1.0

                    property int textWidth: markerText.implicitWidth + 32

                    Rectangle {
                        id: markerRect
                        width: markerContainer.textWidth - 10
                        height: 40
                        radius: 15
                        color: "#ffffff"
                        border.color: modelData.id === root.focusSpotId ? "#ffcf33" : "#d0d5cc"
                        border.width: 1.5

                        layer.enabled: true
                        layer.effect: DropShadow {
                            horizontalOffset: -5
                            verticalOffset: 5
                            radius: 10
                            samples: 8
                            color: "#30000000"
                        }

                        Text {
                            id: markerText
                            anchors.centerIn: parent
                            text: modelData.name
                            font.pixelSize: 30
                            font.bold: false
                            font.family: "字魂扁桃体"
                            color: getTextColor(modelData.type)
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        anchors.fill: markerRect
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.editMode  // 编辑模式下不可点击景点标记，避免干扰
                        onClicked: {
                            root.popupSpot = modelData
                            root.focusSpotId = modelData.id
                        }
                    }

                    ToolTip {
                        visible: markerMouseArea.containsMouse && !root.editMode
                        text: modelData.name + " (" + modelData.type + ")"
                        delay: 400
                    }
                    MouseArea {
                        id: markerMouseArea
                        anchors.fill: markerRect
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
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

    // 景点信息浮窗（保持不变）
    Popup {
        id: infoPopup
        x: parent.width - 360
        y: 24
        width: 320
        modal: false
        visible: root.popupSpot && root.popupSpot.name ? true : false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        z: 20

        background: Rectangle {
            color: "#ffffff"
            radius: 16
            border.color: "#e0e5dc"
            border.width: 1
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                samples: 16
                color: "#30000000"
            }
        }

        Column {
            spacing: 8
            width: parent.width
            padding: 16

            Label {
                text: root.popupSpot.name || ""
                font.pixelSize: 20
                font.bold: true
                color: getTextColor(root.popupSpot.type)
            }
            Label {
                text: root.popupSpot.type || ""
                color: "#8f9b8a"
                font.pixelSize: 14
            }
            Label {
                width: parent.width
                text: root.popupSpot.intro || ""
                wrapMode: Text.WordWrap
                color: "#555"
                font.pixelSize: 13
            }
        }
    }
    
    // ========== 辅助函数 ==========
    function findNodeById(id) {
        for (var i = 0; i < root.allNodes.length; i++) {
            if (root.allNodes[i].id === id) return root.allNodes[i]
        }
        return null
    }

    function jumpToSpot(spotX, spotY) {
        var targetX = spotX * mapLayer.scale - flickable.width / 2
        var targetY = spotY * mapLayer.scale - flickable.height / 2
        targetX = Math.max(0, Math.min(targetX, flickable.contentWidth - flickable.width))
        targetY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height))
        flickable.contentX = targetX
        flickable.contentY = targetY
    }
    
    function getTextColor(type) {
        switch(type) {
            case "校门":     return "#4c84e1"
            case "餐饮食堂": return "#5f80b4"
            case "公共教学楼": return "#16a085"
            case "学院专业楼": return "#9b59b6"
            case "体育场地": return "#27ae60"
            case "宿舍":     return "#1abc9c"
            case "图书馆":   return "#3498db"
            case "诊所":     return "#e74c3c"
            case "景点":     return "#69806e"
            case "活动场地": return "#f1c40f"
            default:         return "#69806e"
        }
    }
    
    // 边悬停检测（优化版）
    function findHoveredEdge(mouseX, mouseY) {
        var threshold = 8
        for (var i = 0; i < root.edges.length; i++) {
            var edge = root.edges[i]
            var fromNode = findNodeById(edge.from)
            var toNode = findNodeById(edge.to)
            if (!fromNode || !toNode) continue
            // 快速包围盒
            var minX = Math.min(fromNode.x, toNode.x) - threshold
            var maxX = Math.max(fromNode.x, toNode.x) + threshold
            var minY = Math.min(fromNode.y, toNode.y) - threshold
            var maxY = Math.max(fromNode.y, toNode.y) + threshold
            if (mouseX < minX || mouseX > maxX || mouseY < minY || mouseY > maxY) continue
            var dist = pointToSegmentDistance(mouseX, mouseY, fromNode.x, fromNode.y, toNode.x, toNode.y)
            if (dist < threshold) return edge
        }
        return null
    }
    
    function pointToSegmentDistance(px, py, x1, y1, x2, y2) {
        var ax = px - x1, ay = py - y1
        var bx = x2 - x1, by = y2 - y1
        var dot = ax * bx + ay * by
        var len2 = bx * bx + by * by
        if (len2 === 0) return Math.hypot(ax, ay)
        var t = Math.max(0, Math.min(1, dot / len2))
        var projX = x1 + t * bx, projY = y1 + t * by
        return Math.hypot(px - projX, py - projY)
    }
}