#include "CampusGraph.h"
#include "ParserUtils.h"

#include <algorithm>
#include <cctype>
#include <fstream>

namespace {
bool isIntegerText(const std::string& value)
{
    if (value.empty()) return false;
    int start = value[0] == '-' ? 1 : 0;
    if (start >= static_cast<int>(value.size())) return false;
    for (int i = start; i < static_cast<int>(value.size()); ++i) {
        if (!std::isdigit(static_cast<unsigned char>(value[i]))) return false;
    }
    return true;
}
}

bool CampusGraph::loadFromFiles(const std::string& spotsFile,
                                const std::string& nodesFile,
                                const std::string& edgesFile,
                                const std::string& configFile)
{
    std::ifstream configInput(configFile);
    if (configInput) {
        std::string line;
        while (std::getline(configInput, line)) {
            if (startsWithCommentOrEmpty(line)) continue;
            std::vector<std::string> parts = splitText(line, '=');
            if (parts.size() < 2) continue;
            if (parts[0] == "scale") {
                roadNetwork.setScale(std::stod(parts[1]));
            } else if (parts[0] == "school") {
                schoolName = parts[1];
            } else if (parts[0] == "map_image") {
                mapImage = parts[1];
            }
        }
    }

    if (!roadNetwork.loadNodes(nodesFile)) return false;

    std::ifstream spotInput(spotsFile);
    if (!spotInput) return false;

    spots.clear();
    std::string line;
    while (std::getline(spotInput, line)) {
        if (startsWithCommentOrEmpty(line)) continue;
        std::vector<std::string> parts = splitText(line, ',');
        if (parts.size() < 4) continue;

        Spot spot;
        spot.id = std::stoi(parts[0]);
        if (parts.size() >= 6 && !isIntegerText(parts[1])) {
            // Legacy format: id,name,type,intro,x,y. The spot id is also its node id.
            spot.nodeId = spot.id;
            spot.name = parts[1];
            spot.type = parts[2];
            spot.intro = parts[3];

            if (!roadNetwork.hasNode(spot.nodeId)) {
                Node spotNode;
                spotNode.id = spot.nodeId;
                spotNode.x = std::stod(parts[4]);
                spotNode.y = std::stod(parts[5]);
                roadNetwork.addNode(spotNode);
            }
        } else if (parts.size() >= 5 && isIntegerText(parts[1])) {
            // Backward-compatible format: id,nodeId,name,type,intro
            spot.nodeId = std::stoi(parts[1]);
            spot.name = parts[2];
            spot.type = parts[3];
            spot.intro = parts[4];
        } else {
            // Current format: id,name,type,intro. Coordinates live in nodes.txt.
            spot.nodeId = spot.id;
            spot.name = parts[1];
            spot.type = parts[2];
            spot.intro = parts[3];
        }
        spots.push_back(spot);
    }
    rebuildSpotMaps();

    if (!roadNetwork.loadEdges(edgesFile)) return false;

    return true;
}

bool CampusGraph::saveToFiles(const std::string& spotsFile,
                              const std::string& nodesFile,
                              const std::string& edgesFile,
                              const std::string& configFile) const
{
    std::ofstream configOutput(configFile);
    if (!configOutput) return false;
    configOutput << "scale = " << roadNetwork.getScale() << "\n";
    configOutput << "school = " << schoolName << "\n";
    configOutput << "map_image = " << mapImage << "\n";

    std::ofstream spotOutput(spotsFile);
    if (!spotOutput) return false;
    spotOutput << "# id,name,type,intro\n";
    for (const Spot& spot : spots) {
        spotOutput << spot.id << "," << spot.name << "," << spot.type << ","
                   << spot.intro << "\n";
    }

    if (!roadNetwork.saveNodes(nodesFile)) return false;
    if (!roadNetwork.saveEdges(edgesFile)) return false;

    return true;
}

int CampusGraph::indexOfSpot(int id) const
{
    auto it = spotIdToIndex.find(id);
    return it == spotIdToIndex.end() ? -1 : it->second;
}

bool CampusGraph::hasSpot(int id) const
{
    return indexOfSpot(id) >= 0;
}

bool CampusGraph::hasSpotNode(int nodeId) const
{
    return spotNodeToIndex.find(nodeId) != spotNodeToIndex.end();
}

const Spot* CampusGraph::getSpotById(int id) const
{
    int idx = indexOfSpot(id);
    return idx < 0 ? nullptr : &spots[idx];
}

const Spot* CampusGraph::getSpotByNodeId(int nodeId) const
{
    auto it = spotNodeToIndex.find(nodeId);
    return it == spotNodeToIndex.end() ? nullptr : &spots[it->second];
}

bool CampusGraph::addSpot(const Spot& spot)
{
    if (hasSpot(spot.id) || hasSpotNode(spot.nodeId)) return false;
    spots.push_back(spot);
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::updateSpot(const Spot& spot)
{
    int idx = indexOfSpot(spot.id);
    if (idx < 0) return false;
    if (spots[idx].nodeId != spot.nodeId && hasSpotNode(spot.nodeId)) return false;
    spots[idx] = spot;
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::removeSpot(int id)
{
    int idx = indexOfSpot(id);
    if (idx < 0) return false;
    spots.erase(spots.begin() + idx);
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::addSpotWithNode(const Spot& spot, const Node& node)
{
    if (spot.nodeId != node.id || hasSpot(spot.id) || hasSpotNode(spot.nodeId)) return false;

    bool nodeAlreadyExists = hasNode(node.id);
    if (nodeAlreadyExists) {
        if (!updateNode(node)) return false;
    } else if (!addNode(node)) {
        return false;
    }

    if (!addSpot(spot)) {
        if (!nodeAlreadyExists) {
            removeNode(node.id);
        }
        return false;
    }
    return true;
}

bool CampusGraph::updateSpotWithNode(const Spot& spot, const Node& node)
{
    int idx = indexOfSpot(spot.id);
    if (idx < 0 || spot.nodeId != node.id) return false;
    if (spots[idx].nodeId != spot.nodeId && hasSpotNode(spot.nodeId)) return false;
    if (!hasNode(node.id) || !updateNode(node)) return false;
    spots[idx] = spot;
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::removeSpotAndNode(int id)
{
    const Spot* spot = getSpotById(id);
    if (!spot) return false;
    int nodeId = spot->nodeId;
    if (!removeSpot(id)) return false;
    removeNode(nodeId);
    return true;
}

bool CampusGraph::addNode(const Node& node)
{
    return roadNetwork.addNode(node);
}

bool CampusGraph::updateNode(const Node& node)
{
    return roadNetwork.updateNode(node);
}

bool CampusGraph::removeNode(int id)
{
    return roadNetwork.removeNode(id);
}

bool CampusGraph::addEdge(int from, int to)
{
    return roadNetwork.addEdge(from, to);
}

bool CampusGraph::removeEdge(int from, int to)
{
    return roadNetwork.removeEdge(from, to);
}

void CampusGraph::rebuildSpotMaps()
{
    spotIdToIndex.clear();
    spotNodeToIndex.clear();
    for (int i = 0; i < static_cast<int>(spots.size()); ++i) {
        spotIdToIndex[spots[i].id] = i;
        spotNodeToIndex[spots[i].nodeId] = i;
    }
}
