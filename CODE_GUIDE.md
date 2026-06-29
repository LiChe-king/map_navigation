# CampusGuide 代码说明文档

本文档用于说明广西大学校园导游系统的代码结构、数据流、核心数据结构和主要算法。阅读目标是快速理解：数据文件如何进入内存，校园路网如何被建模，路径查询如何运行，以及 QML 前端如何调用 C++ 后端。

## 1. 项目整体结构

项目基于 C++17、Qt 6 Quick/QML 和 CMake 实现。前端负责地图展示和交互，后端负责数据管理、文件读写、图结构维护和路径算法。

```text
CampusGuide/
|-- main.cpp                 程序入口，创建 QGuiApplication 并加载 QML
|-- CMakeLists.txt           Qt/CMake 构建配置
|-- src/                     C++ 后端代码
|   |-- Spot.h               景点业务结构
|   |-- Node.h               路网节点结构
|   |-- Edge.h               道路边结构
|   |-- RoadNetwork.h/cpp    路网邻接表、节点和边操作
|   |-- CampusGraph.h/cpp    校园图总管理、景点索引、文件读写
|   |-- PathFinder.h/cpp     最短路径和附近设施查询
|   |-- MinHeap.h            Dijkstra 使用的手写最小堆
|   |-- CampusBackend.h/cpp  暴露给 QML 的 QObject 后端
|   |-- ParserUtils.h        文本解析辅助函数
|-- qml/                     Qt Quick 前端界面
|-- data/                    地图图片、景点、节点、道路和配置数据
```

程序启动流程：

1. `main.cpp` 创建 `CampusBackend backend`。
2. 调用 `backend.load()` 从 `data/` 读取配置、节点、景点和道路。
3. 通过 `engine.rootContext()->setContextProperty("campusBackend", &backend)` 把后端对象注入 QML。
4. QML 通过 `campusBackend.spots()`、`findShortestPath()` 等接口读取数据或发起操作。

## 2. 核心数据模型

系统把校园地图抽象为无向带权图。图中的顶点是 `Node`，边是 `Edge`，景点业务信息是 `Spot`。

### 2.1 Spot：景点业务信息

位置：`src/Spot.h`

```cpp
struct Spot {
    int id = -1;
    int nodeId = -1;
    std::string name;
    std::string type;
    std::string intro;
};
```

字段说明：

| 字段 | 含义 |
| --- | --- |
| `id` | 景点编号，用于查询和显示 |
| `nodeId` | 景点绑定的路网节点 ID |
| `name` | 景点名称 |
| `type` | 景点类型，如校门、食堂、教学楼等 |
| `intro` | 景点简介 |

注意：`Spot` 不保存 `x/y` 坐标。景点位置统一由 `nodeId` 指向的 `Node` 保存，避免景点信息和路网节点各自保存坐标造成不同步。

### 2.2 Node：路网节点

位置：`src/Node.h`

```cpp
struct Node {
    int id = -1;
    double x = 0.0;
    double y = 0.0;
};
```

`Node` 是路径算法真正使用的图顶点。节点分为两类：

- 景点节点：被某个 `Spot.nodeId` 引用，项目约定 ID 小于 `1000`。
- 普通路点：只用于描述道路转折、路口和连通关系，项目约定 ID 从 `1000` 开始。

编辑和新增逻辑使用 `1000` 作为景点与路点的编号分界：新增景点只使用 `1-999` 的空闲 ID，新增路点使用 `1000` 及以上 ID。运行时判断一个节点是否是景点节点，仍通过 `CampusGraph::hasSpotNode(nodeId)` 判断，这样可以避免仅靠编号范围误判历史数据或异常数据。

### 2.3 Edge：邻接表中的边

位置：`src/Edge.h`

```cpp
struct Edge {
    int to = -1;
    int weight = 0;
};
```

字段说明：

| 字段 | 含义 |
| --- | --- |
| `to` | 目标节点 ID |
| `weight` | 按比例尺换算后的道路长度 |

