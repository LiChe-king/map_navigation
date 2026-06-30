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
    signal pathSelected(string startName, string endName, var result)
    signal spotSelected(var spot)
    signal mapPickRequested(string mode)
    signal closeRequested()

    width: 380
    height: 560
    titleText: "附近设施"

    onClosed: {
        if (!editMode) {
            closeRequested()
        }
    }

    ScrollView {
        id: nearbyScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentWidth: availableWidth
        clip: true
        padding: 8

        ColumnLayout {
            width: nearbyScroll.availableWidth
            spacing: 16

            Label {
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                text: "当前位置"
                font.bold: true
                color: "#2c3e2f"
            }

            SpotPickerRow {
                id: centerPicker
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                spotsModel: root.spotsModel
                pickMode: "nearby"
                onMapPickRequested: function(mode) {
                    root.mapPickRequested(mode)
                }
            }

            Label {
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                text: "设施类型"
                font.bold: true
                color: "#2c3e2f"
            }

            AppComboBox {
                id: typeCombo
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                model: ["校门", "餐饮食堂", "公共教学楼", "学院专业楼", "校车乘车点", "体育场地", "宿舍", "图书馆", "诊所", "景点", "活动场地", "其他"]
            }

            Button {
                text: "搜索附近"
                Layout.fillWidth: true
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
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
                Layout.leftMargin: root.formMargin
                Layout.rightMargin: root.formMargin
                text: "搜索结果"
                font.bold: true
                color: "#2c3e2f"
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 220

                ListView {
                    anchors.fill: parent
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
                            root.spotSelected(model.spot)
                        }
                        onNavigateClicked: {
                            if (!root.backend || !root.getSpotIdByNameFn) return
                            var centerId = root.getSpotIdByNameFn(centerPicker.editText)
                            var result = root.backend.findShortestPath(centerId, model.spot.nodeId)
                            root.pathSelected(centerPicker.editText, model.spot.name, result)
                            root.close()
                        }
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
