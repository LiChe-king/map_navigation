#pragma once

#include <string>
#include <vector>
#include "CampusGraph.h"

struct PathResult {
    std::vector<int> nodeIds;
    std::vector<int> spotNodeIds;
    std::vector<std::pair<double, double>> drawPoints;
    int totalLength = 0;
};

struct NearbyResult {
    int spotNodeId = -1;
    int distance = 0;
    PathResult path;
};

class PathFinder {
public:
    explicit PathFinder(const CampusGraph* graph);
    
    PathResult shortestPath(int fromId, int toId) const;
    std::vector<PathResult> allSimplePaths(int fromId, int toId, int maxCount = 3) const;
    std::vector<NearbyResult> nearestByType(int fromId, const std::string& type, int limit) const;

private:
    const CampusGraph* graph = nullptr;
    
    void runDijkstra(int fromId, std::vector<int>& dist, std::vector<int>& prev,
                     int stopIdx = -1) const;
    PathResult buildPathToIndex(const std::vector<int>& prev, int targetIdx, int length) const;
    PathResult buildPathFromNodeIndices(const std::vector<int>& indices, int length) const;
    void sortNearbyByDistance(std::vector<NearbyResult>& items) const;
};