`Edge::to` 存的是节点 ID，不是数组下标。算法访问邻接节点时，需要通过 `idToIndex` 把节点 ID 转换为 `nodes` 数组下标。

## 3. 数据文件加载流程

数据入口位于 `CampusBackend::load()`：

```text
CampusBackend::load()
  -> CampusGraph::loadFromFiles()
       -> 读取 config.txt
       -> RoadNetwork::loadNodes()
       -> 读取 spots.txt
       -> rebuildSpotMaps()
       -> RoadNetwork::loadEdges()
```

加载顺序很重要：

1. 先读 `config.txt`，得到比例尺 `scale`、学校名和地图文件名。
2. 再读 `nodes.txt`，建立全部路网节点和 `idToIndex` 映射。
3. 再读 `spots.txt`，建立景点列表。当前格式中景点节点 ID 默认等于景点 ID，坐标从 `nodes.txt` 中读取。
4. 重建景点索引 `spotIdToIndex` 和 `spotNodeToIndex`。
5. 最后读 `edges.txt`，此时所有节点已存在，才能正确建立道路边。

`spots.txt` 当前格式为：

```csv
# id,name,type,intro
1,北西门,校门,校园西北侧出入口
```

景点文件不再保存 `x/y` 坐标，所有坐标统一由 `nodes.txt` 管理。程序仍兼容两种历史格式：

```csv
# 带坐标的旧格式
id,name,type,intro,x,y

# 显式 nodeId 的旧格式
id,nodeId,name,type,intro
```

读取 `id,name,type,intro,x,y` 时，代码会令 `spot.nodeId = spot.id`，并在路网中自动补充对应节点；读取 `id,nodeId,name,type,intro` 时会保留显式绑定关系。保存时统一写回当前格式 `id,name,type,intro`。

## 4. RoadNetwork：路网邻接表

位置：`src/RoadNetwork.h/cpp`

`RoadNetwork` 是图结构的核心容器：

```cpp
std::vector<Node> nodes;
std::vector<std::vector<Edge>> adj;
std::unordered_map<int, int> idToIndex;
double scale = 0.35;
```

三者关系如下：

```text
nodes[i]          第 i 个路网节点
adj[i]            第 i 个节点的邻接边列表
idToIndex[id]     节点 ID 到 nodes 下标的映射
```

设计原因：

- `nodes` 顺序存储，便于遍历和传给前端。
- `adj` 使用邻接表，适合校园路网这种稀疏图。
- `idToIndex` 解决节点 ID 不连续的问题，避免用 ID 直接当数组下标。

### 4.1 节点操作

`addNode()` 会把节点追加到 `nodes`，同时扩展一条空邻接表并写入 `idToIndex`。

`removeNode()` 会先调用 `removeEdgesOfNode()` 删除所有相关边，再删除节点和对应邻接表，最后重建 `idToIndex`。

`updateNode()` 更新坐标后，会调用 `refreshEdgeWeightsOfNode()` 刷新与该节点相连道路的权重，保证拖拽节点后路径距离仍然正确。

### 4.2 边操作

`addEdge(from, to)` 会检查：

1. 起点和终点不能相同。
2. 两个节点必须都存在。
3. 边不能重复添加。

通过检查后，边权按下面公式计算：

```text
像素距离 = sqrt((x1 - x2)^2 + (y1 - y2)^2)
实际距离 = 像素距离 * scale
weight = 四舍五入后的实际距离
```

添加时会自动生成双向边：

```text
from -> to
to   -> from
```

因此整个校园路网是无向带权图。保存到 `edges.txt` 时，为避免重复写入，只保存 `fromId < toId` 的一份连接。

## 5. CampusGraph：校园图总管理

位置：`src/CampusGraph.h/cpp`

`CampusGraph` 组合景点和路网：

```cpp
std::vector<Spot> spots;
std::unordered_map<int, int> spotIdToIndex;
std::unordered_map<int, int> spotNodeToIndex;
RoadNetwork roadNetwork;
std::string schoolName;
std::string mapImage;
```

