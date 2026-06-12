#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include "CampusGraph.h"
#include "PathFinder.h"

class CampusBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList spots READ spots NOTIFY dataChanged)
    Q_PROPERTY(QVariantList nodes READ nodes NOTIFY dataChanged)
    Q_PROPERTY(QVariantList edges READ edges NOTIFY dataChanged)

public:
    explicit CampusBackend(QObject* parent = nullptr);
    
    // ========== 文件操作 ==========
    Q_INVOKABLE bool load();
    Q_INVOKABLE bool save();
    
    // ========== 景点相关（QML可调用） ==========
    Q_INVOKABLE QVariantList spots() const;
    Q_INVOKABLE QVariantMap spotDetail(int id) const;
    Q_INVOKABLE bool addSpot(int id, const QString& name, const QString& type, 
                             const QString& intro, double x, double y);
    Q_INVOKABLE bool updateSpot(int id, const QString& name, const QString& type,
                                const QString& intro, double x, double y);
    Q_INVOKABLE bool removeSpot(int id);
    
    // ========== 节点相关（路口，QML可调用） ==========
    Q_INVOKABLE QVariantList nodes() const;
    Q_INVOKABLE bool addNode(int id, double x, double y);
    Q_INVOKABLE bool updateNode(int id, double x, double y);   // 新增！之前缺少
    Q_INVOKABLE bool removeNode(int id);
    
    // ========== 边相关（QML可调用） ==========
    Q_INVOKABLE QVariantList edges() const;
    Q_INVOKABLE bool addEdge(int from, int to);
    Q_INVOKABLE bool removeEdge(int from, int to);
    
    // ========== 查询（QML可调用） ==========
    Q_INVOKABLE QVariantMap findShortestPath(int fromId, int toId) const;
    Q_INVOKABLE QVariantList findNearby(int fromId, const QString& type, int limit) const;
    Q_INVOKABLE QVariantMap config() const;
    
    // 只更新内存，不保存文件
    Q_INVOKABLE bool updateSpotOnly(int id, const QString& name, const QString& type,
                                    const QString& intro, double x, double y);
    Q_INVOKABLE bool updateNodeOnly(int id, double x, double y);
    Q_INVOKABLE bool addNodeOnly(int id, double x, double y);
    Q_INVOKABLE bool removeNodeOnly(int id);
    Q_INVOKABLE bool addEdgeOnly(int from, int to);
    Q_INVOKABLE bool removeEdgeOnly(int from, int to);
    
signals:
    void dataChanged();
    
private:
    CampusGraph graph;
    QString dataPath(const QString& fileName) const;
    QVariantMap spotToMap(const Spot& spot) const;
    QVariantMap nodeToMap(const Node& node) const;
    QVariantMap pathToMap(const PathResult& path) const;
};