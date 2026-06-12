import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    property bool editMode: false
    
    signal queryClicked()
    signal pathClicked()
    signal nearbyClicked()
    signal adminClicked()
    
    width: menuRow.implicitWidth + 32
    height: 48
    radius: 24
    color: Qt.rgba(247, 248, 244, 0.95)
    border.color: "#d2dacb"
    border.width: 1

    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 4
        radius: 12
        samples: 16
        color: "#30000000"
    }

    Row {
        id: menuRow
        anchors.centerIn: parent
        spacing: 4
        
        MenuButton {
            text: "🏠 查询"
            menuId: "query"
            onClicked: root.queryClicked()
        }
        MenuButton {
            text: "🗺️ 路径"
            menuId: "path"
            onClicked: root.pathClicked()
        }
        MenuButton {
            text: "📍 附近"
            menuId: "nearby"
            onClicked: root.nearbyClicked()
        }
        MenuButton {
            text: root.editMode ? "✏️ 退出编辑" : "⚙️ 维护"
            menuId: "admin"
            onClicked: root.adminClicked()
        }
    }
}