它负责三类事情：

- 加载和保存 `config.txt`、`spots.txt`、`nodes.txt`、`edges.txt`。
- 管理景点增删改查。
- 把节点和道路操作代理给 `RoadNetwork`。

### 5.1 两个景点索引

`CampusGraph` 维护两张哈希表：

```text
spotIdToIndex[spotId]       景点 ID -> spots 数组下标
spotNodeToIndex[nodeId]     景点绑定节点 ID -> spots 数组下标
```

因此下面这些查询都可以快速完成：

- `getSpotById(id)`
- `getSpotByNodeId(nodeId)`
- `hasSpot(id)`
- `hasSpotNode(nodeId)`

每次景点增删改后都会调用 `rebuildSpotMaps()` 重建索引。

### 5.2 景点和节点同步

景点信息在 `Spot` 中，坐标在 `Node` 中，所以增删改景点时必须同步维护对应节点。

`CampusGraph` 提供三个组合接口：

```text
addSpotWithNode()
updateSpotWithNode()
removeSpotAndNode()
```

这些接口保证：

- 新增景点时，景点和绑定节点一起加入。
- 修改景点时，业务信息和节点坐标一起更新。
- 删除景点时，对应节点及相关道路边也一起删除。

这样 `CampusBackend` 不需要重复处理“先改景点，再改节点”的细节。

## 6. PathFinder：路径查询

位置：`src/PathFinder.h/cpp`

`PathFinder` 不持有数据，只保存一个 `CampusGraph` 指针：

```cpp
const CampusGraph* graph = nullptr;
```

查询时从 `CampusGraph` 读取节点数组、邻接表和索引映射。

### 6.1 最短路径

入口：

```cpp
PathResult shortestPath(int fromId, int toId) const;
```

流程：

1. 使用 `graph->getNodeIndexMap()` 检查起点和终点是否存在。
2. 调用 `runDijkstra(fromId, dist, prev, targetIdx)`。
3. 如果终点不可达，返回空结果。
4. 通过 `prev` 数组从终点反向恢复路径。
5. 调用 `buildPathFromNodeIndices()` 生成前端可用结果。

结果结构：

```cpp
struct PathResult {
    std::vector<int> nodeIds;
    std::vector<int> spotIds;
    std::vector<std::pair<double, double>> drawPoints;
    int totalLength = 0;
};
```

字段含义：

| 字段 | 含义 |
| --- | --- |
| `nodeIds` | 路径经过的所有路网节点 ID |
| `spotIds` | 路径中属于景点的景点 ID |
| `drawPoints` | 前端绘制路径线所需坐标 |
| `totalLength` | 路径总长度 |

`spotIds` 通过 `graph->getSpotByNodeId(node.id)` 判断，不通过节点编号范围判断。

### 6.2 所有可选简单路径

入口：

```cpp
std::vector<PathResult> allSimplePaths(int fromId, int toId, int maxCount = 3) const;
```

该接口用于查询任意两个景点之间距离较短的可选简单路径。简单路径要求同一条路径中不重复经过同一个节点，因此不会出现绕圈路径。实现采用“基于最短路径偏离”的思路，而不是全图暴力枚举：

1. 先用 Dijkstra 得到第 1 条最短路径。
2. 以已找到的路径为基础，依次选择路径中的某个节点作为偏离点。
3. 保留起点到偏离点之前的最短路径前缀。
4. 临时禁止继续走已找到路径在该偏离点后的下一条边。
5. 从偏离点重新运行 Dijkstra 接回终点，生成一条候选路径。
6. 对候选路径按总长度排序，取最短的一条作为下一条可选路径。
7. 重复以上过程，直到得到 `maxCount` 条或没有更多合理候选。

前端默认只请求 3 条，用于避免复杂路网中简单路径数量过多导致界面卡顿。

### 6.3 Dijkstra 实现

核心函数：

