#include "LogFileHelper.h"
#include <QDir>
#include <QFileInfoList>

LogFileHelper::LogFileHelper(QObject* parent)
    : QObject(parent) {}

QStringList LogFileHelper::getBinFiles(const QString& path) {
    QDir logDir(path);
    QStringList filters;
    filters << "*.bin";

    QStringList binFiles;

            // Get all .bin files
    QFileInfoList list = logDir.entryInfoList(filters, QDir::Files);
    for (const QFileInfo& fileInfo : list) {
        binFiles << fileInfo.absoluteFilePath();
    }
    return binFiles;
}
