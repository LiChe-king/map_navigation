# CampusGuide 代码说明文档

本文档用于帮助快速读懂本项目代码，重点说明数据结构、文件数据如何进入内存、路径算法如何使用这些结构。前端 QML 只做必要说明，核心关注 C++ 后端。

## 1. 项目整体结构

项目是一个校园导游系统，用地图上的点和边表示校园道路网络，并支持景点查看、最短路径、附近设施查询和路网编辑。

主要目录如下：

```text
CampusGuide/
|-- main.cpp                 程序入口，注册后端对象并加载 QML
|-- CMakeLists.txt           Qt/CMake 构建配置
|-- src/                     C++ 后端和数据结构
|   |-- Spot.h               景点结构
|   |-- Node.h               路网节点结构
|   |-- Edge.h               边结构
|   |-- RoadNetwork.h/cpp    路网邻接表、节点和边操作
|   |-- CampusGraph.h/cpp    校园图总管理，统一景点和路网
|   |-- PathFinder.h/cpp     最短路径和附近搜索
|   |-- MinHeap.h            手写最小堆
|   |-- ParserUtils.h        文本解析辅助函数
|-- data/
|   |-- spots.txt            景点数据
|   |-- nodes.txt            路口节点数据
|   |-- edges.txt            道路连接数据
|   |-- config.txt           地图比例尺、学校名称、地图图片
|-- qml/                     前端界面
```

阅读代码时建议先看 `src/Spot.h`、`src/Node.h`、`src/Edge.h`，再看 `src/RoadNetwork.h/cpp`，最后看 `src/PathFinder.cpp` 和 `src/CampusBackend.cpp`。

## 2. 数据文件和内存模型

系统启动后，`CampusBackend::load()` 会调用 `CampusGraph::loadFromFiles()` 读取四类文件：

```text
data/config.txt -> 比例尺、学校名称、地图图片
data/nodes.txt  -> 普通路口节点
data/spots.txt  -> 景点
data/edges.txt  -> 路网连接关系
```

加载顺序很重要：

1. 先读取 `config.txt`，得到比例尺 `scale`。
2. 再读取 `nodes.txt`，把普通路口节点加入 `RoadNetwork`。
3. 再读取 `spots.txt`，把景点加入 `CampusGraph::spots`。
4. 每个景点通过 `nodeId` 关联一个路网 `Node`。
5. 最后读取 `edges.txt`，此时路网中已经同时包含路口节点和景点节点，边才能正确连接。

这意味着项目里有两类“点”：

```text
Spot  景点信息：有名称、类型、简介、nodeId，用于展示和查询
Node  路网点：有 id、x、y，用于建图、路径计算和保存坐标
```

景点信息存在 `Spot` 中，坐标存在对应的 `Node` 中。普通路口只存在于 `Node` 中，不存在于 `Spot` 中。

## 3. 核心数据结构

### 3.1 Spot：景点信息

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

字段含义：

| 字段 | 含义 |
| --- | --- |
| `id` | 景点唯一编号 |
| `nodeId` | 该景点绑定的路网节点 ID |
| `name` | 景点名称 |
| `type` | 景点类型，如校门、食堂、教学楼等 |
| `intro` | 景点简介 |

`Spot` 主要用于界面展示、景点详情、附近设施筛选。路径算法本身不直接依赖 `Spot` 坐标，而是使用 `spot.nodeId` 找到对应的 `Node`。

### 3.2 Node：路网节点

位置：`src/Node.h`

```cpp
struct Node {
    int id = -1;
    double x = 0.0;
    double y = 0.0;
};
```

`Node` 是图中的顶点，包括两种来源：

```text
普通路口：来自 nodes.txt，通常 id >= 1000
景点节点：来自 nodes.txt 或旧版 spots.txt，ID 由 Spot.nodeId 指向
```

项目通过统一的 `Node` 来建图，所以最短路径可以从景点到景点，也可以经过普通路口。

### 3.3 Edge：邻接表中的边

位置：`src/Edge.h`

