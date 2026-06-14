import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

DraggablePopup {
    id: root

    property var spotsModel: []

    signal spotSelected(var spot)

    width: 400
    height: 480
    titleText: "🔎 景点查询"

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        padding: 8

        ListView {
            id: spotListView
            anchors.fill: parent
            model: root.spotsModel
            spacing: 6
            clip: true

            delegate: SpotListRow {
                width: ListView.view.width
                spotId: modelData.id
                spotName: modelData.name
                spotType: modelData.type
                intro: modelData.intro || ""
                onClicked: root.spotSelected(modelData)
            }
        }
    }
}
