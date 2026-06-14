import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property alias editText: spotCombo.editText
    property var spotsModel: []
    property string pickMode: ""

    signal mapPickRequested(string mode)

    Layout.fillWidth: true
    spacing: 8

    ComboBox {
        id: spotCombo
        Layout.fillWidth: true
        model: root.spotsModel
        textRole: "name"
        editable: true
        background: Rectangle {
            color: Qt.rgba(245, 247, 242, 0.8)
            radius: 8
            border.color: "#d2dacb"
        }
    }

    Button {
        text: "📍"
        onClicked: root.mapPickRequested(root.pickMode)
        ToolTip.text: "从地图选点"
        ToolTip.visible: hovered
    }
}
