import QtQuick

Item {
    id: root

    property real popupX: 0
    property real popupY: 0
    property var spotsModel: []
    property var backend: null
    property var getSpotIdByNameFn: null
    property string activeMenu: ""

    signal spotSelected(var spot)
    signal pathCalculated(var result)
    signal mapPickRequested(string mode, string menuName)

    QueryPopup {
        id: queryPopup
        x: root.popupX
        y: root.popupY
        spotsModel: root.spotsModel

        onSpotSelected: function(spot) {
            root.spotSelected(spot)
        }
        onClosed: {
            if (root.activeMenu === "query") root.activeMenu = ""
        }
    }

    PathPopup {
        id: pathPopup
        x: root.popupX
        y: root.popupY
        spotsModel: root.spotsModel
        backend: root.backend
        getSpotIdByNameFn: root.getSpotIdByNameFn

        onMapPickRequested: function(mode) {
            pathPopup.close()
            root.mapPickRequested(mode, "path")
        }
        onPathCalculated: function(result) {
            root.pathCalculated(result)
        }
        onClosed: {
            if (root.activeMenu === "path") root.activeMenu = ""
        }
    }

    NearbyPopup {
        id: nearbyPopup
        x: root.popupX
        y: root.popupY
        spotsModel: root.spotsModel
        backend: root.backend
        getSpotIdByNameFn: root.getSpotIdByNameFn

        onMapPickRequested: function(mode) {
            nearbyPopup.close()
            root.mapPickRequested(mode, "nearby")
        }
        onPathCalculated: function(result) {
            root.pathCalculated(result)
        }
        onClosed: {
            if (root.activeMenu === "nearby") root.activeMenu = ""
        }
    }

    function openPopup(menuName) {
        closeAll()
        if (menuName === "query") queryPopup.open()
        else if (menuName === "path") pathPopup.open()
        else if (menuName === "nearby") nearbyPopup.open()
        root.activeMenu = menuName
    }

    function closeAll() {
        if (queryPopup.visible) queryPopup.close()
        if (pathPopup.visible) pathPopup.close()
        if (nearbyPopup.visible) nearbyPopup.close()
    }

    function reopen(menuName) {
        if (menuName === "path") pathPopup.open()
        else if (menuName === "nearby") nearbyPopup.open()
    }

    function setPickedSpot(mode, spotName) {
        pathPopup.setPickedSpot(mode, spotName)
        nearbyPopup.setPickedSpot(mode, spotName)
    }
}
