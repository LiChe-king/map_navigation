import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: window
    width: 1280; height: 820; visible: true
    title: "广西大学校园导游系统"
    color: "#e8efe4"

    // 全局状态
    property string pickingMode: ""
    property string originalMenu: ""
    property string activeMenu: ""
    property var currentPathResult: ({})
    property int currentFocusSpotId: -1
    property var currentPopupSpot: ({})
    
    property bool editMode: false
    property var selectedNode: null
    property int tempEdgeFrom: -1
    property bool hasUnsavedChanges: false

    // 统一弹窗管理函数
    function openPopup(popupToOpen, menuName) {
        // 关闭所有弹窗
        if (queryPopup.visible) queryPopup.close()
        if (pathPopup.visible) pathPopup.close()
        if (nearbyPopup.visible) nearbyPopup.close()
        
        // 打开指定的弹窗
        popupToOpen.open()
        activeMenu = menuName
    }

    // 地图页面
    Item {
        id: mapContainer
        anchors.fill: parent

        MapPage {
            id: mapPage
            anchors.fill: parent
            spotsModel: campusBackend.spots
            pathResult: window.currentPathResult
            focusSpotId: window.currentFocusSpotId
            popupSpot: window.currentPopupSpot
            editMode: window.editMode
            allNodes: getAllNodesData()
            edges: getAllEdgesData()
            tempEdgeFrom: window.tempEdgeFrom
            
            onNodeMoved: function(nodeId, newX, newY) {
                if (nodeId < 1000) {
                    var spot = campusBackend.spotDetail(nodeId)
                    if (spot.id) campusBackend.updateSpotOnly(nodeId, spot.name, spot.type, spot.intro, newX, newY)
                } else {
                    campusBackend.updateNodeOnly(nodeId, newX, newY)
                }
                window.hasUnsavedChanges = true
            }
            onEdgeAdded: function(fromId, toId) {
                campusBackend.addEdgeOnly(fromId, toId)
                mapPage.edges = getAllEdgesData()
                window.hasUnsavedChanges = true
            }
            onEdgeRemoved: function(fromId, toId) {
                campusBackend.removeEdgeOnly(fromId, toId)
                mapPage.edges = getAllEdgesData()
                window.hasUnsavedChanges = true
            }
            onNodeSelected: function(nodeId) {
                window.selectedNode = findNodeById(nodeId)
            }
            onTempEdgeChanged: function(fromId) {
                window.tempEdgeFrom = (fromId !== undefined && fromId !== -1) ? fromId : -1
            }
        }
        
        // 地图选点层
        MouseArea {
            anchors.fill: parent
            enabled: !window.editMode && window.pickingMode !== ""
            cursorShape: Qt.CrossCursor
            z: 100
            onClicked: function(mouse) {
                var scenePos = mapPage.mapToItem(mapPage, mouse.x, mouse.y)
                var spots = campusBackend.spots
                var nearestId = -1, nearestName = "", minDist = 40
                for (var i = 0; i < spots.length; i++) {
                    var dx = spots[i].x - scenePos.x
                    var dy = spots[i].y - scenePos.y
                    var dist = Math.sqrt(dx*dx + dy*dy)
                    if (dist < minDist) {
                        minDist = dist
                        nearestId = spots[i].id
                        nearestName = spots[i].name
                    }
                }
                if (nearestId !== -1) {
                    if (window.pickingMode === "start") {
                        startCombo.editText = nearestName
                    } else if (window.pickingMode === "end") {
                        endCombo.editText = nearestName
                    } else if (window.pickingMode === "nearby") {
                        centerCombo.editText = nearestName
                    }
                }
                window.pickingMode = ""
                if (window.originalMenu === "path") pathPopup.open()
                else if (window.originalMenu === "nearby") nearbyPopup.open()
                window.originalMenu = ""
            }
        }
    }

    // ========== 菜单栏 ==========
    CustomMenuBar {
        id: menuBar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 20
        editMode: window.editMode
        
        Component.onCompleted: {
            // 查询按钮
            menuBar.queryClicked.connect(function() {
                if (window.editMode) window.editMode = false
                openPopup(queryPopup, "query")
            })
            // 路径按钮
            menuBar.pathClicked.connect(function() {
                if (window.editMode) window.editMode = false
                openPopup(pathPopup, "path")
            })
            // 附近按钮
            menuBar.nearbyClicked.connect(function() {
                if (window.editMode) window.editMode = false
                openPopup(nearbyPopup, "nearby")
            })
            // 维护/编辑按钮
            menuBar.adminClicked.connect(function() {
                if (window.editMode) {
                    // 退出编辑模式
                    window.editMode = false
                    window.selectedNode = null
                    window.tempEdgeFrom = -1
                    if (window.hasUnsavedChanges) {
                        campusBackend.save()
                        window.hasUnsavedChanges = false
                    }
                } else {
                    // 进入编辑模式前关闭所有弹窗
                    if (queryPopup.visible) queryPopup.close()
                    if (pathPopup.visible) pathPopup.close()
                    if (nearbyPopup.visible) nearbyPopup.close()
                    window.activeMenu = ""
                    window.editMode = true
                }
            })
        }
    }
    
    // 编辑面板
    EditorPanel {
        id: editorPanel
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        editMode: window.editMode
        hasUnsavedChanges: window.hasUnsavedChanges
        selectedNode: window.selectedNode
        mapLayerScale: mapPage.mapLayerScale
        z: 200
        
        onSaveRequested: {
            campusBackend.save()
            window.hasUnsavedChanges = false
        }
        onUndoRequested: {
            campusBackend.load()
            window.hasUnsavedChanges = false
            mapPage.allNodes = getAllNodesData()
            mapPage.edges = getAllEdgesData()
        }
        onRefreshRequested: {
            mapPage.allNodes = getAllNodesData()
            mapPage.edges = getAllEdgesData()
        }
        onUpdateSpotName: function(nodeId, newName) {
            var spot = campusBackend.spotDetail(nodeId)
            if (spot.id) {
                campusBackend.updateSpotOnly(nodeId, newName, spot.type, spot.intro, spot.x, spot.y)
                if (window.selectedNode) window.selectedNode.name = newName
                mapPage.allNodes = getAllNodesData()
                window.hasUnsavedChanges = true
            }
        }
        onDeleteNodeRequested: function(nodeId) {
            campusBackend.removeNodeOnly(nodeId)
            window.selectedNode = null
            mapPage.allNodes = getAllNodesData()
            mapPage.edges = getAllEdgesData()
            window.hasUnsavedChanges = true
        }
        onAddNodeRequested: {
            var maxId = 1000
            var nodes = campusBackend.nodes
            for (var i = 0; i < nodes.length; i++) {
                if (nodes[i].id > maxId) maxId = nodes[i].id
            }
            var newNodeId = maxId + 1
            if (newNodeId < 1000) newNodeId = 1000
            var centerX = mapContainer.width / 2 / (mapPage.mapLayerScale || 1)
            var centerY = mapContainer.height / 2 / (mapPage.mapLayerScale || 1)
            campusBackend.addNodeOnly(newNodeId, centerX, centerY)
            mapPage.allNodes = getAllNodesData()
            window.hasUnsavedChanges = true
        }
    }

    // 弹窗定义
    QueryPopup {
        id: queryPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        spotsModel: campusBackend.spots
        onSpotSelected: function(spot) {
            window.currentPopupSpot = spot
            window.currentFocusSpotId = spot.id
            if (mapPage.jumpToSpot) mapPage.jumpToSpot(spot.x, spot.y)
        }
        onClosed: {
            if (window.activeMenu === "query") window.activeMenu = ""
        }
    }
    
    PathPopup {
        id: pathPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        spotsModel: campusBackend.spots
        backend: campusBackend
        getSpotIdByNameFn: getSpotIdByName
        onMapPickRequested: function(mode) {
            pathPopup.close()
            window.pickingMode = mode
            window.originalMenu = "path"
        }
        onPathCalculated: function(result) {
            window.currentPathResult = result
        }
        onCloseRequested: function() {
            // 可选：清除路径显示等
        }
        onClosed: {
            if (window.activeMenu === "path") window.activeMenu = ""
        }
    }
    
    NearbyPopup {
        id: nearbyPopup
        x: menuBar.x
        y: menuBar.y + menuBar.height + 10
        spotsModel: campusBackend.spots
        backend: campusBackend
        getSpotIdByNameFn: getSpotIdByName
        onMapPickRequested: function(mode) {
            nearbyPopup.close()
            window.pickingMode = mode
            window.originalMenu = "nearby"
        }
        onPathCalculated: function(result) {
            window.currentPathResult = result
        }
        onCloseRequested: function() {
            // 可选：清理附近搜索状态
        }
        onClosed: {
            if (window.activeMenu === "nearby") window.activeMenu = ""
        }
    }

    // 辅助函数
    function getSpotIdByName(name) {
        var spots = campusBackend.spots
        for (var i = 0; i < spots.length; i++) {
            if (spots[i].name === name || (spots[i].id + " " + spots[i].name) === name) {
                return spots[i].id
            }
        }
        var num = parseInt(name)
        return isNaN(num) ? 1 : num
    }
    
    function getAllNodesData() {
        var nodes = []
        for (var i = 0; i < campusBackend.spots.length; i++) {
            nodes.push(JSON.parse(JSON.stringify(campusBackend.spots[i])))
        }
        for (var j = 0; j < campusBackend.nodes.length; j++) {
            nodes.push(JSON.parse(JSON.stringify(campusBackend.nodes[j])))
        }
        return nodes
    }
    
    function getAllEdgesData() {
        return campusBackend.edges || []
    }
    
    function findNodeById(id) {
        var nodes = getAllNodesData()
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].id === id) return nodes[i]
        }
        return null
    }
}