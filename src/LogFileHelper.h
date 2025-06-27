#ifndef LOGFILEHELPER_H
#define LOGFILEHELPER_H

#include <QObject>
#include <QStringList>
#include <QString>
#include <QDir>

class LogFileHelper : public QObject {
    Q_OBJECT

   public:
    explicit LogFileHelper(QObject* parent = nullptr);

    Q_INVOKABLE QStringList getBinFiles(const QString& path);
};

#endif // LOGFILEHELPER_H
