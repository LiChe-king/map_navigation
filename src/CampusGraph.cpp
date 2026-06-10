#include "CampusGraph.h"

#include <fstream>
#include <sstream>

#include "ParserUtils.h"

bool CampusGraph::loadFromFiles(const std::string &spotsFile,
                                const std::string &roadsFile,
                                const std::string &configFile)
{
    spots.clear();
    roads.clear();

    std::ifstream configInput(configFile);
    if (configInput) {
        std::string line;
        while (std::getline(configInput, line)) {
            if (startsWithCommentOrEmpty(line)) {
                continue;
            }

            const std::vector<std::string> parts = splitText(line, '=');
            if (parts.size() < 2) {
                continue;
            }
            if (parts[0] == "scale") {
                scale = std::stod(parts[1]);
            } else if (parts[0] == "school") {
                school = parts[1];
            } else if (parts[0] == "map_image") {
                mapImage = parts[1];
            }
        }
    }

    std::ifstream spotInput(spotsFile);
    if (!spotInput) {
        return false;
    }

    std::string line;
    while (std::getline(spotInput, line)) {
        if (startsWithCommentOrEmpty(line)) {
            continue;
        }

        const std::vector<std::string> parts = splitText(line, ',');
        if (parts.size() < 6) {
            continue;
        }

        Spot spot;
        spot.id = std::stoi(parts[0]);
        spot.name = parts[1];
        spot.type = parts[2];
        spot.intro = parts[3];
        spot.x = std::stod(parts[4]);
        spot.y = std::stod(parts[5]);
        spots.push_back(spot);
    }

    std::ifstream roadInput(roadsFile);
    if (!roadInput) {
        return false;
    }

    while (std::getline(roadInput, line)) {
        if (startsWithCommentOrEmpty(line)) {
            continue;
        }

        std::istringstream stream(line);
        RoadWithPoints road;
        int pointCount = 0;
        stream >> road.from >> road.to >> pointCount;

        for (int i = 0; i < pointCount; ++i) {
            Waypoint point;
            stream >> point.x >> point.y;
            road.points.push_back(point);
        }

        road.weight = static_cast<int>(road.calcDistance(scale) + 0.5);
        if (road.from >= 0 && road.to >= 0 && pointCount >= 2) {
            roads.push_back(road);
        }
    }

    rebuildAdjacency();
    return true;
}

bool CampusGraph::saveToFiles(const std::string &spotsFile,
                              const std::string &roadsFile,
                              const std::string &configFile) const
{
    std::ofstream configOutput(configFile);
    if (!configOutput) {
        return false;
    }
    configOutput << "scale = " << scale << "\n";
    configOutput << "school = " << school << "\n";
    configOutput << "map_image = " << mapImage << "\n";

    std::ofstream spotOutput(spotsFile);
    if (!spotOutput) {
        return false;
    }
    spotOutput << "# id,name,type,intro,x,y\n";
    for (const Spot &spot : spots) {
        spotOutput << spot.id << "," << spot.name << "," << spot.type << ","
                   << spot.intro << "," << spot.x << "," << spot.y << "\n";
    }

    std::ofstream roadOutput(roadsFile);
    if (!roadOutput) {
        return false;
    }
    roadOutput << "# from to pointCount x1 y1 x2 y2 ...\n";
    for (const RoadWithPoints &road : roads) {
        roadOutput << road.from << " " << road.to << " " << road.points.size();
        for (const Waypoint &point : road.points) {
            roadOutput << " " << point.x << " " << point.y;
        }
        roadOutput << "\n";
    }
    return true;
}

int CampusGraph::indexOfSpot(int id) const
{
    for (int i = 0; i < static_cast<int>(spots.size()); ++i) {
        if (spots[i].id == id) {
            return i;
        }
    }
    return -1;
}

int CampusGraph::indexOfName(const std::string &name) const
{
    for (int i = 0; i < static_cast<int>(spots.size()); ++i) {
        if (spots[i].name == name) {
            return i;
        }
    }
    return -1;
}

const Spot *CampusGraph::spotById(int id) const
{
    const int index = indexOfSpot(id);
    return index < 0 ? nullptr : &spots[index];
}

const Spot *CampusGraph::spotAtIndex(int index) const
{
    if (index < 0 || index >= static_cast<int>(spots.size())) {
        return nullptr;
    }
    return &spots[index];
}

const RoadWithPoints *CampusGraph::roadByIndex(int index) const
{
    if (index < 0 || index >= static_cast<int>(roads.size())) {
        return nullptr;
    }
    return &roads[index];
}

bool CampusGraph::addSpot(const Spot &spot)
{
    if (indexOfSpot(spot.id) >= 0 || indexOfName(spot.name) >= 0) {
        return false;
    }
    spots.push_back(spot);
    rebuildAdjacency();
    return true;
}

bool CampusGraph::updateSpot(const Spot &spot)
{
    const int index = indexOfSpot(spot.id);
    if (index < 0) {
        return false;
    }
    spots[index] = spot;
    rebuildAdjacency();
    return true;
}

bool CampusGraph::removeSpot(int id)
{
    const int index = indexOfSpot(id);
    if (index < 0) {
        return false;
    }

    spots.erase(spots.begin() + index);
    for (int i = static_cast<int>(roads.size()) - 1; i >= 0; --i) {
        if (roads[i].from == id || roads[i].to == id) {
            roads.erase(roads.begin() + i);
        }
    }
    rebuildAdjacency();
    return true;
}

bool CampusGraph::addRoad(const RoadWithPoints &road)
{
    if (road.from == road.to || !spotById(road.from) || !spotById(road.to) || road.points.size() < 2) {
        return false;
    }

    for (const RoadWithPoints &existing : roads) {
        const bool same = existing.from == road.from && existing.to == road.to;
        const bool reverse = existing.from == road.to && existing.to == road.from;
        if (same || reverse) {
            return false;
        }
    }

    RoadWithPoints stored = road;
    stored.weight = static_cast<int>(stored.calcDistance(scale) + 0.5);
    roads.push_back(stored);
    rebuildAdjacency();
    return true;
}

bool CampusGraph::removeRoad(int fromId, int toId)
{
    for (int i = 0; i < static_cast<int>(roads.size()); ++i) {
        const bool same = roads[i].from == fromId && roads[i].to == toId;
        const bool reverse = roads[i].from == toId && roads[i].to == fromId;
        if (same || reverse) {
            roads.erase(roads.begin() + i);
            rebuildAdjacency();
            return true;
        }
    }
    return false;
}

void CampusGraph::rebuildAdjacency()
{
    adjacency.clear();
    adjacency.resize(spots.size());

    for (int roadIndex = 0; roadIndex < static_cast<int>(roads.size()); ++roadIndex) {
        const RoadWithPoints &road = roads[roadIndex];
        const int fromIndex = indexOfSpot(road.from);
        const int toIndex = indexOfSpot(road.to);
        if (fromIndex < 0 || toIndex < 0) {
            continue;
        }

        adjacency[fromIndex].push_back({toIndex, road.weight, roadIndex});
        adjacency[toIndex].push_back({fromIndex, road.weight, roadIndex});
    }
}

