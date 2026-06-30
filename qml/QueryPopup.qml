import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

DraggablePopup {
    id: root

    property var spotsModel: []
    property var filteredSpotsModel: []
    property var typeOptions: ["全部类型"]
    property string selectedType: "全部类型"
    property string searchKeyword: ""

    signal spotSelected(var spot)

    width: 380
    height: 540
    titleText: "🔎 景点查询"

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 8

            AppComboBox {
                id: typeFilter
                Layout.preferredWidth: 130
                model: root.typeOptions
                editable: false
                currentIndex: 0
                onCurrentTextChanged: {
                    root.selectedType = currentText || "全部类型"
                    root.refreshFilter()
                }
            }

            AppTextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "搜索景点"
                onTextChanged: {
                    root.searchKeyword = text
                    root.refreshFilter()
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            padding: 8

            ListView {
                id: spotListView
                anchors.fill: parent
                model: root.filteredSpotsModel
                spacing: 6
                clip: true

                delegate: SpotListRow {
                    width: ListView.view.width
                    spotNodeId: modelData.nodeId
                    spotName: modelData.name
                    spotType: modelData.type
                    intro: modelData.intro || ""
                    onClicked: root.spotSelected(modelData)
                }
            }
        }
    }

    Component.onCompleted: refreshAll()
    onSpotsModelChanged: refreshAll()

    function refreshAll() {
        root.typeOptions = buildTypeOptions()
        if (root.typeOptions.indexOf(root.selectedType) < 0) {
            root.selectedType = "全部类型"
            if (typeFilter) typeFilter.currentIndex = 0
        }
        refreshFilter()
    }

    function buildTypeOptions() {
        var options = ["全部类型"]
        var seen = { "全部类型": true }
        for (var i = 0; i < root.spotsModel.length; i++) {
            var type = root.spotsModel[i].type || "其他"
            if (!seen[type]) {
                seen[type] = true
                options.push(type)
            }
        }
        return options
    }

    function refreshFilter() {
        var keyword = (root.searchKeyword || "").toLowerCase()
        var selected = root.selectedType || "全部类型"
        var result = []

        for (var i = 0; i < root.spotsModel.length; i++) {
            var spot = root.spotsModel[i]
            var type = spot.type || ""
            if (selected !== "全部类型" && type !== selected) continue

            if (keyword) {
                var text = ((spot.name || "") + " " + type + " " + (spot.intro || "")).toLowerCase()
                if (text.indexOf(keyword) < 0) continue
            }

            result.push(spot)
        }

        root.filteredSpotsModel = result
    }
}
