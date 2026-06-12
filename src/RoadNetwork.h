#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <set>
#include "Edge.h"
#include "Node.h"

class RoadNetwork {
public:
    // 文件操作
    bool loadNodes(const std::string& filename);
    bool loadEdges(const std::string& filename);
    bool saveNodes(const std::string& filename) const;
    bool saveEdges(const std::string& filename) const;

    // 节点操作
    bool addNode(const Node& node);
    bool removeNode(int id);
    bool updateNode(const Node& node);
    const Node* getNode(int id) const;
    const std::vector<Node>& getAllNodes() const { return nodes; }
    bool hasNode(int id) const;

    // 边操作（双向自动添加）
    bool addEdge(int from, int to);
    bool removeEdge(int from, int to);
    bool hasEdge(int from, int to) const;
    int getEdgeWeight(int from, int to) const;
    std::vector<int> getNeighbors(int id) const;

    // 图结构（邻接表）
    const std::vector<std::vector<Edge>>& getAdjacency() const { return adj; }

    // 辅助
    int findIndex(int id) const;
    void setScale(double s) { scale = s; }
    double getScale() const { return scale; }

private:
    std::vector<Node> nodes;
    std::vector<std::vector<Edge>> adj;
    std::unordered_map<int, int> idToIndex;  // 节点ID → 数组索引
    double scale = 0.35;

    double calcDistance(const Node& a, const Node& b) const;
    void removeEdgesOfNode(int idx);          // 删除与索引 idx 节点相连的所有边
    void rebuildIndexMap();                   // 重建 idToIndex 映射
    void resizeAdjacency();                   // 使 adj 大小与 nodes 一致
};