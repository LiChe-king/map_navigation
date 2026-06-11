import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

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
                    opacity: 0.95

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.popupSpot = modelData
                    }

                    ToolTip.visible: markerMouse.containsMouse ? true : false
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

    // 景点信息浮窗（跟随点击）
    Popup {
        id: infoPopup
        x: parent.width - 360
        y: 24
        width: 320
        modal: false
        visible: root.popupSpot && root.popupSpot.name ? true : false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#f7f8f4"
            radius: 16
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
        }

        Column {
            spacing: 8
            width: parent.width
            padding: 16

            Label {
                text: root.popupSpot.name || ""
                font.bold: true
                font.pixelSize: 20
                color: "#333"
            }
            Label {
                text: root.popupSpot.type || ""
                color: "#de4d3f"
                font.pixelSize: 14
            }
            Label {
                width: parent.width
                text: root.popupSpot.intro || ""
                wrapMode: Text.WordWrap
                color: "#555"
            }
        }
    }

    // 自动跳转到指定景点
    function jumpToSpot(spotX, spotY) {
        var targetX = spotX * mapLayer.scale - flickable.width / 2
        var targetY = spotY * mapLayer.scale - flickable.height / 2
        
        targetX = Math.max(0, Math.min(targetX, flickable.contentWidth - flickable.width))
        targetY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height))
        
        flickable.contentX = targetX
        flickable.contentY = targetY
    }
}