```cpp
void runDijkstra(int fromId, std::vector<int>& dist,
                 std::vector<int>& prev, int stopIdx = -1) const;
```

使用的数组：

```text
dist[i]      起点到第 i 个节点的当前最短距离
prev[i]      最短路径上第 i 个节点的前驱节点下标
visited[i]   第 i 个节点是否已经确定最短距离
```

`stopIdx` 用于最短路径查询：当目标节点已确定最短距离时可以提前退出。附近搜索需要起点到所有节点的距离，因此不传 `stopIdx`。

### 6.4 附近设施搜索

入口：

```cpp
std::vector<NearbyResult> nearestByType(int fromId,
                                        const std::string& type,
                                        int limit) const;
```

流程：

1. 从起点运行一次 Dijkstra，得到到所有节点的最短距离。
2. 遍历所有 `Spot`，筛选 `spot.type == type` 的景点。
3. 通过 `spot.nodeId` 找到对应节点下标和距离。
4. 恢复从起点到该景点的路径。
5. 使用插入排序按距离升序排列。
6. 截取前 `limit` 个结果。

这种实现比“每个候选景点单独跑一次 Dijkstra”更高效，因为一次 Dijkstra 就能得到起点到所有节点的最短距离。

## 7. MinHeap：手写最小堆

位置：`src/MinHeap.h`

Dijkstra 使用 `MinHeap` 取出当前距离最小的候选节点。

```cpp
struct HeapNode {
    int vertex = -1;
    int distance = 0;
};
```

这里的 `vertex` 是 `nodes` 数组下标，不是节点 ID。

主要操作：

- `push()`：插入元素后通过 `heapifyUp()` 上浮。
- `pop()`：弹出堆顶后通过 `heapifyDown()` 下沉。
- `isEmpty()`：判断堆是否为空。

堆中可能存在同一节点的多个候选距离。`runDijkstra()` 通过 `visited` 数组跳过已经确定最短距离的节点。

## 8. CampusBackend：QML 后端接口

位置：`src/CampusBackend.h/cpp`

`CampusBackend` 继承 `QObject`，负责把 C++ 数据转换为 QML 能直接使用的 `QVariantMap` 和 `QVariantList`。

暴露的属性：

```cpp
Q_PROPERTY(QVariantList spots READ spots NOTIFY spotsChanged)
Q_PROPERTY(QVariantList nodes READ nodes NOTIFY nodesChanged)
Q_PROPERTY(QVariantList edges READ edges NOTIFY edgesChanged)
```

常用接口：

```text
load() / save()
spots() / nodes() / edges()
spotDetail(id)
spotDetailByNode(nodeId)
isSpotNode(nodeId)
findShortestPath(fromId, toId)
findAllPaths(fromId, toId, limit)
findNearby(fromId, type, limit)
addSpot(...) / updateSpot(...) / removeSpot(...)
addNode(...) / updateNode(...) / removeNode(...)
addEdge(from, to) / removeEdge(from, to)
```

数据转换示例：

```text
Spot       -> { id, nodeId, name, type, intro, x, y }
Node       -> { id, x, y, isSpot }
PathResult -> { ids, names, points, length }
```

其中 `Spot` 转给 QML 时会临时补上 `x/y`，但真实坐标仍来自绑定的 `Node`。

### 8.1 立即保存和仅改内存

后端有两组操作：

```text
add/update/remove...       修改内存后立即 save()
add/update/remove...Only   只修改内存，不立即保存文件
```

编辑界面可以用 `Only` 版本提高交互效率，等用户确认后再调用 `save()` 统一写入文件。

### 8.2 ID 分界保护

`CampusBackend` 使用 `ROAD_NODE_START_ID = 1000` 保护新增接口：

- `addSpot()` / `addSpotOnly()` 要求景点 ID 小于 `1000`。
- `addNode()` / `addNodeOnly()` 要求普通路点 ID 大于等于 `1000`。

这样可以和前端编辑逻辑保持一致，避免新增数据破坏“景点 `<1000`，路点 `>=1000`”的编号约定。

