#include "PathFinder.h"

#include <limits>

#include "MinHeap.h"

PathFinder::PathFinder(const CampusGraph *graph)
    : graph(graph)
{
}

// Dijkstra: time O((V+E)logV), space O(V). The heap is implemented in MinHeap.h.
PathResult PathFinder::shortestPath(int fromId, int toId) const
{
    PathResult result;
    if (!graph) {
        return result;
    }

    const int start = graph->indexOfSpot(fromId);
    const int target = graph->indexOfSpot(toId);
    if (start < 0 || target < 0) {
        return result;
    }

    const int n = graph->spotCount();
    const int infinity = std::numeric_limits<int>::max() / 4;
    std::vector<int> dist(n, infinity);
    std::vector<int> previous(n, -1);
    std::vector<bool> done(n, false);

    MinHeap heap;
    dist[start] = 0;
    heap.push({start, 0});

    while (!heap.isEmpty()) {
        const HeapNode node = heap.pop();
        if (done[node.vertex]) {
            continue;
        }
        done[node.vertex] = true;
        if (node.vertex == target) {
            break;
        }

        const std::vector<std::vector<Edge>> &adj = graph->adjacencyList();
        for (const Edge &edge : adj[node.vertex]) {
            if (done[edge.to]) {
                continue;
            }

            const int candidate = dist[node.vertex] + edge.weight;
            if (candidate < dist[edge.to]) {
                dist[edge.to] = candidate;
                previous[edge.to] = node.vertex;
                heap.push({edge.to, candidate});
            }
        }
    }

    if (dist[target] == infinity) {
        return result;
    }

    std::vector<int> reversed;
    for (int at = target; at != -1; at = previous[at]) {
        reversed.push_back(at);
    }

    std::vector<int> indexes;
    for (int i = static_cast<int>(reversed.size()) - 1; i >= 0; --i) {
        indexes.push_back(reversed[i]);
    }
    return buildPathFromIndexes(indexes, dist[target]);
}

std::vector<PathResult> PathFinder::allSimplePaths(int fromId, int toId, int maxCount) const
{
    std::vector<PathResult> result;
    if (!graph || maxCount <= 0) {
        return result;
    }

    const int start = graph->indexOfSpot(fromId);
    const int target = graph->indexOfSpot(toId);
    if (start < 0 || target < 0) {
        return result;
    }

    std::vector<bool> visited(graph->spotCount(), false);
    std::vector<int> path;
    dfsAllPaths(start, target, visited, path, 0, result, maxCount);
    return result;
}

std::vector<NearbyResult> PathFinder::nearestByType(int fromId, const std::string &type, int limit) const
{
    std::vector<NearbyResult> results;
    if (!graph || limit <= 0) {
        return results;
    }

    for (const Spot &spot : graph->allSpots()) {
        if (spot.id == fromId || spot.type != type) {
            continue;
        }

        PathResult path = shortestPath(fromId, spot.id);
        if (!path.spotIds.empty()) {
            NearbyResult item;
            item.spotId = spot.id;
            item.distance = path.totalLength;
            item.path = path;
            results.push_back(item);
        }
    }

    sortNearbyByDistance(results);
    if (static_cast<int>(results.size()) > limit) {
        results.resize(limit);
    }
    return results;
}

// DFS all simple paths: worst-case exponential, space O(V) for recursion and visited marks.
void PathFinder::dfsAllPaths(int currentIndex,
                             int targetIndex,
                             std::vector<bool> &visited,
                             std::vector<int> &path,
                             int length,
                             std::vector<PathResult> &result,
                             int maxCount) const
{
    if (static_cast<int>(result.size()) >= maxCount) {
        return;
    }

    visited[currentIndex] = true;
    path.push_back(currentIndex);

    if (currentIndex == targetIndex) {
        result.push_back(buildPathFromIndexes(path, length));
    } else {
        const std::vector<std::vector<Edge>> &adj = graph->adjacencyList();
        for (const Edge &edge : adj[currentIndex]) {
            if (!visited[edge.to]) {
                dfsAllPaths(edge.to, targetIndex, visited, path, length + edge.weight, result, maxCount);
            }
        }
    }

    path.pop_back();
    visited[currentIndex] = false;
}

PathResult PathFinder::buildPathFromIndexes(const std::vector<int> &indexes, int length) const
{
    PathResult path;
    path.totalLength = length;

    for (int index : indexes) {
        const Spot *spot = graph->spotAtIndex(index);
        if (spot) {
            path.spotIds.push_back(spot->id);
        }
    }

    for (int i = 1; i < static_cast<int>(path.spotIds.size()); ++i) {
        appendRoadPoints(path, path.spotIds[i - 1], path.spotIds[i]);
    }
    return path;
}

void PathFinder::appendRoadPoints(PathResult &path, int fromId, int toId) const
{
    for (const RoadWithPoints &road : graph->allRoads()) {
        const bool forward = road.from == fromId && road.to == toId;
        const bool reverse = road.from == toId && road.to == fromId;
        if (!forward && !reverse) {
            continue;
        }

        if (forward) {
            for (const Waypoint &point : road.points) {
                if (!path.drawPoints.empty() && path.drawPoints.back().x == point.x && path.drawPoints.back().y == point.y) {
                    continue;
                }
                path.drawPoints.push_back(point);
            }
        } else {
            for (int i = static_cast<int>(road.points.size()) - 1; i >= 0; --i) {
                const Waypoint &point = road.points[i];
                if (!path.drawPoints.empty() && path.drawPoints.back().x == point.x && path.drawPoints.back().y == point.y) {
                    continue;
                }
                path.drawPoints.push_back(point);
            }
        }
        return;
    }
}

// Insertion sort: time O(n^2), space O(1).
void PathFinder::sortNearbyByDistance(std::vector<NearbyResult> &items) const
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
