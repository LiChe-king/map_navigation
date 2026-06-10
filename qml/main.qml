import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 1280
    height: 820
    visible: true
    title: "广西大学校园导游系统"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            spotsModel: campusBackend.spots

            onQueryPath: function(fromId, toId) {
                var result = campusBackend.findShortestPath(fromId, toId)
                mapPage.pathResult = result
                sidebar.pathText = result.length > 0
                        ? result.names.join(" -> ") + "\n总距离：" + result.length + " 米"
                        : "未找到可达路径"
            }

            onQueryNearby: function(fromId, type) {
                var result = campusBackend.findNearby(fromId, type, 5)
                sidebar.nearbyModel = result
                if (result.length > 0) {
                    mapPage.pathResult = result[0].path
                }
            }

            onSelectSpot: function(spotId) {
                mapPage.focusSpotId = spotId
                mapPage.popupSpot = campusBackend.spotDetail(spotId)
            }

            onClearPath: {
                mapPage.pathResult = ({})
                sidebar.pathText = ""
                sidebar.nearbyModel = []
            }
        }

        MapPage {
            id: mapPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            spotsModel: campusBackend.spots
            roadsModel: campusBackend.roads
        }
    }
}

