import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    id: root
    property var spotsModel: []
    property var nearbyModel: []
    property string pathText: ""

    signal queryPath(int fromId, int toId)
    signal queryNearby(int fromId, string type)
    signal selectSpot(int spotId)
    signal clearPath()

    background: Rectangle {
        color: "#f7f8f4"
        border.color: "#d2dacb"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: "校园导游咨询"
            font.pixelSize: 22
            font.bold: true
            Layout.fillWidth: true
        }

        TabBar {
            id: tabs
            Layout.fillWidth: true

            TabButton { text: "查询" }
            TabButton { text: "路径" }
            TabButton { text: "附近" }
            TabButton { text: "维护" }
        }

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                clip: true
                model: root.spotsModel

                delegate: ItemDelegate {
                    width: ListView.view.width
                    text: modelData.id + "  " + modelData.name + " / " + modelData.type
                    onClicked: root.selectSpot(modelData.id)
                }
            }

            ColumnLayout {
                spacing: 10

                Label { text: "最短路径"; font.bold: true }
                SpinBox { id: startInput; from: 1; to: 999; Layout.fillWidth: true; editable: true }
                SpinBox { id: endInput; from: 1; to: 999; Layout.fillWidth: true; editable: true }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "查询"
                        Layout.fillWidth: true
                        onClicked: root.queryPath(startInput.value, endInput.value)
                    }
                    Button {
                        text: "清除"
                        Layout.fillWidth: true
                        onClicked: root.clearPath()
                    }
                }

                TextArea {
                    text: root.pathText
                    readOnly: true
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                spacing: 10

                Label { text: "附近设施"; font.bold: true }
                SpinBox { id: nearbyStart; from: 1; to: 999; Layout.fillWidth: true; editable: true }
                ComboBox {
                    id: typeBox
                    model: ["饭堂", "卫生间", "超市", "宾馆", "教学楼", "校门", "景点", "宿舍"]
                    Layout.fillWidth: true
                }
                Button {
                    text: "搜索"
                    Layout.fillWidth: true
                    onClicked: root.queryNearby(nearbyStart.value, typeBox.currentText)
                }

                ListView {
                    clip: true
                    model: root.nearbyModel
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    delegate: ItemDelegate {
                        width: ListView.view.width
                        text: modelData.spot.name + "  " + modelData.distance + " 米"
                        onClicked: root.queryPath(nearbyStart.value, modelData.spot.id)
                    }
                }
            }

            ColumnLayout {
                spacing: 8

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        Label { text: "景点维护"; font.bold: true }
                        TextField { id: spotIdField; placeholderText: "ID"; Layout.fillWidth: true }
                        TextField { id: spotNameField; placeholderText: "名称"; Layout.fillWidth: true }
                        ComboBox {
                            id: spotTypeBox
                            model: ["景点", "饭堂", "卫生间", "超市", "宾馆", "教学楼", "校门", "宿舍"]
                            Layout.fillWidth: true
                        }
                        TextField { id: spotIntroField; placeholderText: "简介"; Layout.fillWidth: true }
                        TextField { id: spotXField; placeholderText: "X 坐标"; Layout.fillWidth: true }
                        TextField { id: spotYField; placeholderText: "Y 坐标"; Layout.fillWidth: true }

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: "保存"
                                Layout.fillWidth: true
                                onClicked: {
                                    var id = Number(spotIdField.text)
                                    var ok = campusBackend.updateSpot(id, spotNameField.text, spotTypeBox.currentText,
                                                                      spotIntroField.text, Number(spotXField.text),
                                                                      Number(spotYField.text))
                                    if (!ok) {
                                        campusBackend.addSpot(id, spotNameField.text, spotTypeBox.currentText,
                                                              spotIntroField.text, Number(spotXField.text),
                                                              Number(spotYField.text))
                                    }
                                }
                            }
                            Button {
                                text: "删除"
                                Layout.fillWidth: true
                                onClicked: campusBackend.removeSpot(Number(spotIdField.text))
                            }
                        }

                        Rectangle { height: 1; color: "#d2dacb"; Layout.fillWidth: true }

                        Label { text: "道路维护"; font.bold: true }
                        TextField { id: roadFromField; placeholderText: "起点 ID"; Layout.fillWidth: true }
                        TextField { id: roadToField; placeholderText: "终点 ID"; Layout.fillWidth: true }
                        TextArea {
                            id: roadPointsField
                            placeholderText: "路点：x,y x,y x,y"
                            wrapMode: TextArea.Wrap
                            Layout.fillWidth: true
                            Layout.preferredHeight: 82
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: "保存"
                                Layout.fillWidth: true
                                onClicked: campusBackend.addRoadFromText(Number(roadFromField.text),
                                                                         Number(roadToField.text),
                                                                         roadPointsField.text)
                            }
                            Button {
                                text: "删除"
                                Layout.fillWidth: true
                                onClicked: campusBackend.removeRoad(Number(roadFromField.text), Number(roadToField.text))
                            }
                        }
                    }
                }
            }
        }
    }
}
