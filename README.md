# 广西大学校园导游系统

这是一个数据结构课程设计项目，基于 C++17、Qt 6 Quick/QML 和 CMake 实现。系统以图结构表示广西大学校园路网，支持景点查询、最短路径规划、附近设施搜索、可视化路网编辑等功能。**所有核心数据结构和算法均手写实现**，不调用标准库的排序、优先队列等算法函数。

## 功能

### 用户功能
- **景点查询**：在地图上点击景点图标或从列表中查看，显示景点详情（名称、类型、简介、坐标）
- **最短路径**：选择起点和终点（下拉框或地图选点），使用 Dijkstra 算法计算最短路径，在地图上绘制贴合道路弯曲的路线，显示经过的景点序列和总距离
- **附近搜索**：选择当前位置和设施类型，返回距离最近的设施列表，点击可直接规划路径

### 管理员功能（编辑模式）
- **可视化路网编辑**：进入编辑模式后，所有节点（景点+路口）和道路直接显示在地图上
- **节点操作**：拖拽移动节点位置；Ctrl+点击节点开始连线，再点击另一节点完成连线添加道路；选中节点后在右侧面板查看/编辑信息；删除路口节点
- **道路操作**：点击道路直接删除
- **数据持久化**：手动保存到文件或撤销修改

## 数据存储格式

### `spots.txt`（景点数据）
```csv
# id,name,type,intro,x,y
1,北西门,校门,校园西北侧出入口,215,122
65,图书馆,图书馆,全校文献藏书、阅览核心场馆,926,1142
```

### `nodes.txt`（路口节点）
```csv
# id,x,y
1001,400,520
1002,490,600
```

### `edges.txt`（道路连接）
```csv
# from,to
1,1001
1001,1002
1002,65
```

### `config.txt`（配置）
```ini
scale = 0.35
school = 广西大学
map_image = campus_map.jpg
```

## 算法说明

| 算法 | 实现位置 | 复杂度 | 说明 |
|------|----------|--------|------|
| 图存储 | `CampusGraph` / `RoadNetwork` | - | 邻接表，景点与路口统一建模 |
| 最小堆 | `MinHeap` | 插入/删除 O(log n) | 手写 `heapifyUp` / `heapifyDown` |
| 最短路径 | `PathFinder::shortestPath` | O((V+E)logV) | Dijkstra + 手写堆 |
| 所有路径 | `PathFinder::allSimplePaths` | O(V!) 指数级 | DFS 回溯 |
| 附近排序 | `PathFinder::sortNearbyByDistance` | O(n²) | 手写插入排序 |

## 编译运行

**环境要求**：Qt 6.5+、CMake 3.16+、C++17 编译器

```bash
cmake -S . -B build
cmake --build build
./build/CampusGuide
```

Windows 下可在 Qt Creator 中打开 `CMakeLists.txt`，选择 Qt 6 套件后构建运行。数据文件需放在可执行文件同目录的 `data/` 文件夹下。

## 项目结构

```
CampusGuide/
├── CMakeLists.txt          # 构建配置
├── main.cpp                # 程序入口
├── src/                    # C++ 源码
│   ├── CampusBackend.h/cpp # 暴露给 QML 的接口
│   ├── CampusGraph.h/cpp   # 校园图总控
│   ├── RoadNetwork.h/cpp   # 路网核心（邻接表+节点/边管理）
│   ├── PathFinder.h/cpp    # 路径算法（Dijkstra/DFS）
│   ├── MinHeap.h           # 手写最小堆
│   ├── ParserUtils.h       # 文件解析辅助
│   └── Spot.h, Node.h, Edge.h
├── qml/                    # QML 界面
│   ├── main.qml            # 主窗口
│   ├── MapPage.qml         # 地图页面（含编辑模式）
│   ├── PathDrawer.qml      # 路径绘制组件
│   └── MenuButton.qml      # 菜单按钮
└── data/                   # 数据文件
    ├── spots.txt, nodes.txt, edges.txt, config.txt
    └── campus_map.jpg
```