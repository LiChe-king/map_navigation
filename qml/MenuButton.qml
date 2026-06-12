import QtQuick
import QtQuick.Controls

Button {
    id: root
    property string menuId: ""
    
    implicitWidth: 76
    implicitHeight: 38
    flat: true
    
    contentItem: Text {
        text: root.text
        font.pixelSize: 14
        font.weight: root.hovered ? Font.Bold : Font.Normal
        color: root.hovered ? "#de4d3f" : "#333"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    
    background: Rectangle {
        radius: 19
        color: root.hovered ? "#f0f0f0" : "transparent"
    }
    
    // 按钮只负责发射信号，具体逻辑由父组件处理
}