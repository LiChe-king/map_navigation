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

    signal pathCalculated(var result)
    signal mapPickRequested(string mode)
    signal closeRequested()

    width: 380
    height: 540
    titleText: "最短路径"

    onClosed: {
        if (!editMode) {
            closeRequested()
        }
    }

    ScrollView {
        id: pathScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        padding: 8

        ColumnLayout {
            width: pathScroll.availableWidth
            spacing: 16

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

            Button {
                text: "查询路径"
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                background: Rectangle { radius: 20; color: "#de4d3f" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.calculatePath()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                height: 260
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
                        font.pixelSize: 13
                    }
                }
            }

            AppButton {
                text: "清除路径"
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                buttonColor: "#eef3ea"
                buttonTextColor: "#8f9b8a"
                onClicked: {
                    pathResultText.text = ""
                    root.pathCalculated({})
                }
            }
        }
    }

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
        var allPaths = []
        if (root.backend && root.getSpotIdByNameFn) {
            var startId = root.getSpotIdByNameFn(startName)
            var endId = root.getSpotIdByNameFn(endName)
            allPaths = root.backend.findAllPaths(startId, endId, 3)
        }
        pathResultText.text = formatPathResult(result, allPaths)
        root.pathCalculated(resultWithPaths(result, allPaths))
    }

    function calculatePath() {
        if (!root.backend || !root.getSpotIdByNameFn) {
            pathResultText.text = "后端未就绪"
            return
        }

        var startId = root.getSpotIdByNameFn(startPicker.editText)
        var endId = root.getSpotIdByNameFn(endPicker.editText)
        var result = root.backend.findShortestPath(startId, endId)
        var allPaths = root.backend.findAllPaths(startId, endId, 3)
        pathResultText.text = formatPathResult(result, allPaths)
        root.pathCalculated(resultWithPaths(result, allPaths))
    }

    function resultWithPaths(result, allPaths) {
        if (!result) return {}

        var paths = allPaths || []
        if (paths.length <= 0 && result.points && result.points.length > 0) {
            paths = [result]
        }

        var next = {}
        for (var key in result) {
            next[key] = result[key]
        }
        next.paths = paths
        return next
    }

    function formatPathResult(result, allPaths) {
        if (!result) return ""

        var distance = result.length || result.totalLength || 0
        var names = result.names || []
        if (names.length <= 0) return "未找到可达路径"

        var text = "最短路径：\n" + names.join(" → ") + "\n总距离：" + distance + " 米"
        var paths = allPaths || []
        if (paths.length <= 0) {
            return text + "\n\n所有可选路径：未找到"
        }

        text += "\n\n所有可选路径（按距离排序，最多显示 3 条）："
        for (var i = 0; i < paths.length; i++) {
            var path = paths[i]
            var pathNames = path.names || []
            var pathDistance = path.length || path.totalLength || 0
            if (pathNames.length <= 0) continue
            text += "\n\n" + (i + 1) + ". " + pathNames.join(" → ")
                  + "\n   距离：" + pathDistance + " 米"
        }

        return text
    }
}
