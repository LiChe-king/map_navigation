#include "PathFinder.h"
#include "MinHeap.h"

#include <algorithm>
#include <limits>

namespace {
constexpr int INF_DISTANCE = std::numeric_limits<int>::max() / 4;
}

PathFinder::PathFinder(const CampusGraph* graph) : graph(graph) {}

PathResult PathFinder::shortestPath(int fromId, int toId) const
{
    PathResult result;
    if (!graph) return result;

    const auto& idToIdx = graph->getNodeIndexMap();
    auto itTo = idToIdx.find(toId);
    if (idToIdx.find(fromId) == idToIdx.end() || itTo == idToIdx.end()) {
        return result;
    }

    std::vector<int> dist;
    std::vector<int> prev;
    runDijkstra(fromId, dist, prev, itTo->second);

    if (itTo->second >= static_cast<int>(dist.size()) || dist[itTo->second] == INF_DISTANCE) {
        return result;
    }
    return buildPathToIndex(prev, itTo->second, dist[itTo->second]);
}

void PathFinder::runDijkstra(int fromId, std::vector<int>& dist, std::vector<int>& prev, int stopIdx) const
{
    const auto& nodes = graph->getAllNodes();
    const auto& idToIdx = graph->getNodeIndexMap();
    const auto& adj = graph->getAdjacency();
    int n = static_cast<int>(nodes.size());

    dist.assign(n, INF_DISTANCE);
    prev.assign(n, -1);
    std::vector<bool> visited(n, false);

    auto itFrom = idToIdx.find(fromId);
    if (itFrom == idToIdx.end()) return;

    int startIdx = itFrom->second;
    MinHeap heap;
    dist[startIdx] = 0;
    heap.push({startIdx, 0});

    while (!heap.isEmpty()) {
        HeapNode node = heap.pop();
        int uIdx = node.vertex;
        if (uIdx < 0 || uIdx >= n || visited[uIdx]) continue;
        visited[uIdx] = true;
        if (uIdx == stopIdx) break;

        for (const Edge& edge : adj[uIdx]) {
            auto itV = idToIdx.find(edge.to);
            if (itV == idToIdx.end()) continue;

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
}

PathResult PathFinder::buildPathToIndex(const std::vector<int>& prev, int targetIdx, int length) const
{
    std::vector<int> indices;
    for (int at = targetIdx; at != -1; at = prev[at]) {
        indices.push_back(at);
    }
    std::reverse(indices.begin(), indices.end());
    return buildPathFromNodeIndices(indices, length);
}

PathResult PathFinder::buildPathFromNodeIndices(const std::vector<int>& indices, int length) const
{
    PathResult result;
    result.totalLength = length;

    const auto& nodes = graph->getAllNodes();
    for (int idx : indices) {
        const Node& node = nodes[idx];
        result.nodeIds.push_back(node.id);
        result.drawPoints.push_back({node.x, node.y});

        const Spot* spot = graph->getSpotByNodeId(node.id);
        if (spot) {
            result.spotIds.push_back(spot->id);
        }
    }

    return result;
}

std::vector<NearbyResult> PathFinder::nearestByType(int fromId, const std::string& type, int limit) const
{
    std::vector<NearbyResult> results;
    if (!graph || limit <= 0) return results;

    const auto& idToIdx = graph->getNodeIndexMap();
    if (idToIdx.find(fromId) == idToIdx.end()) return results;

    std::vector<int> dist;
    std::vector<int> prev;
    runDijkstra(fromId, dist, prev);

    for (const Spot& spot : graph->getAllSpots()) {
        if (spot.nodeId == fromId || spot.type != type) continue;

        auto itTarget = idToIdx.find(spot.nodeId);
        if (itTarget == idToIdx.end()) continue;

        int targetIdx = itTarget->second;
        if (targetIdx < 0 || targetIdx >= static_cast<int>(dist.size()) || dist[targetIdx] == INF_DISTANCE) {
            continue;
        }

        NearbyResult item;
        item.spotId = spot.id;
        item.distance = dist[targetIdx];
        item.path = buildPathToIndex(prev, targetIdx, dist[targetIdx]);
        results.push_back(item);
    }

    sortNearbyByDistance(results);
    if (static_cast<int>(results.size()) > limit) results.resize(limit);
    return results;
}

void PathFinder::sortNearbyByDistance(std::vector<NearbyResult>& items) const
{
    for (int i = 1; i < static_cast<int>(items.size()); ++i) {
        NearbyResult key = items[i];
        int j = i - 1;
        while (j >= 0 && items[j].distance > key.distance) {
            items[j + 1] = items[j];
            --j;
        }
        items[j + 1] = key;
    }
}

std::vector<PathResult> PathFinder::allSimplePaths(int fromId, int toId, int maxCount) const
{
    std::vector<PathResult> results;
    return results;
}
