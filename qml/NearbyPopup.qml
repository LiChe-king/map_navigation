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

    width: 440
    height: 560
    titleText: "📍 附近设施"

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
                text: "📍 当前位置"
                font.bold: true
                color: "#2c3e2f"
            }
            SpotPickerRow {
                id: centerPicker
                spotsModel: root.spotsModel
                pickMode: "nearby"
                onMapPickRequested: function(mode) {
                    root.mapPickRequested(mode)
                }
            }

            Label {
                text: "🏫 设施类型"
                font.bold: true
                color: "#2c3e2f"
            }
            ComboBox {
                id: typeCombo
                Layout.fillWidth: true
                model: ["校门", "餐饮食堂", "公共教学楼", "学院专业楼", "体育场地", "宿舍", "图书馆", "诊所", "景点", "活动场地", "其他"]
                background: Rectangle {
                    color: Qt.rgba(245, 247, 242, 0.8)
                    radius: 8
                    border.color: "#d2dacb"
                }
            }

            Button {
                text: "搜索附近"
                Layout.fillWidth: true
                background: Rectangle { radius: 20; color: "#e67e22" }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: root.searchNearby()
            }

            Label {
                text: "📋 搜索结果"
                font.bold: true
                color: "#2c3e2f"
            }
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                clip: true
                model: ListModel { id: nearbyListModel }
                spacing: 6

                delegate: NearbyResultRow {
                    width: ListView.view.width
                    spotName: model.spot.name
                    spotType: model.spot.type
                    distance: model.distance
                    number: index + 1
                    onClicked: {
                        if (!root.backend || !root.getSpotIdByNameFn) return
                        var centerId = root.getSpotIdByNameFn(centerPicker.editText)
                        root.pathCalculated(root.backend.findShortestPath(centerId, model.spot.id))
                        root.close()
                    }
                }
            }
        }
    }

    function setPickedSpot(mode, spotName) {
        if (mode === "nearby") {
            centerPicker.editText = spotName
        }
    }

    function searchNearby() {
        if (!root.backend || !root.getSpotIdByNameFn) return

        var centerId = root.getSpotIdByNameFn(centerPicker.editText)
        var result = root.backend.findNearby(centerId, typeCombo.currentText, 8)
        nearbyListModel.clear()
        for (var i = 0; i < result.length; i++) {
            nearbyListModel.append(result[i])
        }
    }
}
