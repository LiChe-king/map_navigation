import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Popup {
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
    modal: false
    closePolicy: Popup.NoAutoClose
    
    onClosed: {
        if (!editMode) {
            closeRequested()
        }
    }
    
    background: Rectangle {
        color: Qt.rgba(255, 255, 255, 0.92)
        radius: 16
        border.color: Qt.rgba(224, 224, 224, 0.8)
        border.width: 1
        
        MouseArea {
            anchors.fill: parent
            property point dragStart
            onPressed: (mouse) => { dragStart = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    root.x += mouse.x - dragStart.x
                    root.y += mouse.y - dragStart.y
                }
            }
        }
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 6
            radius: 20
            samples: 32
            color: "#40000000"
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // 标题栏
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "transparent"
            radius: 16
            
            Label {
                text: "📍 附近设施"
                font.pixelSize: 16
                font.bold: true
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                color: "#2c3e2f"
            }
            
            Button {
                text: "✕"
                flat: true
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.close()
                background: Rectangle { radius: 14; color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent" }
                contentItem: Text { text: "✕"; color: "#8f9b8a" }
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(224, 229, 216, 0.6)
            }
        }
        
        // 内容区域
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            padding: 20
            
            ColumnLayout {
                width: parent.width
                spacing: 16
                
                Label { text: "📍 当前位置"; font.bold: true; color: "#2c3e2f" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ComboBox {
                        id: centerCombo
                        Layout.fillWidth: true
                        model: root.spotsModel
                        textRole: "name"
                        editable: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }
                    Button {
                        text: "📍"
                        onClicked: root.mapPickRequested("nearby")
                        ToolTip.text: "从地图选点"
                        ToolTip.visible: hovered
                    }
                }
                
                Label { text: "🏪 设施类型"; font.bold: true; color: "#2c3e2f" }
                ComboBox {
                    id: typeCombo
                    model: ["校门", "餐饮食堂", "公共教学楼", "学院专业楼", "体育场地", "宿舍", "图书馆", "诊所", "景点", "活动场地", "其他"]
                    Layout.fillWidth: true
                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                }
                
                Button {
                    text: "🔍 搜索附近"
                    Layout.fillWidth: true
                    background: Rectangle { radius: 20; color: "#e67e22" }
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                    onClicked: {
                        if (!root.backend || !root.getSpotIdByNameFn) {
                            return
                        }
                        var centerId = root.getSpotIdByNameFn(centerCombo.editText)
                        var result = root.backend.findNearby(centerId, typeCombo.currentText, 8)
                        nearbyListModel.clear()
                        for (var i = 0; i < result.length; i++) {
                            nearbyListModel.append(result[i])
                        }
                    }
                }
                
                Label { text: "📋 搜索结果"; font.bold: true; color: "#2c3e2f" }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    clip: true
                    model: ListModel { id: nearbyListModel }
                    spacing: 6
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 52
                        radius: 10
                        color: mouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: "#e67e22"
                                Text {
                                    anchors.centerIn: parent
                                    text: index + 1
                                    color: "white"
                                    font.bold: true
                                }
                            }
                            
                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Label {
                                    text: model.spot.name
                                    font.bold: true
                                    color: "#2c3e2f"
                                }
                                Label {
                                    text: model.spot.type
                                    color: "#8f9b8a"
                                    font.pixelSize: 11
                                }
                            }
                            
                            Rectangle {
                                implicitWidth: distLabel.implicitWidth + 16
                                implicitHeight: distLabel.implicitHeight + 8
                                radius: 14
                                color: Qt.rgba(224, 229, 216, 0.8)
                                Label {
                                    id: distLabel
                                    anchors.centerIn: parent
                                    text: model.distance + "米"
                                    color: "#de4d3f"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                        
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.backend || !root.getSpotIdByNameFn) return
                                var centerId = root.getSpotIdByNameFn(centerCombo.editText)
                                var result = root.backend.findShortestPath(centerId, model.spot.id)
                                root.pathCalculated(result)
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}