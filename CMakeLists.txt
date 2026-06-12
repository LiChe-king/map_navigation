cmake_minimum_required(VERSION 3.16)

project(CampusGuide VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(CampusGuide
    main.cpp
    src/CampusBackend.cpp
    src/CampusGraph.cpp
    src/PathFinder.cpp
    src/RoadNetwork.cpp
)

qt_add_qml_module(CampusGuide
    URI CampusGuide
    VERSION 1.0
    QML_FILES
        qml/main.qml
        qml/MapPage.qml
        qml/PathDrawer.qml
        qml/MenuButton.qml
        qml/EditorPanel.qml
        qml/CustomMenuBar.qml
        qml/PathPopup.qml
        qml/NearbyPopup.qml
        qml/QueryPopup.qml
    RESOURCES
        data/spots.txt
        data/nodes.txt
        data/edges.txt
        data/config.txt
        data/campus_map.jpg
        data/icon.ico
        data/ZiHunBianTaoTi-2.ttf
)

target_include_directories(CampusGuide PRIVATE src)

target_link_libraries(CampusGuide
    PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
)
