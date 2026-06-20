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
                height: 140
                color: Qt.rgba(245, 247, 242, 0.7)
                radius: 12
                border.color: Qt.rgba(224, 229, 216, 0.6)

                AppTextArea {
                    id: pathResultText
                    anchors.fill: parent
                    anchors.margins: 12
                    readOnly: true
                    wrapMode: Text.WordWrap
                    placeholderText: "路径结果将显示在这里"
                    font.pixelSize: 13
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
        pathResultText.text = formatPathResult(result)
        root.pathCalculated(result)
    }

    function calculatePath() {
        if (!root.backend || !root.getSpotIdByNameFn) {
            pathResultText.text = "后端未就绪"
            return
        }

        var startId = root.getSpotIdByNameFn(startPicker.editText)
        var endId = root.getSpotIdByNameFn(endPicker.editText)
        var result = root.backend.findShortestPath(startId, endId)
        pathResultText.text = formatPathResult(result)
        root.pathCalculated(result)
    }

    function formatPathResult(result) {
        if (!result) return ""

        var distance = result.length || result.totalLength || 0
        var names = result.names || []
        return names.length > 0
            ? names.join(" → ") + "\n\n总距离：" + distance + " 米"
            : "未找到可达路径"
    }
}
