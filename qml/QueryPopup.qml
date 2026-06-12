import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Popup {
    id: root
    property var spotsModel: []
    property var backend: null
    signal spotSelected(var spot)
    
    width: 400; height: 480
    modal: false
    closePolicy: Popup.NoAutoClose
    
    background: Rectangle {
        color: Qt.rgba(255, 255, 255, 0.92); radius: 16
        border.color: Qt.rgba(224, 224, 224, 0.8); border.width: 1
        layer.enabled: true
        layer.effect: DropShadow { horizontalOffset: 0; verticalOffset: 6; radius: 20; samples: 32; color: "#40000000" }
        MouseArea {
            anchors.fill: parent; property point dragStart
            onPressed: (mouse) => dragStart = Qt.point(mouse.x, mouse.y)
            onPositionChanged: (mouse) => { if (pressed) { root.x += mouse.x - dragStart.x; root.y += mouse.y - dragStart.y } }
        }
    }

    ColumnLayout { spacing: 0; anchors.fill: parent
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 52; color: "transparent"
            Label { text: "🔍 景点查询"; font.pixelSize: 16; font.bold: true; anchors.left: parent.left; anchors.leftMargin: 18; anchors.verticalCenter: parent.verticalCenter; color: "#2c3e2f" }
            Button {
                text: "✕"; flat: true; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                onClicked: root.close()
                background: Rectangle { radius: 14; color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent" }
                contentItem: Text { text: "✕"; color: "#8f9b8a"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(224, 229, 216, 0.6) }
        }
        
        ScrollView { Layout.fillWidth: true; Layout.fillHeight: true; clip: true; padding: 8
            ListView {
                id: spotListView; anchors.fill: parent; model: root.spotsModel; spacing: 6; clip: true
                delegate: Rectangle {
                    width: ListView.view.width; height: 52; radius: 10
                    color: mouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: { var tc = { "校门":"#f39c12","餐饮食堂":"#e67e22","公共教学楼":"#1abc9c","学院专业楼":"#9b59b6","体育场地":"#27ae60","宿舍":"#16a085","图书馆":"#3498db","诊所":"#e74c3c","景点":"#2ecc71","活动场地":"#f1c40f","其他":"#7f8c8d" }; return tc[modelData.type] || "#de4d3f" }
                            Text { anchors.centerIn: parent; text: modelData.id; color: "white"; font.bold: true }
                        }
                        ColumnLayout { spacing: 2; Layout.fillWidth: true
                            Label { text: modelData.name; font.bold: true; color: "#2c3e2f" }
                            Label { text: modelData.type + (modelData.intro ? " · " + modelData.intro : ""); color: "#8f9b8a"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                    MouseArea {
                        id: mouseArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.spotSelected(modelData)
                    }
                }
            }
        }
    }
}