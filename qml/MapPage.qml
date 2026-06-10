import QtQuick
import QtQuick.Controls

Item {
    id: root
    property var spotsModel: []
    property var roadsModel: []
    property var pathResult: ({})
    property int focusSpotId: -1
    property var popupSpot: ({})

    Rectangle {
        anchors.fill: parent
        color: "#e8efe4"
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: mapLayer.width * mapLayer.scale
        contentHeight: mapLayer.height * mapLayer.scale

        Item {
            id: mapLayer
            width: Math.max(mapImage.sourceSize.width, 1536)
            height: Math.max(mapImage.sourceSize.height, 2048)
            scale: 0.58
            transformOrigin: Item.TopLeft

            Image {
                id: mapImage
                anchors.fill: parent
                source: "qrc:/qt/qml/CampusGuide/data/campus_map.jpg"
                fillMode: Image.Stretch
                smooth: true
            }

            PathDrawer {
                anchors.fill: parent
                pathPoints: root.pathResult.points || []
            }

            Repeater {
                model: root.spotsModel

                Rectangle {
                    id: marker
                    width: modelData.id === root.focusSpotId ? 26 : 20
                    height: width
                    radius: width / 2
                    x: modelData.x - width / 2
                    y: modelData.y - height / 2
                    color: modelData.id === root.focusSpotId ? "#ffcf33" : "#de4d3f"
                    border.color: "white"
                    border.width: 3

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.popupSpot = modelData
                    }

                    ToolTip.visible: markerMouse.containsMouse
                    ToolTip.text: modelData.name + "\n" + modelData.type

                    MouseArea {
                        id: markerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }

        WheelHandler {
            target: mapLayer
            onWheel: function(event) {
                var next = mapLayer.scale + event.angleDelta.y / 1200
                mapLayer.scale = Math.max(0.35, Math.min(1.8, next))
            }
        }
    }

    Popup {
        id: infoPopup
        x: 24
        y: 24
        width: 300
        modal: false
        visible: root.popupSpot && root.popupSpot.name
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Column {
            spacing: 8
            width: parent.width

            Label {
                text: root.popupSpot.name || ""
                font.bold: true
                font.pixelSize: 18
            }
            Label {
                text: root.popupSpot.type || ""
                color: "#62705d"
            }
            Label {
                width: parent.width
                text: root.popupSpot.intro || ""
                wrapMode: Text.WordWrap
            }
            Label {
                text: root.popupSpot.x !== undefined ? "坐标：" + root.popupSpot.x + ", " + root.popupSpot.y : ""
                color: "#62705d"
            }
        }
    }
}

