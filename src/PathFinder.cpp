#include "PathFinder.h"
#include "MinHeap.h"
#include <limits>
#include <algorithm>

PathFinder::PathFinder(const CampusGraph* graph) : graph(graph) {}

PathResult PathFinder::shortestPath(int fromId, int toId) const {
    PathResult result;
    if (!graph) return result;
    
    // 检查节点是否存在
    if (!graph->hasNode(fromId) || !graph->hasNode(toId)) return result;
    
    const auto& adj = graph->getAdjacency();
    const auto& nodes = graph->getAllNodes();
    int n = nodes.size();
    
    const int INF = std::numeric_limits<int>::max() / 4;
    std::vector<int> dist(n, INF);
    std::vector<int> prev(n, -1);
    std::vector<bool> visited(n, false);
    
    int startIdx = -1, targetIdx = -1;
    for (int i = 0; i < n; ++i) {
        if (nodes[i].id == fromId) startIdx = i;
        if (nodes[i].id == toId) targetIdx = i;
    }
    if (startIdx < 0 || targetIdx < 0) return result;
    
    MinHeap heap;
    dist[startIdx] = 0;
    heap.push({startIdx, 0});
    
    while (!heap.isEmpty()) {
        HeapNode node = heap.pop();
        if (visited[node.vertex]) continue;
        visited[node.vertex] = true;
        if (node.vertex == targetIdx) break;
        
        for (const Edge& edge : adj[node.vertex]) {
            if (visited[edge.to]) continue;
            int candidate = dist[node.vertex] + edge.weight;
            if (candidate < dist[edge.to]) {
                dist[edge.to] = candidate;
                prev[edge.to] = node.vertex;
                heap.push({edge.to, candidate});
            }
        }
    }
    
    if (dist[targetIdx] == INF) return result;
    
    // 重建路径
    std::vector<int> indices;
    for (int at = targetIdx; at != -1; at = prev[at]) {
        indices.push_back(at);
    }
    std::reverse(indices.begin(), indices.end());
    
    return buildPathFromNodeIndices(indices, dist[targetIdx]);
}

PathResult PathFinder::buildPathFromNodeIndices(const std::vector<int>& indices, int length) const {
    PathResult result;
    result.totalLength = length;
    
    const auto& nodes = graph->getAllNodes();
    for (int idx : indices) {
        const Node& node = nodes[idx];
        result.nodeIds.push_back(node.id);
        result.drawPoints.push_back({node.x, node.y});
        
        // 如果是景点，加入 spotIds
        if (node.id < 1000 || graph->getSpotById(node.id)) {
            result.spotIds.push_back(node.id);
        }
    }
    
    return result;
}

std::vector<NearbyResult> PathFinder::nearestByType(int fromId, const std::string& type, int limit) const {
    std::vector<NearbyResult> results;
    if (!graph || limit <= 0) return results;
    
    for (const Spot& spot : graph->getAllSpots()) {
        if (spot.id == fromId || spot.type != type) continue;
        
        PathResult path = shortestPath(fromId, spot.id);
        if (!path.nodeIds.empty()) {
            NearbyResult item;
            item.spotId = spot.id;
            item.distance = path.totalLength;
            item.path = path;
            results.push_back(item);
        }
    }
    
    sortNearbyByDistance(results);
    if ((int)results.size() > limit) results.resize(limit);
    return results;
}

void PathFinder::sortNearbyByDistance(std::vector<NearbyResult>& items) const {
    for (int i = 1; i < (int)items.size(); ++i) {
        NearbyResult key = items[i];
        int j = i - 1;
        while (j >= 0 && items[j].distance > key.distance) {
            items[j + 1] = items[j];
            --j;
        }
        items[j + 1] = key;
    }
}

std::vector<PathResult> PathFinder::allSimplePaths(int fromId, int toId, int maxCount) const {
    std::vector<PathResult> results;
    // 可选的 DFS 实现，暂略
    return results;
}