```cpp
struct Edge {
    int to = -1;
    int weight = 0;
};
```

`Edge` 表示从当前节点指向目标节点的一条边：

| 字段 | 含义 |
| --- | --- |
| `to` | 目标节点的 ID |
| `weight` | 边权重，也就是按比例尺换算后的距离 |

需要注意：`Edge::to` 存的是节点 ID，不是数组下标。查找邻居节点时，需要通过 ID 映射找到它在 `nodes` 数组中的位置。

### 3.4 RoadNetwork：邻接表路网

位置：`src/RoadNetwork.h/cpp`

`RoadNetwork` 是项目最核心的数据结构，内部维护三份数据：

```cpp
std::vector<Node> nodes;
std::vector<std::vector<Edge>> adj;
std::unordered_map<int, int> idToIndex;
double scale = 0.35;
```

它们之间的关系如下：

```text
nodes[i]              第 i 个节点
adj[i]                第 i 个节点的所有出边
idToIndex[nodeId]     节点 ID 到 nodes 数组下标的映射
```

例子：

```text
nodes[0] = Node{id=1001, x=1596.81, y=1156.36}
idToIndex[1001] = 0
adj[0] = [{to=1003, weight=...}, {to=1002, weight=...}]
```

这样设计的原因是：

1. `nodes` 用数组连续存储，遍历方便。
2. `adj` 是邻接表，适合表示稀疏路网。
3. `idToIndex` 解决“节点 ID 不连续”的问题，避免用很大的数组直接按 ID 存储。

校园路网一般是稀疏图，一个点只连接少量道路，所以邻接表比邻接矩阵更节省空间。

### 3.5 CampusGraph：校园图总管理

位置：`src/CampusGraph.h/cpp`

`CampusGraph` 把景点和路网组合起来：

```cpp
std::vector<Spot> spots;
std::unordered_map<int, int> spotIdToIndex;
std::unordered_map<int, int> spotNodeToIndex;
RoadNetwork roadNetwork;
std::string schoolName;
std::string mapImage;
```

它承担三类职责：

1. 文件加载和保存。
2. 景点增删改查。
3. 把路口、边、邻接表操作代理给 `RoadNetwork`。

`CampusGraph` 的关键点是：景点信息存在 `spots` 中，路径计算用的节点存在 `roadNetwork` 中。添加景点时，通常要同时添加一个对应的路网节点，并让 `Spot.nodeId` 指向它；删除景点时，也要删除这个 `nodeId` 对应的路网节点。

为了避免反复线性查找，`CampusGraph` 维护了两张哈希索引：

```text
spotIdToIndex[spotId]     景点 ID -> spots 数组下标
spotNodeToIndex[nodeId]   景点绑定节点 ID -> spots 数组下标
```

因此 `getSpotById()`、`getSpotByNodeId()`、`hasSpotNode()` 都可以 O(1) 查找。

景点和路网节点的同步由 `CampusGraph` 的组合接口统一处理：

```text
addSpotWithNode()
updateSpotWithNode()
removeSpotAndNode()
```

这样 `CampusBackend` 不需要重复写“改景点后再改节点”的同步逻辑。

### 3.6 MinHeap：手写最小堆

位置：`src/MinHeap.h`

路径算法没有直接使用标准库优先队列，而是实现了一个最小堆：

```cpp
struct HeapNode {
    int vertex = -1;
    int distance = 0;
};
```

`vertex` 存的是节点在 `nodes` 数组里的下标，`distance` 存当前从起点到该节点的最短候选距离。

最小堆支持：

```text
push()  插入候选节点，通过 heapifyUp 上浮
pop()   弹出距离最小节点，通过 heapifyDown 下沉
```

Dijkstra 算法依赖这个堆快速取出当前距离最小的未处理节点。

## 4. 图结构如何表示道路

`edges.txt` 中每一行只有两个 ID：

```csv
from,to
1001,1003
```

文件不保存权重。权重在 `RoadNetwork::addEdge()` 中计算：

