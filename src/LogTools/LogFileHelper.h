#ifndef LOGFILEHELPER_H
#define LOGFILEHELPER_H

#include <QObject>
#include <QStringList>

class LogFileHelper : public QObject
{
    Q_OBJECT  // This is essential for moc

   public:
    explicit LogFileHelper(QObject* parent = nullptr);
    Q_INVOKABLE QStringList getBinFiles(const QString& path);
};

#endif // LOGFILEHELPER_H
