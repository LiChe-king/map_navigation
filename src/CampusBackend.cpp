#include "CampusBackend.h"
#include "ParserUtils.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QDebug>

CampusBackend::CampusBackend(QObject* parent)
    : QObject(parent)
{
}

bool CampusBackend::load()
{
    QString basePath = dataPath("");
    bool ok = graph.loadFromFiles(
        (basePath + "spots.txt").toStdString(),
        (basePath + "nodes.txt").toStdString(),
        (basePath + "edges.txt").toStdString(),
        (basePath + "config.txt").toStdString()
    );
    
    if (ok) {
        emit dataChanged();
        qDebug() << "Load success: spots =" << graph.getAllSpots().size()
                 << "nodes =" << graph.getAllNodes().size();
    } else {
        qDebug() << "Load failed";
    }
    return ok;
}

bool CampusBackend::save()
{
    QString basePath = dataPath("");
    bool ok = graph.saveToFiles(
        (basePath + "spots.txt").toStdString(),
        (basePath + "nodes.txt").toStdString(),
        (basePath + "edges.txt").toStdString(),
        (basePath + "config.txt").toStdString()
    );
    
    if (ok) {
        emit dataChanged();
        qDebug() << "Save success";
    }
    return ok;
}

// ========== 景点 ==========

QVariantList CampusBackend::spots() const
{
    QVariantList result;
    for (const Spot& spot : graph.getAllSpots()) {
        result.push_back(spotToMap(spot));
    }
    return result;
}

QVariantMap CampusBackend::spotDetail(int id) const
{
    const Spot* spot = graph.getSpotById(id);
    return spot ? spotToMap(*spot) : QVariantMap();
}

