#include "CampusBackend.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>

#include "ParserUtils.h"

CampusBackend::CampusBackend(QObject *parent)
    : QObject(parent)
{
}

bool CampusBackend::load()
{
    const bool ok = graph.loadFromFiles(dataPath("spots.txt").toStdString(),
                                        dataPath("roads.txt").toStdString(),
                                        dataPath("config.txt").toStdString());
    if (ok) {
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::save()
{
    return graph.saveToFiles(dataPath("spots.txt").toStdString(),
                             dataPath("roads.txt").toStdString(),
                             dataPath("config.txt").toStdString());
}

QVariantList CampusBackend::spots() const
{
    QVariantList result;
    for (const Spot &spot : graph.allSpots()) {
        result.push_back(spotToMap(spot));
    }
    return result;
}

QVariantList CampusBackend::roads() const
{
    QVariantList result;
    for (const RoadWithPoints &road : graph.allRoads()) {
        QVariantMap item;
        item["from"] = road.from;
        item["to"] = road.to;
        item["weight"] = road.weight;
        item["points"] = pointsToVariant(road.points);
        result.push_back(item);
    }
    return result;
}

QVariantMap CampusBackend::config() const
{
    QVariantMap item;
    item["scale"] = graph.mapScale();
    item["school"] = QString::fromStdString(graph.schoolName());
    item["mapImage"] = QString::fromStdString(graph.mapImageName());
    return item;
}

QVariantMap CampusBackend::spotDetail(int id) const
{
    const Spot *spot = graph.spotById(id);
    return spot ? spotToMap(*spot) : QVariantMap();
}

QVariantMap CampusBackend::findSpotByName(const QString &name) const
{
    const int index = graph.indexOfName(name.toStdString());
    const Spot *spot = graph.spotAtIndex(index);
    return spot ? spotToMap(*spot) : QVariantMap();
}

QVariantMap CampusBackend::findShortestPath(int fromId, int toId) const
{
    PathFinder finder(&graph);
    return pathToMap(finder.shortestPath(fromId, toId));
}

QVariantMap CampusBackend::shortestPath(int fromId, int toId) const
{
    return findShortestPath(fromId, toId);
}

QVariantList CampusBackend::findAllPaths(int fromId, int toId) const
{
    PathFinder finder(&graph);
    QVariantList result;
    for (const PathResult &path : finder.allSimplePaths(fromId, toId)) {
        result.push_back(pathToMap(path));
    }
    return result;
}

QVariantList CampusBackend::findNearby(int fromId, const QString &type, int limit) const
{
    PathFinder finder(&graph);
    QVariantList result;
    for (const NearbyResult &item : finder.nearestByType(fromId, type.toStdString(), limit)) {
        QVariantMap row;
        const Spot *spot = graph.spotById(item.spotId);
        row["spot"] = spot ? spotToMap(*spot) : QVariantMap();
        row["distance"] = item.distance;
        row["path"] = pathToMap(item.path);
        result.push_back(row);
    }
    return result;
}

QVariantList CampusBackend::searchByType(const QString &type) const
{
    QVariantList result;
    for (const Spot &spot : graph.allSpots()) {
        if (spot.type == type.toStdString()) {
            result.push_back(spotToMap(spot));
        }
    }
    return result;
}

bool CampusBackend::addSpot(int id, const QString &name, const QString &type,
                            const QString &intro, double x, double y)
{
    Spot spot;
    spot.id = id;
    spot.name = name.toStdString();
    spot.type = type.toStdString();
    spot.intro = intro.toStdString();
    spot.x = x;
    spot.y = y;

    const bool ok = graph.addSpot(spot);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::updateSpot(int id, const QString &name, const QString &type,
                               const QString &intro, double x, double y)
{
    Spot spot;
    spot.id = id;
    spot.name = name.toStdString();
    spot.type = type.toStdString();
    spot.intro = intro.toStdString();
    spot.x = x;
    spot.y = y;

    const bool ok = graph.updateSpot(spot);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeSpot(int id)
{
    const bool ok = graph.removeSpot(id);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::addRoad(int fromId, int toId, const QVariantList &points)
{
    RoadWithPoints road;
    road.from = fromId;
    road.to = toId;

    for (const QVariant &value : points) {
        const QVariantMap pointMap = value.toMap();
        Waypoint point;
        point.x = pointMap.value("x").toDouble();
        point.y = pointMap.value("y").toDouble();
        road.points.push_back(point);
    }

    const bool ok = graph.addRoad(road);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::addRoadFromText(int fromId, int toId, const QString &pointsText)
{
    RoadWithPoints road;
    road.from = fromId;
    road.to = toId;

    const std::vector<std::string> tokens = splitText(pointsText.toStdString(), ' ');
    for (const std::string &token : tokens) {
        if (trimText(token).empty()) {
            continue;
        }

        const std::vector<std::string> pair = splitText(token, ',');
        if (pair.size() != 2) {
            continue;
        }

        Waypoint point;
        point.x = std::stod(pair[0]);
        point.y = std::stod(pair[1]);
        road.points.push_back(point);
    }

    const bool ok = graph.addRoad(road);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

bool CampusBackend::removeRoad(int fromId, int toId)
{
    const bool ok = graph.removeRoad(fromId, toId);
    if (ok) {
        save();
        emit dataChanged();
    }
    return ok;
}

QString CampusBackend::dataPath(const QString &fileName) const
{
    const QString local = QCoreApplication::applicationDirPath() + "/data/" + fileName;
    if (QFile::exists(local)) {
        return local;
    }
    return QDir(QCoreApplication::applicationDirPath()).absoluteFilePath("../data/" + fileName);
}

QVariantMap CampusBackend::spotToMap(const Spot &spot) const
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

QVariantMap CampusBackend::pathToMap(const PathResult &path) const
{
    QVariantMap item;
    QVariantList ids;
    QVariantList names;

    for (int id : path.spotIds) {
        ids.push_back(id);
        const Spot *spot = graph.spotById(id);
        if (spot) {
            names.push_back(QString::fromStdString(spot->name));
        }
    }

    item["ids"] = ids;
    item["names"] = names;
    item["points"] = pointsToVariant(path.drawPoints);
    item["length"] = path.totalLength;
    return item;
}

QVariantList CampusBackend::pointsToVariant(const std::vector<Waypoint> &points) const
{
    QVariantList result;
    for (const Waypoint &point : points) {
        QVariantMap item;
        item["x"] = point.x;
        item["y"] = point.y;
        result.push_back(item);
    }
    return result;
}
