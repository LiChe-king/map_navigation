# 广西大学校园导游系统

广西大学校园导游系统是一个数据结构课程设计项目，基于 C++17、Qt 6 Quick/QML 和 CMake 实现。系统把校园地图抽象为无向带权图，用节点表示景点、路口和道路转折点，用边表示可通行道路，从而实现景点查询、最短路径规划、附近设施搜索和可视化路网编辑。

项目核心逻辑由 C++ 后端完成，包括数据文件读写、路网维护、景点管理、Dijkstra 最短路径和附近搜索；QML 前端负责地图展示、弹窗交互、路径绘制和编辑操作。

## 功能概览

### 游览功能

- **景点查询**：可在地图上点击景点标记，或从查询弹窗中选择景点，查看景点名称、类型、简介和位置。
- **地图定位**：选择景点后，地图视图可跳转到对应位置，并突出显示当前目标。
- **最短路径**：选择起点和终点后，后端使用 Dijkstra 算法计算最短路径，前端在地图上绘制路线。
- **附近搜索**：选择当前位置和设施类型后，系统返回距离最近的若干设施，并可查看到达路线。

### 编辑功能

- **路网可视化**：编辑模式下显示景点节点、普通路点和道路边，便于检查校园路网。
- **节点编辑**：支持新增、拖拽、修改和删除节点；景点节点可同步编辑名称、类型和简介。
- **道路编辑**：支持为两个节点建立道路连接，也支持删除已有道路。
- **数据保存**：编辑结果可写回 `data/` 目录下的文本数据文件。

## 技术栈

- C++17
- Qt 6.5+、Qt Quick/QML
- CMake 3.16+
- 邻接表、哈希映射、手写最小堆
- Dijkstra 最短路径算法、插入排序

## 项目结构

```text
CampusGuide/
|-- CMakeLists.txt              Qt/CMake 构建配置
|-- main.cpp                    程序入口，加载后端和 QML
|-- README.md                   项目使用说明
|-- CODE_GUIDE.md               代码结构和算法说明
|-- data/                       地图资源和文本数据
|   |-- campus_map.jpg          校园地图图片
|   |-- config.txt              比例尺、学校名、地图文件配置
|   |-- spots.txt               景点信息
|   |-- nodes.txt               路网节点
|   |-- edges.txt               道路连接
|-- qml/                        Qt Quick 前端界面
|-- src/                        C++ 后端和核心数据结构
    |-- Spot.h                  景点业务信息
    |-- Node.h                  路网节点
    |-- Edge.h                  道路边
    |-- RoadNetwork.h/cpp       邻接表路网、节点和边管理
    |-- CampusGraph.h/cpp       校园图总管理、景点索引、文件读写
    |-- PathFinder.h/cpp        最短路径和附近设施查询
    |-- MinHeap.h               手写最小堆
    |-- CampusBackend.h/cpp     QML 可调用的后端接口
    |-- ParserUtils.h           文本解析辅助函数
```

## 数据模型

系统中的核心数据分为三类：

```text
Spot  景点业务信息：id、nodeId、name、type、intro
Node  路网节点：id、x、y
Edge  道路边：to、weight
```

`Spot` 不直接保存坐标。景点位置由 `Spot.nodeId` 指向的 `Node` 决定。这样可以保证景点显示、路径计算和拖拽编辑使用同一份坐标数据，避免重复存储导致不同步。

路网使用邻接表表示：

```text
nodes[i]      第 i 个路网节点
adj[i]        第 i 个节点的邻接边列表
idToIndex     节点 ID 到数组下标的映射
```

道路边权不直接写在文件中，而是根据两个节点的地图坐标和 `scale` 自动计算。

## 数据文件

数据文件位于 `data/` 目录。

### `spots.txt`

```csv
# id,nodeId,name,type,intro
1,1,北西门,校门,校园西北侧出入口
```

字段含义：

- `id`：景点编号。
- `nodeId`：景点绑定的路网节点 ID。
- `name`：景点名称。
- `type`：景点类型。
- `intro`：景点简介。

程序兼容旧格式 `id,name,type,intro,x,y` 的读取，但保存时会写回当前格式。

### `nodes.txt`

```csv
# id,x,y
1,1243.28,835.249
1001,1596.81,1156.36
```

景点节点和普通路点都存放在这里。节点是否为景点，通过是否存在 `Spot.nodeId == Node.id` 判断。

### `edges.txt`

```csv
# from,to
1,1001
1001,1002
```

文件只保存道路连接关系。程序加载时会自动计算边权并添加双向边，因此路网是无向带权图。

### `config.txt`

```ini
scale = 0.42
school = 广西大学
map_image = campus_map.jpg
```

`scale` 用于把地图像素距离换算成实际距离。

## 核心算法

| 内容 | 实现位置 | 说明 |
| --- | --- | --- |
| 路网存储 | `RoadNetwork` | 使用邻接表保存校园无向带权图 |
| 节点索引 | `RoadNetwork` | 使用 `unordered_map` 将节点 ID 映射到数组下标 |
| 景点索引 | `CampusGraph` | 按景点 ID 和绑定节点 ID 快速查找景点 |
| 最小堆 | `MinHeap` | 为 Dijkstra 提供最小距离节点弹出能力 |
| 最短路径 | `PathFinder::shortestPath` | 计算两点之间的最短路线 |
| 附近搜索 | `PathFinder::nearestByType` | 一次 Dijkstra 后筛选指定类型景点 |
| 结果排序 | `PathFinder::sortNearbyByDistance` | 用插入排序按距离升序排列 |

## 编译运行

环境要求：

- Qt 6.5 或更高版本
- CMake 3.16 或更高版本
- 支持 C++17 的编译器

常规构建：

```bash
cmake -S . -B build
cmake --build build
./build/CampusGuide
```

Windows + MinGW 环境下，如果用户目录包含中文并导致汇编器报 `Illegal byte sequence`，可以临时指定 ASCII 路径作为临时目录：

```powershell
New-Item -ItemType Directory -Force build\tmp | Out-Null
$env:TMP = (Resolve-Path build\tmp).Path
$env:TEMP = $env:TMP
cmake --build build
```

## 阅读建议

如果只是了解项目功能，先阅读本文件即可。

如果需要理解代码实现，建议继续阅读 [CODE_GUIDE.md](CODE_GUIDE.md)，并按下面顺序查看源码：

1. `src/Spot.h`、`src/Node.h`、`src/Edge.h`
2. `data/spots.txt`、`data/nodes.txt`、`data/edges.txt`
3. `src/RoadNetwork.h/cpp`
4. `src/CampusGraph.h/cpp`
5. `src/MinHeap.h`
6. `src/PathFinder.h/cpp`
7. `src/CampusBackend.h/cpp`
8. `qml/`
