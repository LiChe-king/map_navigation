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

    AppComboBox {
        id: spotCombo
        Layout.fillWidth: true
        model: root.spotsModel
        textRole: "name"
        editable: true
    }

    AppButton {
        text: "📍"
        implicitWidth: 42
        buttonColor: "#f8faf5"
        buttonTextColor: "#2c3e2f"
        borderColor: "#d2dacb"
        onClicked: root.mapPickRequested(root.pickMode)
        ToolTip.text: "从地图选点"
        ToolTip.visible: hovered
    }
}
