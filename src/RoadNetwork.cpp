#include "RoadNetwork.h"
#include "ParserUtils.h"
#include <fstream>
#include <cmath>
#include <algorithm>
#include <set>
#include <iostream>

bool RoadNetwork::loadNodes(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) return false;

    nodes.clear();
    idToIndex.clear();

    std::string line;
    while (std::getline(file, line)) {
        if (startsWithCommentOrEmpty(line)) continue;

        std::vector<std::string> parts = splitText(line, ',');
        if (parts.size() < 3) continue;

        Node node;
        node.id = std::stoi(parts[0]);
        node.x = std::stod(parts[1]);
        node.y = std::stod(parts[2]);

        int idx = nodes.size();
        nodes.push_back(node);
        idToIndex[node.id] = idx;
    }

    // 重建邻接表（大小正确，但边需要重新从文件加载，这里留空）
    adj.clear();
    adj.resize(nodes.size());
    return true;
}

bool RoadNetwork::loadEdges(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) return false;

    // 先清空所有边
    for (auto& edgeList : adj) {
        edgeList.clear();
    }

    std::string line;
    while (std::getline(file, line)) {
        if (startsWithCommentOrEmpty(line)) continue;

        std::vector<std::string> parts = splitText(line, ',');
        if (parts.size() < 2) continue;

        int from = std::stoi(parts[0]);
        int to = std::stoi(parts[1]);

        addEdge(from, to);   // 内部会双向添加并计算权重
    }
    return true;
}

bool RoadNetwork::saveNodes(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) return false;

    file << "# id,x,y\n";
    for (const Node& node : nodes) {
        file << node.id << "," << node.x << "," << node.y << "\n";
    }
    return true;
}

bool RoadNetwork::saveEdges(const std::string& filename) const {
    std::ofstream file(filename);
    if (!file.is_open()) return false;

    file << "# from,to\n";
    std::set<std::pair<int, int>> saved;
    for (int i = 0; i < (int)adj.size(); ++i) {
        int fromId = nodes[i].id;
        for (const Edge& e : adj[i]) {
            int toId = e.to;
            if (fromId < toId && saved.find({fromId, toId}) == saved.end()) {
                saved.insert({fromId, toId});
                file << fromId << "," << toId << "\n";
            }
        }
    }
    return true;
}

bool RoadNetwork::addNode(const Node& node) {
    if (hasNode(node.id)) return false;

    int idx = nodes.size();
    nodes.push_back(node);
    idToIndex[node.id] = idx;
    // 邻接表增加一个空列表
    adj.emplace_back();
    return true;
}

bool RoadNetwork::removeNode(int id) {
    int idx = findIndex(id);
    if (idx < 0) return false;

    // 删除与该节点相连的所有边
    removeEdgesOfNode(idx);

    // 删除节点
    nodes.erase(nodes.begin() + idx);
    adj.erase(adj.begin() + idx);

    // 重建索引映射
    rebuildIndexMap();

    // 删除后需要修正邻接表中指向被删除节点之后节点的索引（因为节点移动了）
    // 实际上邻接表中存储的是目标节点的ID，不是索引，所以不需要修改索引值，只需保证后续查找正确。
    // 但是要注意：删除节点后，某些边可能指向了已经被删除的节点，这些边已经在 removeEdgesOfNode 中删除了，
    // 剩下的边中如果有指向 ID 不存在的节点，会在后续操作中被忽略，这里不再额外处理。
    return true;
}

bool RoadNetwork::updateNode(const Node& node) {
    int idx = findIndex(node.id);
    if (idx < 0) return false;
    nodes[idx] = node;
    // 坐标改变不会影响边的连接性，所以邻接表不变
    return true;
}

const Node* RoadNetwork::getNode(int id) const {
    int idx = findIndex(id);
    return idx < 0 ? nullptr : &nodes[idx];
}

bool RoadNetwork::hasNode(int id) const {
    return findIndex(id) >= 0;
}

bool RoadNetwork::addEdge(int from, int to) {
    if (from == to) return false;

    int fromIdx = findIndex(from);
    int toIdx = findIndex(to);
    if (fromIdx < 0 || toIdx < 0) return false;

    // 检查是否已存在
    for (const Edge& e : adj[fromIdx]) {
        if (e.to == to) return false;
    }

    int weight = (int)(calcDistance(nodes[fromIdx], nodes[toIdx]) + 0.5);
    adj[fromIdx].push_back(Edge(to, weight));
    adj[toIdx].push_back(Edge(from, weight));
    return true;
}

bool RoadNetwork::removeEdge(int from, int to) {
    int fromIdx = findIndex(from);
    int toIdx = findIndex(to);
    if (fromIdx < 0 || toIdx < 0) return false;

    auto& fromEdges = adj[fromIdx];
    auto& toEdges = adj[toIdx];

    fromEdges.erase(std::remove_if(fromEdges.begin(), fromEdges.end(),
        [to](const Edge& e) { return e.to == to; }), fromEdges.end());
    toEdges.erase(std::remove_if(toEdges.begin(), toEdges.end(),
        [from](const Edge& e) { return e.to == from; }), toEdges.end());

    return true;
}

bool RoadNetwork::hasEdge(int from, int to) const {
    int fromIdx = findIndex(from);
    if (fromIdx < 0) return false;
    for (const Edge& e : adj[fromIdx]) {
        if (e.to == to) return true;
    }
    return false;
}

int RoadNetwork::getEdgeWeight(int from, int to) const {
    int fromIdx = findIndex(from);
    if (fromIdx < 0) return -1;
    for (const Edge& e : adj[fromIdx]) {
        if (e.to == to) return e.weight;
    }
    return -1;
}

std::vector<int> RoadNetwork::getNeighbors(int id) const {
    std::vector<int> result;
    int idx = findIndex(id);
    if (idx < 0) return result;
    for (const Edge& e : adj[idx]) {
        result.push_back(e.to);
    }
    return result;
}

int RoadNetwork::findIndex(int id) const {
    auto it = idToIndex.find(id);
    return it == idToIndex.end() ? -1 : it->second;
}

double RoadNetwork::calcDistance(const Node& a, const Node& b) const {
    double dx = a.x - b.x;
    double dy = a.y - b.y;
    double pixelDist = std::sqrt(dx * dx + dy * dy);
    return pixelDist * scale;
}

void RoadNetwork::removeEdgesOfNode(int idx) {
    if (idx < 0 || idx >= (int)adj.size()) return;

    int nodeId = nodes[idx].id;
    // 删除所有指向该节点的边
    for (int i = 0; i < (int)adj.size(); ++i) {
        if (i == idx) continue;
        auto& edgeList = adj[i];
        edgeList.erase(std::remove_if(edgeList.begin(), edgeList.end(),
            [nodeId](const Edge& e) { return e.to == nodeId; }), edgeList.end());
    }
    // 清空该节点自己的邻接表
    adj[idx].clear();
}

void RoadNetwork::rebuildIndexMap() {
    idToIndex.clear();
    for (int i = 0; i < (int)nodes.size(); ++i) {
        idToIndex[nodes[i].id] = i;
    }
}

void RoadNetwork::resizeAdjacency() {
    adj.resize(nodes.size());
}