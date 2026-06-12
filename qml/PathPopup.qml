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
    
    width: 460
    height: 540
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
                text: "🗺️ 最短路径"
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
                
                Label { text: "🚩 起点"; font.bold: true; color: "#2c3e2f" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ComboBox {
                        id: startCombo
                        Layout.fillWidth: true
                        model: root.spotsModel
                        textRole: "name"
                        editable: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }
                    Button {
                        text: "📍"
                        onClicked: root.mapPickRequested("start")
                        ToolTip.text: "从地图选点"
                        ToolTip.visible: hovered
                    }
                }
                
                Label { text: "🏁 终点"; font.bold: true; color: "#2c3e2f" }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ComboBox {
                        id: endCombo
                        Layout.fillWidth: true
                        model: root.spotsModel
                        textRole: "name"
                        editable: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }
                    Button {
                        text: "📍"
                        onClicked: root.mapPickRequested("end")
                        ToolTip.text: "从地图选点"
                        ToolTip.visible: hovered
                    }
                }
                
                Button {
                    text: "✨ 查询路径"
                    Layout.fillWidth: true
                    background: Rectangle { radius: 20; color: "#de4d3f" }
                    contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                    onClicked: {
                        if (!root.backend || !root.getSpotIdByNameFn) {
                            pathResultText.text = "❌ 后端未就绪"
                            return
                        }
                        var startId = root.getSpotIdByNameFn(startCombo.editText)
                        var endId = root.getSpotIdByNameFn(endCombo.editText)
                        var result = root.backend.findShortestPath(startId, endId)
                        root.pathCalculated(result)
                        var distance = result.length || result.totalLength || 0
                        var names = result.names || []
                        pathResultText.text = names.length > 0
                            ? names.join(" → ") + "\n\n📏 总距离：" + distance + " 米"
                            : "❌ 未找到可达路径"
                    }
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
                    text: "🗑️ 清除路径"
                    Layout.fillWidth: true
                    flat: true
                    onClicked: {
                        startCombo.editText = ""
                        endCombo.editText = ""
                        pathResultText.text = ""
                        root.pathCalculated({})
                    }
                    contentItem: Text { text: parent.text; color: "#8f9b8a" }
                }
            }
        }
    }
}