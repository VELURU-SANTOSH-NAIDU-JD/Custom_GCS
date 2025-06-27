#include "LogFileHelper.h"
#include <QDir>
#include <QDebug>

LogFileHelper::LogFileHelper(QObject* parent)
    : QObject(parent)
{
}

QStringList LogFileHelper::getBinFiles(const QString& path)
{
    QDir dir(path);
    if (!dir.exists()) {
        qWarning() << "Directory does not exist:" << path;
        return {};
    }

    QStringList binFiles = dir.entryList(QStringList() << "*.bin", QDir::Files);
    return binFiles;
}