bool CampusBackend::addSpot(int id, const QString& name, const QString& type,
                            const QString& intro, double x, double y)
{
    Spot spot;
    spot.id = id;
    spot.name = name.toStdString();
    spot.type = type.toStdString();
    spot.intro = intro.toStdString();
    spot.x = x;
    spot.y = y;
    
    bool ok = graph.addSpot(spot);
    if (ok) {
        // 同时自动添加一个同名节点（用于路网）
        Node node;
        node.id = id;
        node.x = x;
        node.y = y;
        graph.addNode(node);
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::updateSpot(int id, const QString& name, const QString& type,
                               const QString& intro, double x, double y)
{
    Spot spot;
    spot.id = id;
    spot.name = name.toStdString();
    spot.type = type.toStdString();
    spot.intro = intro.toStdString();
    spot.x = x;
    spot.y = y;
    
    bool ok = graph.updateSpot(spot);
    if (ok) {
        // 同步更新节点坐标
        Node node;
        node.id = id;
        node.x = x;
        node.y = y;
        graph.updateNode(node);
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeSpot(int id)
{
    bool ok = graph.removeSpot(id);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

// ========== 节点（路口） ==========

QVariantList CampusBackend::nodes() const
{
    QVariantList result;
    for (const Node& node : graph.getAllNodes()) {
        result.push_back(nodeToMap(node));
    }
    return result;
}

bool CampusBackend::addNode(int id, double x, double y)
{
    Node node;
    node.id = id;
    node.x = x;
    node.y = y;
    
    bool ok = graph.addNode(node);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::updateNode(int id, double x, double y)
{
    Node node;
    node.id = id;
    node.x = x;
    node.y = y;
    bool ok = graph.updateNode(node);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeNode(int id)
{
    bool ok = graph.removeNode(id);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

// ========== 边 ==========

QVariantList CampusBackend::edges() const
{
    QVariantList result;
    const auto& adj = graph.getAdjacency();
    const auto& nodes = graph.getAllNodes();
    
    // 构建节点ID到索引的映射
    QMap<int, int> idToIdx;
    for (int i = 0; i < nodes.size(); ++i) {
        idToIdx[nodes[i].id] = i;
    }
    
    // 遍历邻接表，收集所有边（只存一次，from < to）
    for (int i = 0; i < nodes.size(); ++i) {
        int fromId = nodes[i].id;
        for (const Edge& edge : adj[i]) {
            int toId = edge.to;
            if (fromId < toId) {
                QVariantMap item;
                item["from"] = fromId;
                item["to"] = toId;
                result.push_back(item);
            }
        }
    }
    return result;
}

bool CampusBackend::addEdge(int from, int to)
{
    bool ok = graph.addEdge(from, to);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeEdge(int from, int to)
{
    bool ok = graph.removeEdge(from, to);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

// ========== 查询 ==========

QVariantMap CampusBackend::findShortestPath(int fromId, int toId) const
{
    PathFinder finder(&graph);
    PathResult result = finder.shortestPath(fromId, toId);
    return pathToMap(result);
}

QVariantList CampusBackend::findNearby(int fromId, const QString& type, int limit) const
{
    PathFinder finder(&graph);
    QVariantList result;
    
    for (const NearbyResult& item : finder.nearestByType(fromId, type.toStdString(), limit)) {
        QVariantMap row;
        const Spot* spot = graph.getSpotById(item.spotId);
        if (spot) {
            row["spot"] = spotToMap(*spot);
        }
        row["distance"] = item.distance;
        row["path"] = pathToMap(item.path);
        result.push_back(row);
    }
    return result;
}

QVariantMap CampusBackend::config() const
{
    QVariantMap item;
    item["scale"] = graph.getScale();
    item["school"] = QString::fromStdString(graph.getSchoolName());
    item["mapImage"] = QString::fromStdString(graph.getMapImage());
    return item;
}

// ========== 辅助函数 ==========

QString CampusBackend::dataPath(const QString &fileName) const
{
    const QString local = QCoreApplication::applicationDirPath() + "/data/" + fileName;
    if (QFile::exists(local)) {
        return local;
    }
    return QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../data/" + fileName);
}

QVariantMap CampusBackend::spotToMap(const Spot& spot) const
{
    QVariantMap item;
    item["id"] = spot.id;
    item["name"] = QString::fromStdString(spot.name);
    item["type"] = QString::fromStdString(spot.type);
    item["intro"] = QString::fromStdString(spot.intro);
    item["x"] = spot.x;
    item["y"] = spot.y;
    return item;
}

QVariantMap CampusBackend::nodeToMap(const Node& node) const
{
    QVariantMap item;
    item["id"] = node.id;
    item["x"] = node.x;
    item["y"] = node.y;
    return item;
}

QVariantMap CampusBackend::pathToMap(const PathResult& path) const
{
    QVariantMap item;
    QVariantList ids;
    QVariantList names;
    QVariantList points;
    
    for (int nodeId : path.nodeIds) {
        ids.push_back(nodeId);
        
        // 如果是景点，取名字
        const Spot* spot = graph.getSpotById(nodeId);
        if (spot) {
            names.push_back(QString::fromStdString(spot->name));
        } else {
            names.push_back(QString("节点%1").arg(nodeId));
        }
    }
    
    for (const auto& p : path.drawPoints) {
        QVariantMap point;
        point["x"] = p.first;
        point["y"] = p.second;
        points.push_back(point);
    }
    
    item["ids"] = ids;
    item["names"] = names;
    item["points"] = points;
    item["length"] = path.totalLength;
    return item;
}

bool CampusBackend::updateSpotOnly(int id, const QString& name, const QString& type,
                                    const QString& intro, double x, double y)
{
    Spot spot;
    spot.id = id;
    spot.name = name.toStdString();
    spot.type = type.toStdString();
    spot.intro = intro.toStdString();
    spot.x = x;
    spot.y = y;
    
    bool ok = graph.updateSpot(spot);
    if (ok) {
        Node node;
        node.id = id;
        node.x = x;
        node.y = y;
        graph.updateNode(node);
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::updateNodeOnly(int id, double x, double y)
{
    Node node;
    node.id = id;
    node.x = x;
    node.y = y;
    bool ok = graph.updateNode(node);
    if (ok) {
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::addNodeOnly(int id, double x, double y)
{
    Node node;
    node.id = id;
    node.x = x;
    node.y = y;
    bool ok = graph.addNode(node);
    if (ok) {
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeNodeOnly(int id)
{
    bool ok = graph.removeNode(id);
    if (ok) {
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::addEdgeOnly(int from, int to)
{
    bool ok = graph.addEdge(from, to);
    if (ok) {
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeEdgeOnly(int from, int to)
{
    bool ok = graph.removeEdge(from, to);
    if (ok) {
        emit dataChanged();
    }
    return ok;
}

