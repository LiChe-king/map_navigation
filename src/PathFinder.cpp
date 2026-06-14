#include "PathFinder.h"
#include "MinHeap.h"
#include <limits>
#include <algorithm>

PathFinder::PathFinder(const CampusGraph* graph) : graph(graph) {}

PathResult PathFinder::shortestPath(int fromId, int toId) const {
    PathResult result;
    if (!graph) return result;

    const auto& nodes = graph->getAllNodes();
    int n = static_cast<int>(nodes.size());

    // 构建 ID -> 索引 映射
    std::unordered_map<int, int> idToIdx;
    for (int i = 0; i < n; ++i) {
        idToIdx[nodes[i].id] = i;
    }

    auto itFrom = idToIdx.find(fromId);
    auto itTo = idToIdx.find(toId);
    if (itFrom == idToIdx.end() || itTo == idToIdx.end()) {
        return result;   // 起点或终点不在图中
    }

    int startIdx = itFrom->second;
    int targetIdx = itTo->second;

    const int INF = std::numeric_limits<int>::max() / 4;
    std::vector<int> dist(n, INF);
    std::vector<int> prev(n, -1);
    std::vector<bool> visited(n, false);

    MinHeap heap;
    dist[startIdx] = 0;
    heap.push({startIdx, 0});

    const auto& adj = graph->getAdjacency(); // 邻接表，Edge.to 是节点 ID

    while (!heap.isEmpty()) {
        HeapNode node = heap.pop();
        int uIdx = node.vertex;
        if (visited[uIdx]) continue;
        visited[uIdx] = true;
        if (uIdx == targetIdx) break;

        for (const Edge& edge : adj[uIdx]) {
            int vId = edge.to;
            auto itV = idToIdx.find(vId);
            if (itV == idToIdx.end()) continue; // 安全起见
            int vIdx = itV->second;
            if (visited[vIdx]) continue;

            int candidate = dist[uIdx] + edge.weight;
            if (candidate < dist[vIdx]) {
                dist[vIdx] = candidate;
                prev[vIdx] = uIdx;
                heap.push({vIdx, candidate});
            }
        }
    }

    if (dist[targetIdx] == INF) return result; // 不可达

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