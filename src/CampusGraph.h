#pragma once

#include <string>
#include <unordered_map>
#include <vector>
#include "Spot.h"
#include "RoadNetwork.h"

class CampusGraph {
public:
    bool loadFromFiles(const std::string& spotsFile,
                       const std::string& nodesFile,
                       const std::string& edgesFile,
                       const std::string& configFile);
    bool saveToFiles(const std::string& spotsFile,
                     const std::string& nodesFile,
                     const std::string& edgesFile,
                     const std::string& configFile) const;
    
    // 景点操作
    bool addSpot(const Spot& spot);
    bool updateSpot(const Spot& spot);
    bool removeSpot(int nodeId);
    bool addSpotWithNode(const Spot& spot, const Node& node);
    bool updateSpotWithNode(const Spot& spot, const Node& node);
    bool removeSpotAndNode(int nodeId);
    const Spot* getSpotByNodeId(int nodeId) const;
    const std::vector<Spot>& getAllSpots() const { return spots; }
    
    // 路网操作（代理到 RoadNetwork）
    bool addNode(const Node& node);
    bool updateNode(const Node& node);
    bool removeNode(int id);
    bool addEdge(int from, int to);
    bool removeEdge(int from, int to);
    const std::vector<Node>& getAllNodes() const { return roadNetwork.getAllNodes(); }
    const Node* getNode(int id) const { return roadNetwork.getNode(id); }
    std::vector<int> getNeighbors(int id) const { return roadNetwork.getNeighbors(id); }
    const std::vector<std::vector<Edge>>& getAdjacency() const { return roadNetwork.getAdjacency(); }
    const std::unordered_map<int, int>& getNodeIndexMap() const { return roadNetwork.getIdToIndex(); }
    
    // 配置
    double getScale() const { return roadNetwork.getScale(); }
    void setScale(double s) { roadNetwork.setScale(s); }
    const std::string& getSchoolName() const { return schoolName; }
    const std::string& getMapImage() const { return mapImage; }
    
    // 路径查询辅助
    bool hasNode(int id) const { return roadNetwork.hasNode(id); }
    bool hasSpotNode(int nodeId) const;
    
private:
    std::vector<Spot> spots;
    std::unordered_map<int, int> spotNodeToIndex;
    RoadNetwork roadNetwork;
    std::string schoolName = "广西大学";
    std::string mapImage = "campus_map.jpg";
    
    void rebuildSpotMaps();
};
