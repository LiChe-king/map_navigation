# 广西大学校园导游系统

基于 C++17、Qt 6 Quick/QML 和 CMake 的校园导游咨询系统。核心数据结构和算法位于 `src/`，界面位于 `qml/`，数据文件位于 `data/`。

## 功能

- 从 `spots.txt`、`roads.txt`、`config.txt` 加载校园图数据。
- 在地图上显示景点图标，点击后显示景点详情。
- 使用手写最小堆的 Dijkstra 算法查询最短路径。
- 根据道路路点绘制贴合道路弯曲的路径折线。
- 使用 DFS 查询两点之间所有简单路径。
- 按设施类型查询附近设施，并用手写插入排序按距离排序。
- 支持景点和道路的增删改，保存回纯文本文件。

## 文件格式

`spots.txt`

```text
# id,name,type,intro,x,y
1,图书馆,景点,学校主要文献资源与自习场所,930,1145
```

`roads.txt`

```text
# from to pointCount x1 y1 x2 y2 ...
1 2 4 930 1145 860 1130 780 1100 705 1080
```

`config.txt`

```text
scale = 0.35
school = 广西大学
map_image = campus_map.jpg
```

## 编译运行

需要 Qt 6.x 和 CMake。

```bash
cmake -S . -B build
cmake --build build
./build/CampusGuide
```

Windows 下可在 Qt Creator 中打开 `CMakeLists.txt`，选择 Qt 6 套件后构建运行。

## 算法说明

- 图存储：`std::vector<std::vector<Edge>>` 邻接表。
- 最小堆：`MinHeap` 手写 `heapifyUp` 和 `heapifyDown`。
- 最短路径：`PathFinder::shortestPath` 使用 Dijkstra，时间复杂度 `O((V+E)logV)`，空间复杂度 `O(V)`。
- 所有路径：`PathFinder::allSimplePaths` 使用 DFS，最坏时间复杂度为指数级，空间复杂度 `O(V)`。
- 附近搜索排序：`PathFinder::sortNearbyByDistance` 使用手写插入排序，时间复杂度 `O(n^2)`，空间复杂度 `O(1)`。
- 文件解析：`ParserUtils::splitText` 手写分隔解析，不使用 JSON/YAML 等库。

