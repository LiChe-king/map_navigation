#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <QIcon>
#include <QWindow>

#include "CampusBackend.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    
    QGuiApplication app(argc, argv);

    CampusBackend backend;
    backend.load();

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("campusBackend", &backend);
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/CampusGuide/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    // 获取窗口对象并设置图标
    QWindow *window = qobject_cast<QWindow*>(engine.rootObjects().first());
    if (window) {
        // 从资源加载图标
        QIcon icon(":/qt/qml/CampusGuide/data/icon.ico");
        if (!icon.isNull()) {
            window->setIcon(icon);
        }
    }

    return app.exec();
}