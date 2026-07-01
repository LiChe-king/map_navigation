#include "PathFinder.h"
#include "MinHeap.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <queue>
#include <string>

namespace {
constexpr int INF_DISTANCE = std::numeric_limits<int>::max() / 4;

struct QueueState {
    int idx = -1;
    int distance = 0;
};

struct LongerDistanceFirst {
    bool operator()(const QueueState& a, const QueueState& b) const
    {
        return a.distance > b.distance;
    }
};

bool samePrefix(const std::vector<int>& path, const std::vector<int>& prefix)
{
    return path.size() >= prefix.size()
        && std::equal(prefix.begin(), prefix.end(), path.begin());
}

bool samePath(const PathResult& path, const std::vector<int>& ids)
{
    return path.nodeIds == ids;
}

bool hasPath(const std::vector<PathResult>& paths, const std::vector<int>& ids)
{
    return std::any_of(paths.begin(), paths.end(), [&ids](const PathResult& path) {
        return samePath(path, ids);
    });
}

std::vector<std::pair<int, int>> pathEdges(const PathResult& path)
{
    std::vector<std::pair<int, int>> edges;
    if (path.nodeIds.size() < 2) return edges;

    edges.reserve(path.nodeIds.size() - 1);
    for (int i = 1; i < static_cast<int>(path.nodeIds.size()); ++i) {
        int a = path.nodeIds[i - 1];
        int b = path.nodeIds[i];
        if (a > b) std::swap(a, b);
        edges.push_back({a, b});
    }
    return edges;
}

double overlapRatio(const PathResult& a, const PathResult& b)
{
    const std::vector<std::pair<int, int>> edgesA = pathEdges(a);
    const std::vector<std::pair<int, int>> edgesB = pathEdges(b);
    if (edgesA.empty() || edgesB.empty()) return 0.0;

    int shared = 0;
    for (const auto& edge : edgesA) {
        if (std::find(edgesB.begin(), edgesB.end(), edge) != edgesB.end()) {
            ++shared;
        }
    }

    const int base = std::max(edgesA.size(), edgesB.size());
    return base > 0 ? static_cast<double>(shared) / static_cast<double>(base) : 0.0;
}

double maxOverlapWithPaths(const std::vector<PathResult>& paths, const PathResult& candidate)
{
    double best = 0.0;
    for (const PathResult& path : paths) {
        best = std::max(best, overlapRatio(path, candidate));
    }
    return best;
}

bool hasEdgeBan(const std::vector<std::pair<int, int>>& bannedEdges, int fromId, int toId)
{
    return std::any_of(bannedEdges.begin(), bannedEdges.end(),
                       [fromId, toId](const std::pair<int, int>& edge) {
                           return edge.first == fromId && edge.second == toId;
                       });
}
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
            result.spotNodeIds.push_back(spot->nodeId);
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
        item.spotNodeId = spot.nodeId;
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
    if (!graph || maxCount <= 0) return results;

    PathResult shortest = shortestPath(fromId, toId);
    if (shortest.nodeIds.empty()) return results;
    results.push_back(shortest);
    if (maxCount == 1) return results;

    const auto& nodes = graph->getAllNodes();
    const auto& adj = graph->getAdjacency();
    const auto& idToIdx = graph->getNodeIndexMap();
    auto itTo = idToIdx.find(toId);
    const int targetIdx = itTo->second;

    auto edgeWeight = [&idToIdx, &adj](int fromNodeId, int toNodeId) {
        auto itFromIdx = idToIdx.find(fromNodeId);
        if (itFromIdx == idToIdx.end()) return INF_DISTANCE;
        for (const Edge& edge : adj[itFromIdx->second]) {
            if (edge.to == toNodeId) return edge.weight;
        }
        return INF_DISTANCE;
    };

    auto pathLength = [&edgeWeight](const std::vector<int>& nodeIds) {
        int length = 0;
        for (int i = 1; i < static_cast<int>(nodeIds.size()); ++i) {
            int weight = edgeWeight(nodeIds[i - 1], nodeIds[i]);
            if (weight == INF_DISTANCE) return INF_DISTANCE;
            length += weight;
        }
        return length;
    };

