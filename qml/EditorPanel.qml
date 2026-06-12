import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    
    property bool editMode: false
    property bool hasUnsavedChanges: false
    property var selectedNode: null
    property real mapLayerScale: 1.0
    
    signal saveRequested()
    signal undoRequested()
    signal refreshRequested()
    signal updateSpotName(int nodeId, string newName)
    signal deleteNodeRequested(int nodeId)
    signal addNodeRequested()
    
    width: 300
    height: 550
    radius: 16
    color: Qt.rgba(255, 255, 255, 0.98)
    border.color: "#d2dacb"
    visible: editMode

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 4
        radius: 12
        samples: 16
        color: "#30000000"
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "✏️ 路网编辑器"
                font.bold: true
                font.pixelSize: 16
                color: "#2c3e2f"
                Layout.fillWidth: true
            }
            Rectangle {
                width: 12; height: 12; radius: 6
                color: hasUnsavedChanges ? "#e67e22" : "#27ae60"
                ToolTip { text: hasUnsavedChanges ? "有未保存的修改" : "已保存"; visible: parentMouse.containsMouse }
                MouseArea { id: parentMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
            }
        }
        
        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }
        
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Button {
                text: "💾 保存"; Layout.fillWidth: true; enabled: hasUnsavedChanges
                onClicked: root.saveRequested()
                background: Rectangle { radius: 8; color: hasUnsavedChanges ? "#27ae60" : "#bdc3c7" }
                contentItem: Text { text: parent.text; color: "white" }
            }
            Button {
                text: "↩️ 撤销"; Layout.fillWidth: true; enabled: hasUnsavedChanges
                onClicked: root.undoRequested()
                background: Rectangle { radius: 8; color: "#e67e22" }
                contentItem: Text { text: parent.text; color: "white" }
            }
        }
        
        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }
        
        Text { text: "📌 操作提示"; font.bold: true; font.pixelSize: 12 }
        ColumnLayout { spacing: 4; Layout.fillWidth: true
            Text { text: "• 拖拽节点：移动位置"; font.pixelSize: 11; color: "#555" }
            Text { text: "• Ctrl+点击节点：开始连线"; font.pixelSize: 11; color: "#555" }
            Text { text: "• 再点击另一节点：完成连线"; font.pixelSize: 11; color: "#555" }
            Text { text: "• 点击道路：删除该道路"; font.pixelSize: 11; color: "#555" }
        }
        
        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }
        
        Text { text: "📍 选中节点"; font.bold: true; font.pixelSize: 12 }
        
        GridLayout { columns: 2; columnSpacing: 12; rowSpacing: 6; Layout.fillWidth: true
            Text { text: "ID:"; color: "#7f8c8d"; font.pixelSize: 12 }
            Text { text: selectedNode ? selectedNode.id : "未选中"; font.bold: true; font.pixelSize: 12 }
            Text { text: "类型:"; color: "#7f8c8d"; font.pixelSize: 12 }
            Text {
                text: selectedNode ? (selectedNode.id < 1000 ? "🏛️ 景点" : "🔘 路口") : ""
                color: selectedNode ? (selectedNode.id < 1000 ? "#e74c3c" : "#27ae60") : "#7f8c8d"
                font.pixelSize: 12
            }
            Text { text: "坐标:"; color: "#7f8c8d"; font.pixelSize: 12 }
            Text { text: selectedNode ? Math.round(selectedNode.x) + ", " + Math.round(selectedNode.y) : ""; font.pixelSize: 12 }
        }
        
        TextField {
            id: spotNameEditor
            placeholderText: "景点名称"
            text: (selectedNode && selectedNode.id < 1000 && selectedNode.name) ? selectedNode.name : ""
            visible: selectedNode && selectedNode.id < 1000
            Layout.fillWidth: true
            background: Rectangle { radius: 8; border.color: "#d2dacb" }
        }
        
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            visible: selectedNode && selectedNode.id < 1000
            Button {
                text: "更新名称"; Layout.fillWidth: true
                onClicked: { if (selectedNode && spotNameEditor.text) root.updateSpotName(selectedNode.id, spotNameEditor.text) }
                background: Rectangle { radius: 8; color: "#3498db" }
                contentItem: Text { text: parent.text; color: "white" }
            }
        }
        
        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }
        
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Button {
                text: "🗑️ 删除节点"; Layout.fillWidth: true; enabled: selectedNode && selectedNode.id >= 1000
                onClicked: root.deleteNodeRequested(selectedNode.id)
                background: Rectangle { radius: 8; color: "#e74c3c" }
                contentItem: Text { text: parent.text; color: "white" }
            }
            Button {
                text: "➕ 新增路口"; Layout.fillWidth: true
                onClicked: root.addNodeRequested()
                background: Rectangle { radius: 8; color: "#27ae60" }
                contentItem: Text { text: parent.text; color: "white" }
            }
        }
        
        Button {
            text: "📐 刷新视图"; Layout.fillWidth: true
            onClicked: root.refreshRequested()
            background: Rectangle { radius: 8; color: "#3498db" }
            contentItem: Text { text: parent.text; color: "white" }
        }
    }
}