## 9. QML 前端组织

前端位于 `qml/` 目录，主要文件职责如下：

```text
main.qml                 应用主界面和整体状态管理
MapPage.qml              地图区域、缩放、拖动、地图点击
MapWorkspace.qml         地图页与编辑面板的组合
SpotMarkersLayer.qml     景点标记显示和点击
MapNodeLayer.qml         编辑模式下的节点显示、拖拽和连线
MapEdgesLayer.qml        道路边显示和删除
PathDrawer.qml           按 PathResult.points/paths 绘制单条或多条路径
NavigationPopups.qml     查询、路径、附近搜索弹窗管理
PathPopup.qml            最短路径查询弹窗
NearbyPopup.qml          附近搜索弹窗
QueryPopup.qml           景点查询弹窗，支持类型筛选和关键词搜索
EditorPanel.qml          编辑模式工具面板
SpotEditForm.qml         景点编辑表单
```

QML 不直接维护复杂数据结构，而是通过 `campusBackend` 获取列表、提交编辑操作和发起路径查询。

路径查询结果会把最短路径放在 `paths[0]`，其他可选路径放在后续位置。地图绘制时最短路径保持蓝色，其他可选路径统一使用橙色，并在与最短路径分叉后的独立路段上标注 `2`、`3` 等序号，以便同时对比多条路线。

`QueryPopup.qml` 会从 `spotsModel` 中提取全部景点类型，生成“全部类型 + 类型列表”的下拉框；搜索框会在景点名称、类型和简介中做关键词匹配。筛选结果保存到 `filteredSpotsModel`，列表只渲染筛选后的景点。

`EditActions.qml` 中的新增逻辑也遵守 ID 分界：`nextSpotId()` 在 `1-999` 中寻找空闲 ID，`nextRoadNodeId()` 从现有路点最大 ID 继续递增并保证不小于 `1000`。

## 10. 数据结构课程设计对应点

| 实践点 | 代码位置 | 说明 |
| --- | --- | --- |
| 顺序表 | `std::vector<Spot>`、`std::vector<Node>` | 存储景点和路网节点 |
| 图 | `RoadNetwork` | 校园道路抽象为无向带权图 |
| 邻接表 | `std::vector<std::vector<Edge>> adj` | 存储稀疏路网 |
| 哈希映射 | `idToIndex`、`spotIdToIndex`、`spotNodeToIndex` | 支持快速索引 |
| 堆 | `MinHeap` | Dijkstra 中取最小距离节点 |
| 最短路径 | `PathFinder::shortestPath` | Dijkstra 算法 |
| 单源多目标查询 | `PathFinder::nearestByType` | 一次 Dijkstra 后筛选附近设施 |
| 排序 | `sortNearbyByDistance` | 插入排序 |
| 文件持久化 | `loadFromFiles()`、`saveToFiles()` | 文本文件读写 |

可以这样概括项目主线：

```text
校园地图 -> 路网节点和道路边 -> 邻接表无向带权图
景点信息 -> Spot 业务数据 -> 通过 nodeId 绑定到路网节点
路径查询 -> Dijkstra + 最小堆 -> 输出路径节点、坐标点和总距离
前端展示 -> QML 调用 CampusBackend -> 绘制地图、景点和路线
```

## 11. 推荐阅读顺序

第一次阅读代码建议按下面顺序：

1. `src/Spot.h`、`src/Node.h`、`src/Edge.h`
2. `data/spots.txt`、`data/nodes.txt`、`data/edges.txt`
3. `src/RoadNetwork.h/cpp`
4. `src/CampusGraph.h/cpp`
5. `src/MinHeap.h`
6. `src/PathFinder.h/cpp`
7. `src/CampusBackend.h/cpp`
8. `qml/MapPage.qml`、`qml/NavigationPopups.qml`、`qml/EditorPanel.qml`

这样可以先抓住数据结构和算法主线，再理解界面如何调用后端。
