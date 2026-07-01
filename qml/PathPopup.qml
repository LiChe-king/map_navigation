import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

DraggablePopup {
    id: root

    property var spotsModel: []
    property var backend: null
    property var getSpotIdByNameFn: null
    property bool editMode: false
    readonly property int formMargin: 12

    // 存储所有路径结果（由后端返回，包含最短路径 + 可选路径）
    property var allPathResults: []
    // 当前显示的路径索引列表（-1 表示最短路径，1,2,3 表示可选路径）
    property var visiblePathIndices: [-1]
    // 路径颜色列表（用于可选路径）
    property var pathColors: ["#3498db", "#e67e22", "#27ae60", "#8e44ad"]

    signal pathCalculated(var result)
    signal mapPickRequested(string mode)
    signal closeRequested()

    width: 380
    height: 600
    titleText: "最短路径"

    onClosed: {
        if (!editMode) {
            closeRequested()
        }
    }

    // ---------- 核心函数 ----------
    function clearAllPaths() {
        allPathResults = []
        visiblePathIndices = []
        pathResultText.text = ""
        // 发送完全空的数据，包括 points
        root.pathCalculated({ paths: [], points: [], length: 0, names: [] })
    }

    function togglePath(index) {
        var idx = visiblePathIndices.indexOf(index)
        if (idx >= 0) {
            visiblePathIndices.splice(idx, 1)
        } else {
            visiblePathIndices.push(index)
        }
        updatePathDisplay()
        updatePathButtons()
        updateLegend()
    }

    function toggleShortestPath() {
        var idx = visiblePathIndices.indexOf(-1)
        if (idx >= 0) {
            visiblePathIndices.splice(idx, 1)
        } else {
            visiblePathIndices.push(-1)
        }
        updatePathDisplay()
        updatePathButtons()
        updateLegend()
    }

    function updatePathDisplay() {
        // 如果没有路径数据，清空显示
        if (!allPathResults || allPathResults.length === 0) {
            pathResultText.text = ""
            root.pathCalculated({ paths: [], points: [], length: 0, names: [] })
            updatePathButtons()
            updateLegend()
            return
        }

        var shortest = allPathResults[0]
        if (!shortest || !shortest.names || shortest.names.length === 0) {
            pathResultText.text = "未找到可达路径"
            root.pathCalculated({ paths: [], points: [], length: 0, names: [] })
            return
        }

        // 构建文本
        var text = ""
        text += "最短路径：\n"
        text += shortest.names.join(" → ") + "\n"
        text += "总距离：" + (shortest.length || shortest.totalLength || 0) + " 米\n"

        if (allPathResults.length > 1) {
            text += "\n其他可选路径：\n"
            for (var i = 1; i < allPathResults.length; i++) {
                var path = allPathResults[i]
                var pathNames = path.names || []
                if (pathNames.length === 0) continue
                text += (i) + ". " + pathNames.join(" → ") + "\n"
                text += "   距离：" + (path.length || path.totalLength || 0) + " 米\n"
            }
        }
        pathResultText.text = text

        // 构建地图绘制数据（只包含可见路径）
        var pathsToShow = []
        // 最短路径
        if (visiblePathIndices.indexOf(-1) >= 0) {
            var shortestCopy = {}
            for (var key in shortest) {
                shortestCopy[key] = shortest[key]
            }
            shortestCopy.color = pathColors[0]
            pathsToShow.push(shortestCopy)
        }
        // 可选路径
        for (var i = 0; i < visiblePathIndices.length; i++) {
            var idx = visiblePathIndices[i]
            if (idx > 0 && idx < allPathResults.length) {
                var pathCopy = {}
                for (var key in allPathResults[idx]) {
                    pathCopy[key] = allPathResults[idx][key]
                }
                pathCopy.color = pathColors[idx % pathColors.length]
                pathsToShow.push(pathCopy)
            }
        }

        var combinedResult = {}
        if (pathsToShow.length > 0) {
            // 用第一条作为主路径（兼容旧接口）
            var mainPath = pathsToShow[0]
            for (var key in mainPath) {
                combinedResult[key] = mainPath[key]
            }
            combinedResult.paths = pathsToShow
            combinedResult.visibleIndices = visiblePathIndices
            combinedResult.pathColors = pathColors
        } else {
            // 没有可见路径，发送完全空的数据
            combinedResult = { paths: [], points: [], length: 0, names: [] }
        }
        root.pathCalculated(combinedResult)
    }

    function updatePathButtons() {
        // 如果 allPathResults 为空，按钮不可见，直接返回
        if (allPathResults.length === 0) return

        // 更新最短路径按钮
        var showShortest = visiblePathIndices.indexOf(-1) >= 0
        if (shortestBtn) {
            shortestBtn.text = "最短路径 " + (showShortest ? "✕" : "✓")
            shortestBtn.background.color = showShortest ? "#e74c3c" : "#3498db"
        }

        // 更新可选路径按钮
        for (var i = 0; i < pathButtonsRepeater.count; i++) {
            var btn = pathButtonsRepeater.itemAt(i)
            if (btn) {
                var idx = btn.buttonIndex
                var isVisible = visiblePathIndices.indexOf(idx) >= 0
                btn.text = "路径" + idx + " " + (isVisible ? "✕" : "✓")
                btn.background.color = isVisible ? "#e74c3c" : root.pathColors[(idx-1) % root.pathColors.length]
            }
        }
    }

    function updateLegend() {
        var legendItems = []
        for (var i = 0; i < visiblePathIndices.length; i++) {
            var idx = visiblePathIndices[i]
            if (idx === -1) {
                legendItems.push({label: "最短路径", color: pathColors[0]})
            } else if (idx > 0 && idx < allPathResults.length) {
                legendItems.push({label: "路径" + idx, color: pathColors[idx % pathColors.length]})
            }
        }
        legendRepeater.model = legendItems
        legendArea.visible = legendItems.length > 0
    }

    // ---------- UI ----------
    ScrollView {
        id: pathScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        padding: 8

        ColumnLayout {
            width: pathScroll.availableWidth
            spacing: 12

            Label {
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                text: "起点"
                font.bold: true
                color: "#2c3e2f"
            }

            SpotPickerRow {
                id: startPicker
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                spotsModel: root.spotsModel
                pickMode: "start"
                onMapPickRequested: function(mode) {
                    root.mapPickRequested(mode)
                }
            }

            Label {
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                text: "终点"
                font.bold: true
                color: "#2c3e2f"
            }

            SpotPickerRow {
                id: endPicker
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                spotsModel: root.spotsModel
                pickMode: "end"
                onMapPickRequested: function(mode) {
                    root.mapPickRequested(mode)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                spacing: 8

                Button {
                    text: "查询路径"
                    Layout.fillWidth: true
                    background: Rectangle { radius: 20; color: "#de4d3f" }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.calculatePath()
                }

                Button {
                    text: "清除所有"
                    Layout.fillWidth: true
                    background: Rectangle {
                        radius: 20
                        color: "#eef3ea"
                        border.color: "#d2dacb"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#8f9b8a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: root.clearAllPaths()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                height: 180
                color: Qt.rgba(245, 247, 242, 0.7)
                radius: 12
                border.color: Qt.rgba(224, 229, 216, 0.6)

                ScrollView {
                    id: resultScroll
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    AppTextArea {
                        id: pathResultText
                        width: resultScroll.availableWidth
                        readOnly: true
                        wrapMode: Text.WordWrap
                        placeholderText: "路径结果将显示在这里"
                        font.pixelSize: 12
                    }
                }
            }

            // ---------- 路径控制区域 ----------
            ColumnLayout {
                id: pathControlsArea
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                spacing: 8
                visible: allPathResults.length > 0

                // 按钮行：最短路径 + 可选路径
                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Button {
                        id: shortestBtn
                        text: "最短路径 ✓"
                        implicitHeight: 28
                        background: Rectangle {
                            radius: 14
                            color: "#3498db"
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: root.toggleShortestPath()
                    }

                    Repeater {
                        id: pathButtonsRepeater
                        model: (allPathResults && allPathResults.length > 1) ? Math.min(allPathResults.length - 1, 3) : 0

                        Button {
                            property int buttonIndex: index + 1
                            property color buttonColor: root.pathColors[index % root.pathColors.length]

                            text: "路径" + (index + 1) + " ✓"
                            implicitHeight: 28
                            background: Rectangle {
                                radius: 14
                                color: buttonColor
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: root.togglePath(buttonIndex)
                        }
                    }
                }

                // 图例
                Rectangle {
                    id: legendArea
                    Layout.fillWidth: true
                    height: visible ? 24 : 0
                    visible: false

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8
                        visible: parent.visible

                        Label {
                            text: "图例："
                            font.pixelSize: 10
                            color: "#8f9b8a"
                        }

                        Repeater {
                            id: legendRepeater
                            model: []

                            RowLayout {
                                spacing: 4

                                Rectangle {
                                    width: 16
                                    height: 3
                                    radius: 1.5
                                    color: modelData.color
                                }

                                Label {
                                    text: modelData.label
                                    font.pixelSize: 10
                                    color: "#555"
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }
    }

    // ---------- 外部接口 ----------
    function setPickedSpot(mode, spotName) {
        if (mode === "start") {
            startPicker.editText = spotName
        } else if (mode === "end") {
            endPicker.editText = spotName
        }
    }

    function showPath(startName, endName, result) {
        startPicker.editText = startName
        endPicker.editText = endName
        if (root.backend && root.getSpotIdByNameFn) {
            var startId = root.getSpotIdByNameFn(startName)
            var endId = root.getSpotIdByNameFn(endName)
            allPathResults = root.backend.findAllPaths(startId, endId, 4)
            visiblePathIndices = [-1]
            updatePathDisplay()
            updatePathButtons()
            updateLegend()
        }
    }

    function calculatePath() {
        if (!root.backend || !root.getSpotIdByNameFn) {
            pathResultText.text = "后端未就绪"
            return
        }

        var startId = root.getSpotIdByNameFn(startPicker.editText)
        var endId = root.getSpotIdByNameFn(endPicker.editText)
        allPathResults = root.backend.findAllPaths(startId, endId, 4)
        visiblePathIndices = [-1]
        updatePathDisplay()
        updatePathButtons()
        updateLegend()
    }
}