```text
两个节点的像素距离 = sqrt((x1 - x2)^2 + (y1 - y2)^2)
真实距离 = 像素距离 * scale
weight = 四舍五入后的真实距离
```

添加边时，代码会自动添加双向边：

```text
from -> to
to   -> from
```

因此路网是无向图。保存到文件时，为避免重复保存双向边，只在 `fromId < toId` 时写出一条。

## 5. 最短路径算法

位置：`src/PathFinder.cpp`

`PathFinder::shortestPath(fromId, toId)` 使用 Dijkstra 算法。流程如下：

1. 从 `CampusGraph` 获取所有 `Node` 和邻接表。
2. 临时构建 `idToIdx`，把节点 ID 映射到数组下标。
3. 初始化三个数组：

```text
dist[i]     起点到第 i 个节点的当前最短距离
prev[i]     最短路径上第 i 个节点的前驱节点
visited[i]  第 i 个节点是否已经确定最短距离
```

4. 把起点加入 `MinHeap`。
5. 每次弹出当前距离最小的节点。
6. 遍历它的邻接边，尝试松弛距离。
7. 到达终点或堆为空时停止。
8. 通过 `prev` 从终点反向恢复路径。

恢复后的结果存入 `PathResult`：

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
| `nodeIds` | 路径经过的所有路网节点 ID，包括路口和景点 |
| `spotIds` | 路径中属于景点的节点 ID |
| `drawPoints` | 用于前端画线的坐标点 |
| `totalLength` | 路径总长度 |

`drawPoints` 来自路径节点的 `(x, y)` 坐标，前端直接按这些点绘制路径线。

## 6. 附近设施查询

位置：`PathFinder::nearestByType()`

附近搜索不是单独建索引，而是复用最短路径算法：

1. 遍历所有 `Spot`。
2. 筛选出 `spot.type == type` 的景点。
3. 从起点运行一次 Dijkstra，得到到所有节点的最短距离和前驱数组。
4. 根据 `spot.nodeId` 在距离数组中读取候选景点距离。
5. 用前驱数组恢复候选景点路径，并包装成 `NearbyResult`。
6. 用手写插入排序按距离升序排列。
7. 截取前 `limit` 个结果。

结果结构：

```cpp
struct NearbyResult {
    int spotId = -1;
    int distance = 0;
    PathResult path;
};
```

这种实现比“每个候选景点各跑一次 Dijkstra”更高效：一次 Dijkstra 就能得到起点到所有节点的最短距离，附近搜索只需要筛选和排序。

## 7. 后端如何给 QML 提供数据

位置：`src/CampusBackend.h/cpp`

`CampusBackend` 继承 `QObject`，通过 `Q_PROPERTY` 和 `Q_INVOKABLE` 暴露给 QML：

```cpp
Q_PROPERTY(QVariantList spots READ spots NOTIFY spotsChanged)
Q_PROPERTY(QVariantList nodes READ nodes NOTIFY nodesChanged)
Q_PROPERTY(QVariantList edges READ edges NOTIFY edgesChanged)
```

前端能直接调用：

```text
backend.spots()
backend.nodes()
backend.edges()
backend.findShortestPath(fromId, toId)
backend.findNearby(fromId, type, limit)
backend.addSpot(...)
backend.addNode(...)
backend.addEdge(...)
```

C++ 数据结构不能直接给 QML 用，所以后端会把结构体转换成 `QVariantMap` 或 `QVariantList`：

```text
Spot       -> QVariantMap{id, nodeId, name, type, intro, x, y}
Node       -> QVariantMap{id, x, y}
PathResult -> QVariantMap{ids, names, points, length}
```

这里 `x/y` 是为了前端显示方便临时补上的字段，真实坐标仍然来自 `Node`。前端只是数据消费者，真正的数据结构维护、路径计算和文件保存都在 C++ 后端完成。

## 8. 增删改时的数据同步

项目中有两类操作：

```text
add/update/remove...       修改内存后立即 save()
add/update/remove...Only   只修改内存，不立即保存文件
```

