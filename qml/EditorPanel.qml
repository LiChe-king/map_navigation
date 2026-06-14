import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property bool editMode: false
    property bool hasUnsavedChanges: false
    property var selectedNode: null
    property string toolMode: "select"

    signal saveRequested()
    signal undoRequested()
    signal refreshRequested()
    signal toolModeRequested(string mode)
    signal updateSpotName(int nodeId, string newName)
    signal updateSpotInfo(int nodeId, string name, string type, string intro)
    signal deleteSelectedRequested(int nodeId)
    signal addNodeRequested()
    signal roadDrawResetRequested()

    width: 320
    height: Math.min(panelLayout.implicitHeight + 32, parent ? parent.height - 40 : panelLayout.implicitHeight + 32)
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

    ScrollView {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.topMargin: 16
        anchors.rightMargin: 24
        anchors.bottomMargin: 16
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            id: panelLayout
            width: parent.width
            spacing: 10

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            RowLayout {
                id: titleRow
                anchors.fill: parent

                Text {
                    text: "地图编辑"
                    font.bold: true
                    font.pixelSize: 18
                    color: "#2c3e2f"
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    color: root.hasUnsavedChanges ? "#e67e22" : "#27ae60"

                    ToolTip {
                        text: root.hasUnsavedChanges ? "有未保存的修改" : "已保存"
                        visible: statusMouse.containsMouse
                    }

                    MouseArea {
                        id: statusMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, parent.width - 12)
                cursorShape: Qt.SizeAllCursor
                property point pressInParent
                property real startX: 0
                property real startY: 0

                onPressed: function(mouse) {
                    if (!root.parent) return
                    pressInParent = mapToItem(root.parent, mouse.x, mouse.y)
                    startX = root.x
                    startY = root.y
                }
                onPositionChanged: function(mouse) {
                    if (!pressed || !root.parent) return
                    var current = mapToItem(root.parent, mouse.x, mouse.y)
                    root.x = Math.max(8, Math.min(root.parent.width - root.width - 8, startX + current.x - pressInParent.x))
                    root.y = Math.max(8, Math.min(root.parent.height - root.height - 8, startY + current.y - pressInParent.y))
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AppButton {
                text: "💾 保存"
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                enabled: root.hasUnsavedChanges
                onClicked: root.saveRequested()
                buttonColor: "#27ae60"
            }

            AppButton {
                text: "↶ 撤销"
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                enabled: root.hasUnsavedChanges
                onClicked: root.undoRequested()
                buttonColor: "#e67e22"
            }
        }

        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }

        Text { text: "编辑工具"; font.bold: true; font.pixelSize: 13; color: "#2c3e2f" }

        AppComboBox {
            id: toolCombo
            Layout.fillWidth: true
            textRole: "label"
            valueRole: "value"
            model: [
                { label: "选择 / 移动", value: "select" },
                { label: "连续画路", value: "drawRoad" },
                { label: "新增景点", value: "addSpot" }
            ]
            onActivated: {
                root.toolMode = currentValue
                root.toolModeRequested(currentValue)
            }
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 11
            color: "#66736a"
            text: root.toolMode === "drawRoad"
                ? "在地图上连续点击即可新建路点并自动连线；点击已有节点可从该节点继续。"
                : root.toolMode === "addSpot"
                    ? "填写信息后点击地图，即可在该位置新增景点并生成同名路网节点。"
                    : "拖拽节点移动位置；点选节点后可编辑或删除。"
        }

        AppButton {
            text: "✓ 结束当前道路"
            visible: root.toolMode === "drawRoad"
            Layout.fillWidth: true
            buttonColor: "#5f80b4"
            onClicked: root.roadDrawResetRequested()
        }

        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }

        Text { text: "选中对象"; font.bold: true; font.pixelSize: 13; color: "#2c3e2f" }

        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 6
            Layout.fillWidth: true

            Text { text: "ID:"; color: "#7f8c8d"; font.pixelSize: 12 }
            Text { text: root.selectedNode ? root.selectedNode.id : "未选中"; font.bold: true; font.pixelSize: 12 }

            Text { text: "类型:"; color: "#7f8c8d"; font.pixelSize: 12 }
            Text {
                text: root.selectedNode ? (root.selectedNode.id < 1000 ? "景点" : "路点") : ""
                color: root.selectedNode ? (root.selectedNode.id < 1000 ? "#e74c3c" : "#27ae60") : "#7f8c8d"
                font.pixelSize: 12
            }

            Text { text: "坐标:"; color: "#7f8c8d"; font.pixelSize: 12 }
            Text {
                text: root.selectedNode ? Math.round(root.selectedNode.x) + ", " + Math.round(root.selectedNode.y) : ""
                font.pixelSize: 12
            }
        }

        SpotEditForm {
            selectedNode: root.selectedNode
            onUpdateSpotInfo: function(nodeId, name, type, intro) {
                root.updateSpotInfo(nodeId, name, type, intro)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            AppButton {
                text: "🗑 删除选中"
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                enabled: root.selectedNode
                onClicked: root.deleteSelectedRequested(root.selectedNode.id)
                buttonColor: "#e74c3c"
            }

            AppButton {
                text: "＋ 中心加路点"
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                buttonColor: "#5f80b4"
                onClicked: root.addNodeRequested()
            }
        }

        Rectangle { height: 1; color: "#e0e5dc"; Layout.fillWidth: true }

        Text { text: "新增景点默认信息"; font.bold: true; font.pixelSize: 13; color: "#2c3e2f" }

        AppTextField {
            id: newSpotName
            Layout.fillWidth: true
            placeholderText: "新景点名称"
            text: "新景点"
        }

        AppComboBox {
            id: newSpotType
            Layout.fillWidth: true
            editable: true
            model: ["景点", "校门", "餐饮食堂", "公共教学楼", "学院专业楼", "体育场地", "宿舍", "图书馆", "诊所", "活动场地", "其他"]
        }

        AppTextArea {
            id: newSpotIntro
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            placeholderText: "简介"
            wrapMode: Text.WordWrap
        }

        AppButton {
            text: "⟳ 刷新视图"
            Layout.fillWidth: true
            buttonColor: "#5f80b4"
            onClicked: root.refreshRequested()
        }
        }
    }

    function nextSpotName() {
        return newSpotName.text || "新景点"
    }

    function nextSpotType() {
        return newSpotType.editText || "景点"
    }

    function nextSpotIntro() {
        return newSpotIntro.text || ""
    }
}
