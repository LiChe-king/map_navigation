import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

DraggablePopup {
    id: root

    property var spotsModel: []
    property var backend: null
    property var getSpotIdByNameFn: null
    property bool editMode: false

    signal pathCalculated(var result)
    signal mapPickRequested(string mode)
    signal closeRequested()

    width: 460
    height: 540
    titleText: "🧭 最短路径"

    onClosed: {
        if (!editMode) {
            closeRequested()
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        padding: 20

        ColumnLayout {
            width: parent.width
            spacing: 16

            Label {
                text: "🚩 起点"
                font.bold: true
                color: "#2c3e2f"
            }
            SpotPickerRow {
                id: startPicker
                spotsModel: root.spotsModel
                pickMode: "start"
                onMapPickRequested: function(mode) {
                    root.mapPickRequested(mode)
                }
            }

            Label {
                text: "🏁 终点"
                font.bold: true
                color: "#2c3e2f"
            }
            SpotPickerRow {
                id: endPicker
                spotsModel: root.spotsModel
                pickMode: "end"
                onMapPickRequested: function(mode) {
                    root.mapPickRequested(mode)
                }
            }

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

            Rectangle {
                Layout.fillWidth: true
                height: 140
                color: Qt.rgba(245, 247, 242, 0.7)
                radius: 12
                border.color: Qt.rgba(224, 229, 216, 0.6)

                TextArea {
                    id: pathResultText
                    anchors.fill: parent
                    anchors.margins: 12
                    readOnly: true
                    wrapMode: Text.WordWrap
                    placeholderText: "路径结果将显示在这里"
                    background: null
                    font.pixelSize: 13
                }
            }

            Button {
                text: "清除路径"
                Layout.fillWidth: true
                flat: true
                onClicked: {
                    startPicker.editText = ""
                    endPicker.editText = ""
                    pathResultText.text = ""
                    root.pathCalculated({})
                }
                contentItem: Text {
                    text: parent.text
                    color: "#8f9b8a"
                    horizontalAlignment: Text.AlignHCenter
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

    function calculatePath() {
        if (!root.backend || !root.getSpotIdByNameFn) {
            pathResultText.text = "后端未就绪"
            return
        }

        var startId = root.getSpotIdByNameFn(startPicker.editText)
        var endId = root.getSpotIdByNameFn(endPicker.editText)
        var result = root.backend.findShortestPath(startId, endId)
        root.pathCalculated(result)

        var distance = result.length || result.totalLength || 0
        var names = result.names || []
        pathResultText.text = names.length > 0
            ? names.join(" → ") + "\n\n总距离：" + distance + " 米"
            : "未找到可达路径"
    }
}
