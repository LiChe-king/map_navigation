#pragma once

#include <string>
#include <vector>

#include "Edge.h"
#include "RoadWithPoints.h"
#include "Spot.h"

class CampusGraph {
public:
    bool loadFromFiles(const std::string &spotsFile,
                       const std::string &roadsFile,
                       const std::string &configFile);
    bool saveToFiles(const std::string &spotsFile,
                     const std::string &roadsFile,
                     const std::string &configFile) const;

    int spotCount() const { return static_cast<int>(spots.size()); }
    double mapScale() const { return scale; }
    const std::string &schoolName() const { return school; }
    const std::string &mapImageName() const { return mapImage; }
    const std::vector<Spot> &allSpots() const { return spots; }
    const std::vector<RoadWithPoints> &allRoads() const { return roads; }
    const std::vector<std::vector<Edge>> &adjacencyList() const { return adjacency; }

    int indexOfSpot(int id) const;
    int indexOfName(const std::string &name) const;
    const Spot *spotById(int id) const;
    const Spot *spotAtIndex(int index) const;
    const RoadWithPoints *roadByIndex(int index) const;

    bool addSpot(const Spot &spot);
    bool updateSpot(const Spot &spot);
    bool removeSpot(int id);
    bool addRoad(const RoadWithPoints &road);
    bool removeRoad(int fromId, int toId);

private:
    std::vector<Spot> spots;
    std::vector<RoadWithPoints> roads;
    std::vector<std::vector<Edge>> adjacency;
    double scale = 0.35;
    std::string school = "广西大学";
    std::string mapImage = "campus_map.jpg";

    void rebuildAdjacency();
};

