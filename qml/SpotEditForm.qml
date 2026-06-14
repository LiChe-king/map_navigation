import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var selectedNode: null

    signal updateSpotInfo(int nodeId, string name, string type, string intro)

    visible: root.selectedNode && root.selectedNode.id < 1000
    Layout.fillWidth: true
    spacing: 8

    AppTextField {
        id: spotNameEditor
        Layout.fillWidth: true
        placeholderText: "景点名称"
        text: (root.selectedNode && root.selectedNode.name) ? root.selectedNode.name : ""
    }

    AppComboBox {
        id: spotTypeEditor
        Layout.fillWidth: true
        editable: true
        model: ["校门", "餐饮食堂", "公共教学楼", "学院专业楼", "体育场地", "宿舍", "图书馆", "诊所", "景点", "活动场地", "其他"]
        Component.onCompleted: root.syncSelectedSpot()
    }

    AppTextArea {
        id: spotIntroEditor
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        placeholderText: "景点简介"
        wrapMode: Text.WordWrap
        text: (root.selectedNode && root.selectedNode.intro) ? root.selectedNode.intro : ""
    }

    AppButton {
        text: "更新景点"
        Layout.fillWidth: true
        buttonColor: "#2f3431"
        onClicked: {
            if (root.selectedNode && spotNameEditor.text) {
                root.updateSpotInfo(root.selectedNode.id, spotNameEditor.text, spotTypeEditor.editText, spotIntroEditor.text)
            }
        }
    }

    onSelectedNodeChanged: syncSelectedSpot()

    function syncSelectedSpot() {
        if (!root.selectedNode || root.selectedNode.id >= 1000 || !spotTypeEditor) return
        spotTypeEditor.editText = root.selectedNode.type || "景点"
    }
}
