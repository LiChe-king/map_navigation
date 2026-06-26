# 广西大学校园导游系统

这是一个数据结构课程设计项目，基于 C++17、Qt 6 Quick/QML 和 CMake 实现。系统把校园地图抽象成无向带权图，支持景点查询、最短路径规划、附近设施搜索和可视化路网编辑。核心数据结构和算法均在 C++ 后端实现。

## 功能概览

### 用户功能

- **景点查询**：点击地图景点标记或从列表中选择景点，查看名称、类型、简介和地图位置。
- **最短路径**：选择起点和终点后，使用 Dijkstra 算法计算最短路径，并在地图上绘制路径。
- **附近搜索**：选择当前位置和设施类型，返回距离最近的设施列表，并可直接查看对应路线。

### 编辑功能

- **路网编辑**：进入编辑模式后，可查看景点节点、普通路点和道路边。
- **节点操作**：拖拽节点改变位置；Ctrl+点击节点连线；选中节点后可编辑景点信息或删除节点。
- **道路操作**：点击道路可删除连接。
- **数据持久化**：支持保存修改到 `data/` 下的文本数据文件。

## 数据结构设计

项目将校园路网抽象为图：

```text
Node  表示图的顶点，保存 id、x、y 坐标
Edge  表示图的边，保存目标节点 id 和距离权重
Spot  表示景点业务信息，保存 id、nodeId、名称、类型、简介
```

需要特别注意：`Spot` 不再保存 `x/y` 坐标。景点位置统一由 `Spot.nodeId` 指向的 `Node` 保存。

这样可以避免同一个景点坐标在 `Spot` 和 `Node` 中重复存储，减少拖拽、编辑、保存时的数据不同步问题。

## 核心数据文件

数据文件位于 `data/` 目录。

### `spots.txt`

景点信息文件，新格式如下：

```csv
# id,nodeId,name,type,intro
1,1,北西门,校门,校园西北侧出入口
```

字段含义：

```text
景点 id, 绑定的路网节点 id, 名称, 类型, 简介
```

说明：

- `id` 是景点自己的业务编号。
- `nodeId` 指向 `nodes.txt` 中的某个路网节点。
- 景点坐标不写在 `spots.txt` 中，而是写在 `nodes.txt` 中。
- 程序仍兼容旧格式 `id,name,type,intro,x,y` 的读取；保存后会写成新格式。

### `nodes.txt`

路网节点文件：

```csv
# id,x,y
1,1243.28,835.249
1001,1596.81,1156.36
```

字段含义：

```text
节点 id, 地图 x 坐标, 地图 y 坐标
```

景点节点和普通路口节点都存放在这里。是否为景点不再通过 `id < 1000` 判断，而是通过是否存在 `Spot.nodeId == Node.id` 判断。

### `edges.txt`

道路连接文件：

```csv
# from,to
1,1001
1001,1002
1002,65
```

字段含义：

```text
起点节点 id, 终点节点 id
```

文件只保存连接关系，不保存边权。程序加载边时，会根据两个节点的坐标和 `scale` 自动计算距离权重，并添加双向边。

### `config.txt`

配置文件：

```ini
scale = 0.42
school = 广西大学
map_image = campus_map.jpg
```

`scale` 用于将地图像素距离换算为实际距离。

## 核心代码结构

```text
CampusGuide/
|-- CMakeLists.txt
|-- main.cpp
|-- src/
|   |-- Spot.h               景点业务信息：id、nodeId、name、type、intro
|   |-- Node.h               路网节点：id、x、y
|   |-- Edge.h               邻接表中的边：to、weight
|   |-- RoadNetwork.h/cpp    路网邻接表、节点管理、边管理
|   |-- CampusGraph.h/cpp    校园图总管理，组合 Spot 和 RoadNetwork
|   |-- PathFinder.h/cpp     Dijkstra 最短路径、附近设施查询
|   |-- MinHeap.h            手写最小堆
|   |-- ParserUtils.h        文本解析辅助函数
|-- qml/                     Qt Quick 前端界面
|-- data/                    地图、景点、节点、道路和配置数据
```

## 算法说明

| 算法/结构 | 实现位置 | 说明 |
| --- | --- | --- |
| 邻接表 | `RoadNetwork` | 使用 `vector<vector<Edge>>` 存储校园路网 |
| ID 映射 | `RoadNetwork` | 使用 `unordered_map<int, int>` 将节点 ID 映射为数组下标，并提供只读映射给路径算法复用 |
| 景点索引 | `CampusGraph` | 使用哈希映射按景点 ID 和绑定节点 ID 快速查找景点 |
| 最小堆 | `MinHeap` | 手写 `heapifyUp` / `heapifyDown` |
| 最短路径 | `PathFinder::shortestPath` | Dijkstra 算法 |
| 附近搜索 | `PathFinder::nearestByType` | 从起点运行一次 Dijkstra，再筛选指定类型景点 |
| 排序 | `PathFinder::sortNearbyByDistance` | 手写插入排序 |

## 路径查询流程

1. 前端传入起点节点 ID 和终点节点 ID。
2. `PathFinder` 从 `CampusGraph` 获取所有 `Node` 和邻接表。
3. Dijkstra 使用 `MinHeap` 取出当前距离最短的候选节点。
4. 算法得到节点路径后，生成：
   - `nodeIds`：路径经过的所有节点 ID。
   - `spotIds`：路径中属于景点的景点 ID。
   - `drawPoints`：前端绘制路径用的坐标点。
   - `totalLength`：总距离。

景点路径判断通过 `getSpotByNodeId(nodeId)` 完成，不依赖节点编号范围。

## 维护优化

- `CampusGraph` 提供 `addSpotWithNode()`、`updateSpotWithNode()`、`removeSpotAndNode()`，集中维护景点和对应路网节点的同步关系。
- `PathFinder` 复用 `RoadNetwork` 的只读 `idToIndex` 映射，避免每次查询都重新构建节点 ID 映射。
- 附近搜索只运行一次 Dijkstra，再根据 `Spot.nodeId` 从距离数组中读取候选景点距离。
- 节点坐标更新后，`RoadNetwork` 会刷新与该节点相连边的权重，保证路径距离和地图坐标一致。

## 编译运行

环境要求：

- Qt 6.5+
- CMake 3.16+
- 支持 C++17 的编译器

常规构建：

```bash
cmake -S . -B build
cmake --build build
./build/CampusGuide
```

Windows + MinGW 下，如果用户目录包含中文导致汇编器报 `Illegal byte sequence`，可以临时指定 ASCII 路径作为临时目录：

```powershell
New-Item -ItemType Directory -Force build\tmp | Out-Null
$env:TMP = (Resolve-Path build\tmp).Path
$env:TEMP = $env:TMP
cmake --build build
```

## 阅读建议

建议按以下顺序阅读代码：

1. `src/Spot.h`、`src/Node.h`、`src/Edge.h`
2. `data/spots.txt`、`data/nodes.txt`、`data/edges.txt`
3. `src/RoadNetwork.h/cpp`
4. `src/CampusGraph.h/cpp`
5. `src/MinHeap.h`
6. `src/PathFinder.h/cpp`
7. `src/CampusBackend.h/cpp`
8. `qml/`

更详细的数据结构说明见 [CODE_GUIDE.md](CODE_GUIDE.md)。