    auto dijkstraWithBans = [&](int spurNodeId,
                                const std::vector<bool>& bannedNodes,
                                const std::vector<std::pair<int, int>>& bannedEdges) {
        std::vector<int> empty;
        auto itSpur = idToIdx.find(spurNodeId);
        if (itSpur == idToIdx.end()) return std::pair<std::vector<int>, int>(empty, INF_DISTANCE);

        const int n = static_cast<int>(nodes.size());
        std::vector<int> dist(n, INF_DISTANCE);
        std::vector<int> prev(n, -1);
        std::vector<bool> visited(n, false);
        std::priority_queue<QueueState, std::vector<QueueState>, LongerDistanceFirst> queue;

        int spurIdx = itSpur->second;
        dist[spurIdx] = 0;
        queue.push({spurIdx, 0});

        while (!queue.empty()) {
            QueueState current = queue.top();
            queue.pop();

            int currentIdx = current.idx;
            if (currentIdx < 0 || currentIdx >= n || visited[currentIdx]) continue;
            visited[currentIdx] = true;
            if (currentIdx == targetIdx) break;

            int currentNodeId = nodes[currentIdx].id;
            for (const Edge& edge : adj[currentIdx]) {
                auto itNext = idToIdx.find(edge.to);
                if (itNext == idToIdx.end()) continue;

                int nextIdx = itNext->second;
                if (visited[nextIdx] || bannedNodes[nextIdx]) continue;
                if (hasEdgeBan(bannedEdges, currentNodeId, edge.to)) continue;

                int candidate = dist[currentIdx] + edge.weight;
                if (candidate < dist[nextIdx]) {
                    dist[nextIdx] = candidate;
                    prev[nextIdx] = currentIdx;
                    queue.push({nextIdx, candidate});
                }
            }
        }

        if (dist[targetIdx] == INF_DISTANCE) {
            return std::pair<std::vector<int>, int>(empty, INF_DISTANCE);
        }

        std::vector<int> path;
        for (int at = targetIdx; at != -1; at = prev[at]) {
            path.push_back(at);
        }
        std::reverse(path.begin(), path.end());
        return std::pair<std::vector<int>, int>(path, dist[targetIdx]);
    };

    std::vector<PathResult> candidates;
    for (int k = 1; k < maxCount; ++k) {
        const PathResult& basePath = results[k - 1];

        for (int spurPos = 0; spurPos < static_cast<int>(basePath.nodeIds.size()) - 1; ++spurPos) {
            std::vector<int> rootIds(basePath.nodeIds.begin(), basePath.nodeIds.begin() + spurPos + 1);
            int rootLength = pathLength(rootIds);
            if (rootLength == INF_DISTANCE) continue;

            std::vector<bool> bannedNodes(nodes.size(), false);
            for (int i = 0; i < spurPos; ++i) {
                auto itRoot = idToIdx.find(rootIds[i]);
                if (itRoot != idToIdx.end()) bannedNodes[itRoot->second] = true;
            }

            std::vector<std::pair<int, int>> bannedEdges;
            for (const PathResult& path : results) {
                if (samePrefix(path.nodeIds, rootIds)
                    && static_cast<int>(path.nodeIds.size()) > spurPos + 1) {
                    bannedEdges.push_back({path.nodeIds[spurPos], path.nodeIds[spurPos + 1]});
                }
            }

            auto spurResult = dijkstraWithBans(rootIds.back(), bannedNodes, bannedEdges);
            if (spurResult.first.empty()) continue;

            std::vector<int> totalIds = rootIds;
            for (int i = 1; i < static_cast<int>(spurResult.first.size()); ++i) {
                totalIds.push_back(nodes[spurResult.first[i]].id);
            }

            if (hasPath(results, totalIds) || hasPath(candidates, totalIds)) continue;

            std::vector<int> totalIndices;
            for (int nodeId : totalIds) {
                auto itIdx = idToIdx.find(nodeId);
                if (itIdx != idToIdx.end()) totalIndices.push_back(itIdx->second);
            }

            PathResult candidate = buildPathFromNodeIndices(totalIndices, rootLength + spurResult.second);
            if (hasPath(results, candidate.nodeIds)
                || hasPath(candidates, candidate.nodeIds)
                || maxOverlapWithPaths(results, candidate) >= 0.95
                || maxOverlapWithPaths(candidates, candidate) >= 0.95) {
                continue;
            }

            candidates.push_back(candidate);
        }

        if (candidates.empty()) break;
        std::sort(candidates.begin(), candidates.end(), [&results](const PathResult& a, const PathResult& b) {
            if (a.totalLength != b.totalLength) return a.totalLength < b.totalLength;
            double aOverlap = maxOverlapWithPaths(results, a);
            double bOverlap = maxOverlapWithPaths(results, b);
            if (aOverlap != bOverlap) return aOverlap < bOverlap;
            return a.nodeIds.size() < b.nodeIds.size();
        });
        results.push_back(candidates.front());
        candidates.erase(candidates.begin());
    }

    if (results.size() > 1) {
        std::stable_sort(results.begin() + 1, results.end(), [](const PathResult& a, const PathResult& b) {
            if (a.totalLength != b.totalLength) return a.totalLength < b.totalLength;
            return a.nodeIds.size() < b.nodeIds.size();
        });
    }

    return results;
}
