// LogUploadDialog.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

Item {
    id: root
    width: 600
    height: 400

    property string logPath: "/sdcard/qgroundcontrol/Logs" // adjust path as needed
    property var logFiles: []

    signal closed()

    Component.onCompleted: {
        loadLogFiles()
    }

    function loadLogFiles() {
        logFiles = QGroundControl.fileManager.listFiles(logPath, "*.bin")
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        border.color: "black"
        border.width: 1
        radius: 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            Text {
                text: "Select log files to upload"
                font.pointSize: 18
                Layout.alignment: Qt.AlignHCenter
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: logFiles
                delegate: RowLayout {
                    spacing: 10
                    Text { text: modelData }
                    Button {
                        text: "Upload"
                        onClicked: {
                            console.log("Uploading:", modelData)
                            // handleUpload(modelData) — implement your logic here
                        }
                    }
                    Button {
                        text: "Cancel"
                        onClicked: {
                            console.log("Cancelled:", modelData)
                        }
                    }
                }
            }

            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: root.closed()
            }
        }
    }
}
