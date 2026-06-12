#include "CampusGraph.h"
#include "ParserUtils.h"
#include <fstream>
#include <algorithm>

bool CampusGraph::loadFromFiles(const std::string& spotsFile,
                                const std::string& nodesFile,
                                const std::string& edgesFile,
                                const std::string& configFile) {
    // 读配置
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
    
    // 读景点
    std::ifstream spotInput(spotsFile);
    if (!spotInput) return false;
    
    spots.clear();
    std::string line;
    while (std::getline(spotInput, line)) {
        if (startsWithCommentOrEmpty(line)) continue;
        std::vector<std::string> parts = splitText(line, ',');
        if (parts.size() < 6) continue;
        
        Spot spot;
        spot.id = std::stoi(parts[0]);
        spot.name = parts[1];
        spot.type = parts[2];
        spot.intro = parts[3];
        spot.x = std::stod(parts[4]);
        spot.y = std::stod(parts[5]);
        spots.push_back(spot);
    }
    
    // 读节点和边
    if (!roadNetwork.loadNodes(nodesFile)) return false;
    if (!roadNetwork.loadEdges(edgesFile)) return false;
    
    return true;
}

bool CampusGraph::saveToFiles(const std::string& spotsFile,
                              const std::string& nodesFile,
                              const std::string& edgesFile,
                              const std::string& configFile) const {
    // 保存配置
    std::ofstream configOutput(configFile);
    if (!configOutput) return false;
    configOutput << "scale = " << roadNetwork.getScale() << "\n";
    configOutput << "school = " << schoolName << "\n";
    configOutput << "map_image = " << mapImage << "\n";
    
    // 保存景点
    std::ofstream spotOutput(spotsFile);
    if (!spotOutput) return false;
    spotOutput << "# id,name,type,intro,x,y\n";
    for (const Spot& spot : spots) {
        spotOutput << spot.id << "," << spot.name << "," << spot.type << ","
                   << spot.intro << "," << spot.x << "," << spot.y << "\n";
    }
    
    // 保存节点和边
    if (!roadNetwork.saveNodes(nodesFile)) return false;
    if (!roadNetwork.saveEdges(edgesFile)) return false;
    
    return true;
}

int CampusGraph::indexOfSpot(int id) const {
    for (int i = 0; i < (int)spots.size(); ++i) {
        if (spots[i].id == id) return i;
    }
    return -1;
}

bool CampusGraph::hasSpot(int id) const {
    return indexOfSpot(id) >= 0;
}

const Spot* CampusGraph::getSpotById(int id) const {
    int idx = indexOfSpot(id);
    return idx < 0 ? nullptr : &spots[idx];
}

bool CampusGraph::addSpot(const Spot& spot) {
    if (hasSpot(spot.id)) return false;
    spots.push_back(spot);
    return true;
}

bool CampusGraph::updateSpot(const Spot& spot) {
    int idx = indexOfSpot(spot.id);
    if (idx < 0) return false;
    spots[idx] = spot;
    return true;
}

bool CampusGraph::removeSpot(int id) {
    int idx = indexOfSpot(id);
    if (idx < 0) return false;
    spots.erase(spots.begin() + idx);
    return true;
}

bool CampusGraph::addNode(const Node& node) {
    return roadNetwork.addNode(node);
}

bool CampusGraph::updateNode(const Node& node) {
    return roadNetwork.updateNode(node);
}

bool CampusGraph::removeNode(int id) {
    return roadNetwork.removeNode(id);
}

bool CampusGraph::addEdge(int from, int to) {
    return roadNetwork.addEdge(from, to);
}

bool CampusGraph::removeEdge(int from, int to) {
    return roadNetwork.removeEdge(from, to);
}