例如 `CampusBackend::addSpot()` 会：

1. 构造 `Spot`。
2. 构造对应的 `Node`。
3. 调用 `graph.addSpotWithNode(spot, node)`。
4. 保存文件。
5. 发出 `spotsChanged`、`nodesChanged`、`dataChanged` 信号。

删除景点时也会同步删除对应路网节点，同时删除相关边。

这部分要特别注意：景点坐标只改 `Node`，景点名称、类型、简介只改 `Spot`。这样不会再出现 `Spot.x/y` 和 `Node.x/y` 两份坐标不同步的问题。

节点坐标更新后，`RoadNetwork::updateNode()` 会刷新该节点相关边的权重，保证最短路径长度和最新地图坐标一致。

## 9. 文件格式说明

### 9.1 spots.txt

```csv
# id,nodeId,name,type,intro
1,1,北西门,校门,校园西北侧出入口
```

字段顺序：

```text
景点 ID, 绑定的路网节点 ID, 名称, 类型, 简介
```

### 9.2 nodes.txt

```csv
# id,x,y
1001,1596.81,1156.36
```

字段顺序：

```text
路口节点 ID, x 坐标, y 坐标
```

### 9.3 edges.txt

```csv
# from,to
1001,1003
```

字段顺序：

```text
起点节点 ID, 终点节点 ID
```

`edges.txt` 只保存连接关系，不保存权重。权重由坐标和比例尺计算。

### 9.4 config.txt

```ini
scale = 0.42
school = 广西大学
map_image = campus_map.jpg
```

`scale` 用于把地图像素距离换算成实际距离。

## 10. 按实践要求对应的数据结构与算法

本项目可以对应常见数据结构课程实践要求：

| 实践点 | 代码位置 | 说明 |
| --- | --- | --- |
| 顺序表 | `std::vector<Spot>`、`std::vector<Node>` | 存储景点和节点 |
| 邻接表 | `std::vector<std::vector<Edge>> adj` | 存储校园道路图 |
| 哈希映射 | `std::unordered_map<int, int> idToIndex` | 节点 ID 到数组下标的快速映射 |
| 景点索引 | `spotIdToIndex`、`spotNodeToIndex` | 景点 ID / 景点节点 ID 到景点数组下标的快速映射 |
| 最小堆 | `MinHeap` | Dijkstra 中获取当前最短候选节点 |
| 图的最短路径 | `PathFinder::shortestPath` | Dijkstra 算法 |
| 单源多目标查询 | `PathFinder::nearestByType` | 一次 Dijkstra 后筛选附近设施 |
| 排序 | `PathFinder::sortNearbyByDistance` | 插入排序按距离排序附近设施 |
| 文件存储 | `loadFromFiles()`、`saveToFiles()` | 文本文件持久化 |

如果需要向老师或同学解释项目，可以这样概括：

```text
项目把校园地图抽象成无向带权图。
景点和路口统一作为图的顶点，道路作为图的边。
路网用邻接表存储，边权由地图坐标和比例尺计算。
最短路径使用手写最小堆优化的 Dijkstra 算法。
附近设施查询通过一次 Dijkstra 得到所有节点距离，再筛选指定类型景点实现。
```

## 11. 推荐读代码顺序

第一次阅读建议按下面顺序：

1. `src/Spot.h`、`src/Node.h`、`src/Edge.h`：理解基本元素。
2. `data/spots.txt`、`data/nodes.txt`、`data/edges.txt`：理解文件数据。
3. `src/RoadNetwork.h/cpp`：理解邻接表、ID 映射、加边和删边。
4. `src/CampusGraph.h/cpp`：理解景点和路网如何合并。
5. `src/MinHeap.h`：理解 Dijkstra 使用的最小堆。
6. `src/PathFinder.cpp`：理解最短路径和附近查询。
7. `src/CampusBackend.cpp`：理解 C++ 如何把结果转换给 QML。
8. `qml/`：最后看界面如何调用后端。

这样读不会被前端界面细节打断，更容易抓住项目的数据结构主线。
