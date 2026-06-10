#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include "CampusBackend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    CampusBackend backend;
    backend.load();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("campusBackend", &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/CampusGuide/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }
    return app.exec();
}
