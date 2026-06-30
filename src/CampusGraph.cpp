#include "CampusGraph.h"
#include "ParserUtils.h"

#include <fstream>

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
        spot.nodeId = std::stoi(parts[0]);
        spot.name = parts[1];
        spot.type = parts[2];
        spot.intro = parts[3];
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
    spotOutput << "# nodeId,name,type,intro\n";
    for (const Spot& spot : spots) {
        spotOutput << spot.nodeId << "," << spot.name << "," << spot.type << ","
                   << spot.intro << "\n";
    }

    if (!roadNetwork.saveNodes(nodesFile)) return false;
    if (!roadNetwork.saveEdges(edgesFile)) return false;

    return true;
}

bool CampusGraph::hasSpotNode(int nodeId) const
{
    return spotNodeToIndex.find(nodeId) != spotNodeToIndex.end();
}

const Spot* CampusGraph::getSpotByNodeId(int nodeId) const
{
    auto it = spotNodeToIndex.find(nodeId);
    return it == spotNodeToIndex.end() ? nullptr : &spots[it->second];
}

bool CampusGraph::addSpot(const Spot& spot)
{
    if (hasSpotNode(spot.nodeId)) return false;
    spots.push_back(spot);
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::updateSpot(const Spot& spot)
{
    auto it = spotNodeToIndex.find(spot.nodeId);
    int idx = it == spotNodeToIndex.end() ? -1 : it->second;
    if (idx < 0) return false;
    spots[idx] = spot;
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::removeSpot(int nodeId)
{
    auto it = spotNodeToIndex.find(nodeId);
    int idx = it == spotNodeToIndex.end() ? -1 : it->second;
    if (idx < 0) return false;
    spots.erase(spots.begin() + idx);
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::addSpotWithNode(const Spot& spot, const Node& node)
{
    if (spot.nodeId != node.id || hasSpotNode(spot.nodeId)) return false;

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
    auto it = spotNodeToIndex.find(spot.nodeId);
    int idx = it == spotNodeToIndex.end() ? -1 : it->second;
    if (idx < 0 || spot.nodeId != node.id) return false;
    if (!hasNode(node.id) || !updateNode(node)) return false;
    spots[idx] = spot;
    rebuildSpotMaps();
    return true;
}

bool CampusGraph::removeSpotAndNode(int nodeId)
{
    const Spot* spot = getSpotByNodeId(nodeId);
    if (!spot) return false;
    if (!removeSpot(nodeId)) return false;
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
    spotNodeToIndex.clear();
    for (int i = 0; i < static_cast<int>(spots.size()); ++i) {
        spotNodeToIndex[spots[i].nodeId] = i;
    }
}
