#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

#include "CampusGraph.h"
#include "PathFinder.h"

class CampusBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList spots READ spots NOTIFY dataChanged)
    Q_PROPERTY(QVariantList roads READ roads NOTIFY dataChanged)

public:
    explicit CampusBackend(QObject *parent = nullptr);

    Q_INVOKABLE bool load();
    Q_INVOKABLE bool save();
    Q_INVOKABLE QVariantList spots() const;
    Q_INVOKABLE QVariantList roads() const;
    Q_INVOKABLE QVariantMap config() const;
    Q_INVOKABLE QVariantMap spotDetail(int id) const;
    Q_INVOKABLE QVariantMap findSpotByName(const QString &name) const;
    Q_INVOKABLE QVariantMap findShortestPath(int fromId, int toId) const;
    Q_INVOKABLE QVariantMap shortestPath(int fromId, int toId) const;
    Q_INVOKABLE QVariantList findAllPaths(int fromId, int toId) const;
    Q_INVOKABLE QVariantList findNearby(int fromId, const QString &type, int limit) const;
    Q_INVOKABLE QVariantList searchByType(const QString &type) const;

    Q_INVOKABLE bool addSpot(int id, const QString &name, const QString &type,
                             const QString &intro, double x, double y);
    Q_INVOKABLE bool updateSpot(int id, const QString &name, const QString &type,
                                const QString &intro, double x, double y);
    Q_INVOKABLE bool removeSpot(int id);
    Q_INVOKABLE bool addRoad(int fromId, int toId, const QVariantList &points);
    Q_INVOKABLE bool addRoadFromText(int fromId, int toId, const QString &pointsText);
    Q_INVOKABLE bool removeRoad(int fromId, int toId);

signals:
    void dataChanged();

private:
    CampusGraph graph;

    QString dataPath(const QString &fileName) const;
    QVariantMap spotToMap(const Spot &spot) const;
    QVariantMap pathToMap(const PathResult &path) const;
    QVariantList pointsToVariant(const std::vector<Waypoint> &points) const;
};
