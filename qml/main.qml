import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: window
    width: 1280
    height: 820
    visible: true
    title: "广西大学校园导游系统"
    color: "#e8efe4"

    // 地图铺满整个窗口
    MapPage {
        id: mapPage
        anchors.fill: parent
        spotsModel: campusBackend.spots
        roadsModel: campusBackend.roads
        pathResult: currentPathResult
        focusSpotId: currentFocusSpotId
        popupSpot: currentPopupSpot
    }

    // ========== 悬浮菜单栏 ==========
    Rectangle {
        id: menuBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        width: menuRow.implicitWidth + 32
        height: 48
        radius: 24
        color: Qt.rgba(247, 248, 244, 0.95)
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

        Row {
            id: menuRow
            anchors.centerIn: parent
            spacing: 4
            MenuButton { text: "🏠 查询"; menuId: "query" }
            MenuButton { text: "🗺️ 路径"; menuId: "path" }
            MenuButton { text: "📍 附近"; menuId: "nearby" }
            MenuButton { text: "⚙️ 维护"; menuId: "admin" }
        }
    }

    // ========== 状态变量 ==========
    property string activeMenu: ""
    property var currentPathResult: ({})
    property int currentFocusSpotId: -1
    property var currentPopupSpot: ({})

    // ========== 查询弹窗 ==========
    Popup {
        id: queryPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        width: 400
        height: 480
        modal: false
        closePolicy: Popup.NoAutoClose
        visible: activeMenu === "query"
        onClosed: { if (activeMenu === "query") activeMenu = "" }

        background: Rectangle {
            color: Qt.rgba(255, 255, 255, 0.92)
            radius: 16
            border.color: Qt.rgba(224, 224, 224, 0.8)
            border.width: 1

            MouseArea {
                anchors.fill: parent
                property point dragStart
                onPressed: (mouse) => { dragStart = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        queryPopup.x += mouse.x - dragStart.x
                        queryPopup.y += mouse.y - dragStart.y
                    }
                }
            }
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 6
                radius: 20
                samples: 32
                color: "#40000000"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 标题栏
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "transparent"
                radius: 16

                Label {
                    text: "🔍 景点查询"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2c3e2f"
                }

                Button {
                    text: "✕"
                    flat: true
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: activeMenu = ""
                    font.pixelSize: 16
                    background: Rectangle {
                        radius: 14
                        color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent"
                    }
                    contentItem: Text {
                        text: "✕"
                        color: "#8f9b8a"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.rgba(224, 229, 216, 0.6)
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                padding: 8

                ListView {
                    id: spotListView
                    width: parent.width
                    model: campusBackend.spots
                    spacing: 6
                    clip: true

                    delegate: Rectangle {
                        width: parent.width
                        height: 52
                        radius: 10
                        color: mouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: {
                                    var typeColors = {
                                        "景点": "#de4d3f",
                                        "饭堂": "#e67e22", 
                                        "卫生间": "#3498db",
                                        "超市": "#2ecc71",
                                        "宾馆": "#9b59b6",
                                        "教学楼": "#1abc9c",
                                        "校门": "#f39c12",
                                        "宿舍": "#16a085"
                                    }
                                    return typeColors[modelData.type] || (modelData.id % 2 === 0 ? "#de4d3f" : "#e67e22")
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.id
                                    color: "white"
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true
                                Label {
                                    text: modelData.name
                                    font.bold: true
                                    color: "#2c3e2f"
                                }
                                Label {
                                    text: modelData.type + (modelData.intro ? " · " + modelData.intro : "")
                                    color: "#8f9b8a"
                                    font.pixelSize: 11
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                currentPopupSpot = modelData
                                currentFocusSpotId = modelData.id
                                mapPage.jumpToSpot(modelData.x, modelData.y)
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== 路径规划弹窗 ==========
    Popup {
        id: pathPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        width: 420
        height: 480
        modal: false
        closePolicy: Popup.NoAutoClose
        visible: activeMenu === "path"
        onClosed: { if (activeMenu === "path") activeMenu = "" }

        background: Rectangle {
            color: Qt.rgba(255, 255, 255, 0.92)
            radius: 16
            border.color: Qt.rgba(224, 224, 224, 0.8)
            border.width: 1

            MouseArea {
                anchors.fill: parent
                property point dragStart
                onPressed: (mouse) => { dragStart = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        pathPopup.x += mouse.x - dragStart.x
                        pathPopup.y += mouse.y - dragStart.y
                    }
                }
            }
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 6
                radius: 20
                samples: 32
                color: "#40000000"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "transparent"
                radius: 16

                Label {
                    text: "🗺️ 最短路径"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2c3e2f"
                }

                Button {
                    text: "✕"
                    flat: true
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: activeMenu = ""
                    background: Rectangle { radius: 14; color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent" }
                    contentItem: Text { text: "✕"; color: "#8f9b8a" }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.rgba(224, 229, 216, 0.6)
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                padding: 20

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    Label { text: "🚩 起点"; font.bold: true; color: "#2c3e2f" }
                    ComboBox {
                        id: startCombo
                        Layout.fillWidth: true
                        model: campusBackend.spots
                        textRole: "displayName"
                        editable: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }

                    Label { text: "🏁 终点"; font.bold: true; color: "#2c3e2f" }
                    ComboBox {
                        id: endCombo
                        Layout.fillWidth: true
                        model: campusBackend.spots
                        textRole: "displayName"
                        editable: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }

                    Button {
                        text: "✨ 查询路径"
                        Layout.fillWidth: true
                        background: Rectangle { radius: 20; color: "#de4d3f" }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                        onClicked: {
                            var startId = getSpotIdByName(startCombo.editText)
                            var endId = getSpotIdByName(endCombo.editText)
                            var result = campusBackend.findShortestPath(startId, endId)
                            currentPathResult = result
                            pathResultText.text = result.length > 0
                                ? result.names.join(" → ") + "\n\n📏 总距离：" + result.length + " 米"
                                : "❌ 未找到可达路径"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 120
                        color: Qt.rgba(245, 247, 242, 0.7)
                        radius: 12
                        border.color: Qt.rgba(224, 229, 216, 0.6)
                        TextArea {
                            id: pathResultText
                            anchors.fill: parent
                            anchors.margins: 12
                            readOnly: true
                            wrapMode: Text.WordWrap
                            placeholderText: "路径结果将显示在这里"
                            background: null
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // ========== 附近搜索弹窗 ==========
    Popup {
        id: nearbyPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        width: 400
        height: 500
        modal: false
        closePolicy: Popup.NoAutoClose
        visible: activeMenu === "nearby"
        onClosed: { if (activeMenu === "nearby") activeMenu = "" }

        background: Rectangle {
            color: Qt.rgba(255, 255, 255, 0.92)
            radius: 16
            border.color: Qt.rgba(224, 224, 224, 0.8)
            border.width: 1

            MouseArea {
                anchors.fill: parent
                property point dragStart
                onPressed: (mouse) => { dragStart = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        nearbyPopup.x += mouse.x - dragStart.x
                        nearbyPopup.y += mouse.y - dragStart.y
                    }
                }
            }
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 6
                radius: 20
                samples: 32
                color: "#40000000"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "transparent"
                radius: 16

                Label {
                    text: "📍 附近设施"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2c3e2f"
                }

                Button {
                    text: "✕"
                    flat: true
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: activeMenu = ""
                    background: Rectangle { radius: 14; color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent" }
                    contentItem: Text { text: "✕"; color: "#8f9b8a" }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.rgba(224, 229, 216, 0.6)
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                padding: 20

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    Label { text: "📍 当前位置"; font.bold: true; color: "#2c3e2f" }
                    ComboBox {
                        id: centerCombo
                        Layout.fillWidth: true
                        model: campusBackend.spots
                        textRole: "displayName"
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }

                    Label { text: "🏪 设施类型"; font.bold: true; color: "#2c3e2f" }
                    ComboBox {
                        id: typeCombo
                        model: ["饭堂", "卫生间", "超市", "宾馆", "教学楼", "校门", "景点", "宿舍"]
                        Layout.fillWidth: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                    }

                    Button {
                        text: "🔍 搜索附近"
                        Layout.fillWidth: true
                        background: Rectangle { radius: 20; color: "#de4d3f" }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                        onClicked: {
                            var centerId = getSpotIdByName(centerCombo.editText)
                            var result = campusBackend.findNearby(centerId, typeCombo.currentText, 5)
                            nearbyListModel.clear()
                            for (var i = 0; i < result.length; i++) {
                                nearbyListModel.append(result[i])
                            }
                        }
                    }

                    Label { text: "📋 搜索结果"; font.bold: true; color: "#2c3e2f" }
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        clip: true
                        model: ListModel { id: nearbyListModel }
                        spacing: 6

                        delegate: Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            color: mouseArea.containsMouse ? Qt.rgba(245, 247, 242, 0.7) : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                Label {
                                    text: model.spot.name
                                    font.bold: true
                                    color: "#2c3e2f"
                                    Layout.fillWidth: true
                                }
                                Rectangle {
                                    implicitWidth: distLabel.implicitWidth + 12
                                    implicitHeight: distLabel.implicitHeight + 8
                                    radius: 12
                                    color: Qt.rgba(224, 229, 216, 0.8)
                                    Label {
                                        id: distLabel
                                        anchors.centerIn: parent
                                        text: model.distance + "米"
                                        color: "#de4d3f"
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var result = campusBackend.findShortestPath(centerCombo.currentValue, model.spot.id)
                                    currentPathResult = result
                                    activeMenu = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== 后台维护弹窗 ==========
    Popup {
        id: adminPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        width: 460
        height: 580
        modal: false
        closePolicy: Popup.NoAutoClose
        visible: activeMenu === "admin"
        onClosed: { if (activeMenu === "admin") activeMenu = "" }

        background: Rectangle {
            color: Qt.rgba(255, 255, 255, 0.92)
            radius: 16
            border.color: Qt.rgba(224, 224, 224, 0.8)
            border.width: 1

            MouseArea {
                anchors.fill: parent
                property point dragStart
                onPressed: (mouse) => { dragStart = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        adminPopup.x += mouse.x - dragStart.x
                        adminPopup.y += mouse.y - dragStart.y
                    }
                }
            }
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 6
                radius: 20
                samples: 32
                color: "#40000000"
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                color: "transparent"
                radius: 16

                Label {
                    text: "⚙️ 数据维护"
                    font.pixelSize: 16
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#2c3e2f"
                }

                Button {
                    text: "✕"
                    flat: true
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: activeMenu = ""
                    background: Rectangle { radius: 14; color: parent.hovered ? Qt.rgba(224, 229, 216, 0.6) : "transparent" }
                    contentItem: Text { text: "✕"; color: "#8f9b8a" }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.rgba(224, 229, 216, 0.6)
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                padding: 20

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    TabBar {
                        id: adminTabs
                        Layout.fillWidth: true
                        background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 12 }
                        TabButton {
                            text: "🏛️ 景点管理"
                            background: Rectangle {
                                radius: 10
                                color: parent.checked ? "#de4d3f" : "transparent"
                            }
                        }
                        TabButton {
                            text: "🛣️ 道路管理"
                            background: Rectangle {
                                radius: 10
                                color: parent.checked ? "#de4d3f" : "transparent"
                            }
                        }
                    }

                    StackLayout {
                        currentIndex: adminTabs.currentIndex
                        Layout.fillWidth: true
                        Layout.preferredHeight: 380

                        ColumnLayout {
                            spacing: 12
                            GridLayout {
                                columns: 2
                                Layout.fillWidth: true
                                columnSpacing: 12
                                rowSpacing: 10

                                Label { text: "ID:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminSpotId
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "名称:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminSpotName
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "类型:"; color: "#2c3e2f" }
                                ComboBox {
                                    id: adminSpotType
                                    model: ["景点", "饭堂", "卫生间", "超市", "宾馆", "教学楼", "校门", "宿舍"]
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "X坐标:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminSpotX
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "Y坐标:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminSpotY
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "简介:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminSpotIntro
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                Button {
                                    text: "💾 保存"
                                    Layout.fillWidth: true
                                    background: Rectangle { radius: 20; color: "#de4d3f" }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                Button {
                                    text: "🗑️ 删除"
                                    Layout.fillWidth: true
                                    background: Rectangle { radius: 20; color: "#8f9b8a" }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 12
                            GridLayout {
                                columns: 2
                                Layout.fillWidth: true
                                columnSpacing: 12
                                rowSpacing: 10
                                Label { text: "起点ID:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminRoadFrom
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "终点ID:"; color: "#2c3e2f" }
                                TextField {
                                    id: adminRoadTo
                                    Layout.fillWidth: true
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                                Label { text: "路点序列:"; color: "#2c3e2f"; Layout.rowSpan: 2 }
                                TextArea {
                                    id: adminRoadPoints
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 80
                                    placeholderText: "x y x y x y"
                                    background: Rectangle { color: Qt.rgba(245, 247, 242, 0.8); radius: 8; border.color: "#d2dacb" }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                Button {
                                    text: "💾 保存"
                                    Layout.fillWidth: true
                                    background: Rectangle { radius: 20; color: "#de4d3f" }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                                Button {
                                    text: "🗑️ 删除"
                                    Layout.fillWidth: true
                                    background: Rectangle { radius: 20; color: "#8f9b8a" }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== 辅助函数 ==========
    function getSpotIdByName(name) {
        var spots = campusBackend.spots
        for (var i = 0; i < spots.length; i++) {
            if (spots[i].name === name || (spots[i].id + " " + spots[i].name) === name) {
                return spots[i].id
            }
        }
        return parseInt(name) || 1
    }
}