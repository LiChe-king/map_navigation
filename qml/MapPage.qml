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

            // ========== 景点标记（白色圆角矩形 + 彩色文字） ==========
            Repeater {
                model: root.spotsModel

                Item {
                    id: markerContainer
                    x: modelData.x - (markerRect.width / 2)
                    y: modelData.y - markerRect.height - 6

                    property int textWidth: markerText.implicitWidth + 32

                    // 白色圆角矩形背景
                    Rectangle {
                        id: markerRect
                        width: markerContainer.textWidth-10
                        height: 40
                        radius: 15
                        color: "#ffffff"  // 统一白色底
                        border.color: {
                            if (modelData.id === root.focusSpotId) return "#ffcf33"
                            return "#d0d5cc"
                        }
                        border.width: 1.5

                        layer.enabled: true
                        layer.effect: DropShadow {
                            horizontalOffset: -5
                            verticalOffset: 5
                            radius: 10
                            samples: 8
                            color: "#30000000"
                        }

                        // 景点名称（彩色文字，根据类型）
                        Text {
                            id: markerText
                            anchors.centerIn: parent
                            text: modelData.name
                            font.pixelSize: 30
                            font.bold: false
                            font.family: "字魂扁桃体"
                            color: getTextColor(modelData.type)
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        anchors.fill: markerRect
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.popupSpot = modelData
                            root.focusSpotId = modelData.id
                        }
                    }

                    ToolTip {
                        visible: markerMouseArea.containsMouse
                        text: modelData.name + " (" + modelData.type + ")"
                        delay: 400
                    }
                    MouseArea {
                        id: markerMouseArea
                        anchors.fill: markerRect
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

    // 景点信息浮窗
    Popup {
        id: infoPopup
        x: parent.width - 360
        y: 24
        width: 320
        modal: false
        visible: root.popupSpot && root.popupSpot.name ? true : false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#ffffff"
            radius: 16
            border.color: "#e0e5dc"
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
                font.pixelSize: 20
                font.bold: true
                color: getTextColor(root.popupSpot.type)
            }
            Label {
                text: root.popupSpot.type || ""
                color: "#8f9b8a"
                font.pixelSize: 14
            }
            Label {
                width: parent.width
                text: root.popupSpot.intro || ""
                wrapMode: Text.WordWrap
                color: "#555"
                font.pixelSize: 13
            }
        }
    }

    function jumpToSpot(spotX, spotY) {
        var targetX = spotX * mapLayer.scale - flickable.width / 2
        var targetY = spotY * mapLayer.scale - flickable.height / 2
        
        targetX = Math.max(0, Math.min(targetX, flickable.contentWidth - flickable.width))
        targetY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height))
        
        flickable.contentX = targetX
        flickable.contentY = targetY
    }
    
    // 根据类型返回文字颜色（深色、鲜艳、区分度高）
    // ["校门", "餐饮食堂", "公共教学楼", "学院专业楼", "体育场地", "宿舍", "图书馆", "诊所", "景点", "活动场地", "其他"]
    function getTextColor(type) {
        switch(type) {
            case "校门":     return "#4c84e1"  // 天蓝色
            case "餐饮食堂":     return "#5f80b4"  // 蓝色
            case "公共教学楼":   return "#16a085"  // 青绿色
            case "学院专业楼":   return "#9b59b6"  // 紫色
            case "体育场地":   return "#27ae60"  // 绿色
            case "宿舍":     return "#1abc9c"  // 青绿色
            case "图书馆":   return "#3498db"  // 蓝色
            case "诊所":     return "#e74c3c"  // 红色
            case "景点":     return "#69806e"  // 灰绿色
            case "活动场地":   return "#f1c40f"  // 黄色
            case "其他":     return "#69806e"  // 灰绿色
            default:         return "#69806e"  // 灰绿色
        }
    }
}