/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.LogHelper 1.0

// 3D Viewer modules
import Viewer3D

Item {
    id: _root

    LogFileHelper { id: logHelper }

    ListModel {
        id: binFilesModel
    }

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController

    // Properties of UTM adapter
    property bool utmspSendActTrigger: false


    PlanMasterController {
        id:                     _planController
        flyView:                true
        Component.onCompleted:  start()
    }

    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _missionController:     _planController.missionController
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property var    _guidedController:      guidedActionsController
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets

    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
    }

    function dropMainStatusIndicatorTool() {
        toolbar.dropMainStatusIndicatorTool();
    }

    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    FlyViewToolBar {
        id:         toolbar
        visible:    !QGroundControl.videoManager.fullScreen
    }

    Item {
        id:                 mapHolder
        anchors.top:        toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
            pipView:                _pipView
            pipMode:                !_mainWindowIsMap
            toolInsets:             customOverlay.totalToolInsets
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
        }

        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
        }

        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                        (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0
        }

        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2 // we need to add one extra layer for map 3d viewer (normally was 1)
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            visible:                !QGroundControl.videoManager.fullScreen
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
        }

        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       widgetLayer
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            visible:            !QGroundControl.videoManager.fullScreen
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      widgetLayer.z + 1
            insetsToView:           widgetLayer.totalToolInsets
            visible:                false
        }

        GuidedActionsController {
            id:                 guidedActionsController
            missionController:  _missionController
            guidedValueSlider:     _guidedValueSlider
        }

        //-- Guided value slider (e.g. altitude)
        GuidedValueSlider {
            id:                 guidedValueSlider
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            z:                  QGroundControl.zOrderTopMost
            visible:            false
        }

        Viewer3D{
            id:                     viewer3DWindow
            anchors.fill:           parent
        }
    }

    Rectangle {
        id: startupOverlay
        anchors.fill: parent
        color: "#f2f2f2ee"
        z: 9999
        visible: isLoggedIn
        opacity: 1.0

        Column {
            anchors.fill: parent

            // Header with background image
            Rectangle {
                width: parent.width
                height: parent.height * 0.80
                border.width: 0
                clip: true

                Image {
                    anchors.fill: parent
                    source: "/qmlimages/homePageImage.svg" // Replace with actual image path
                    fillMode: Image.PreserveAspectCrop
                }

            }

            // Card Section
            Row {
                width: parent.width
                height: parent.height * 0.20
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20
                padding: 30


                Row {
                    width: parent.width
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    padding: 30


                    Rectangle {
                        width: 300
                        height: 130
                        color: "white"
                        radius: 10
                        border.color: "#cccccc"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                logUploadDialog.logFiles = logHelper.getBinFiles("C:/Users/gfhgd/OneDrive/Desktop/binfiles")
                                // logUploadDialog.visible = true
                                logUploadDialog.open()
                            }
                            // Button {
                            //     text: "Test Log Dialog"
                            //     onClicked: logUploadDialog.open()
                            // }


                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            QGCLabel {
                                text: "Log Upload"
                                font.bold: true
                                font.pointSize: 14
                                color: "#222"
                            }
                            Image {
                                source: "qrc:/icons/log_upload.png"
                                width: 24
                                height: 24
                            }
                        }
                    }

                    Rectangle {
                        width: 300
                        height: 130
                        color: "white"
                        radius: 10
                        border.color: "#cccccc"
                        MouseArea {
                                id: hoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: versionInfoLabel.text =
                                    "Firmware: " +
                                    (_activeVehicle ? _activeVehicle.firmwareMajorVersion + "." +
                                                      _activeVehicle.firmwareMinorVersion + "." +
                                                      _activeVehicle.firmwarePatchVersion : "--") +
                                    "\nApp: " + QGroundControl.qgcVersion
                                onExited: versionInfoLabel.text = "Up to date"
                            }
                        Column {
                                anchors.centerIn: parent
                                QGCLabel {
                                    text: "Device Management"
                                    font.pointSize: 14
                                    font.bold: true
                                    // horizontalAlignment: Text.AlignTop
                                    // anchors.horizontalCenter: parent.horizontalTop
                                    color: "black"
                                }

                                QGCLabel {
                                    id: versionInfoLabel
                                    text: hoverArea.containsMouse ?
                                          ("Firmware: " +
                                            (_activeVehicle ? _activeVehicle.firmwareMajorVersion + "." +
                                                              _activeVehicle.firmwareMinorVersion + "." +
                                                              _activeVehicle.firmwarePatchVersion : "--") +
                                           "\nApp: " + QGroundControl.qgcVersion)
                                          : ""
                                    font.pointSize: 10
                                    // horizontalAlignment: Text.AlignHCenter
                                    // anchors.horizontalCenter: parent.horizontalCenter
                                    color: "black"
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                }
                            }
                        }

                    Rectangle {
                        width: 700
                        height: 130
                        color: "white"
                        radius: 10
                        border.color: "#cccccc"

                        MouseArea {
                            id: hoverArea12
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 70 // 10% of 700

                            QGCLabel {
                                id: statusText1
                                width: parent.width * 0.45
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                                text: {
                                    var v = QGroundControl.multiVehicleManager.activeVehicle
                                    var q = v ? v.rcRSSI : -1
                                    if (hoverArea12.containsMouse){
                                        if (!v) return "Disconnected\nConnection: " + ((q / 255) * 100).toFixed(3) + "% "
                                        if (q >= 200) return "Connected\nConnection: "+((q/255)*100).toFixed(3)+"%"
                                        if (q >= 150) return "Weak Signal\nConnection: "+((q/255)*100).toFixed(3)+"%"
                                        return "Disconnected\nConnection: "+((q/255)*100).toFixed(3)+"%"
                                    }
                                    if (!v) return "Aircraft not Connected"
                                    if (q >= 200) return "Aircraft Connected"
                                    if (q >= 150) return "Weak Signal"
                                    return "Aircraft Disconnected"
                                }
                                color: {
                                    var v = QGroundControl.multiVehicleManager.activeVehicle
                                    var q = v ? v.rcRSSI : -1
                                    if (q >= 200) return "green"
                                    if (q >= 150) return "orange"
                                    return "red"
                                }
                            }

                            Rectangle {
                                width: parent.width * 0.45
                                height: 70
                                color: "#00C853"
                                radius: 8
                                border.color: "#00A843"
                                anchors.verticalCenter: parent.verticalCenter

                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: "Begin"
                                    color: "white"
                                    font.bold: true
                                    font.pointSize: 14
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: fadeOutAnim.start()
                                }
                            }
                        }
                    }





                }



            }

        }

    }


    Dialog {
        id: logUploadDialog
        width: parent.width * 0.8
        height: parent.height * 0.8
        title: "Log Files"
        modal: true
        standardButtons: Dialog.Cancel

        property var logFiles: []

        Component.onCompleted: {
            logFiles = logHelper.getBinFiles("C:/Users/gfhgd/OneDrive/Desktop/binfiles")
        }

        function uploadToFirebase(filePath) {
            // Placeholder logic (simulate Firebase upload)
            console.log("Uploading to Firebase:", filePath)
            return true
        }

        contentItem: Column {
            spacing: 10
            padding: 10

            ListView {
                id: logFileList
                width: parent.width
                height: parent.height - 100
                model: logUploadDialog.logFiles
                spacing: 10

                delegate: Row {
                    width: parent.width
                    height: 40
                    spacing: 10

                    Text {
                        text: modelData
                        width: parent.width * 0.6
                        elide: Text.ElideRight
                        color: "black"
                    }

                    Button {
                        text: "Upload"
                        onClicked: {
                            console.log("Upload clicked:", modelData)
                            if (logUploadDialog.uploadToFirebase(modelData)) {
                                logUploadDialog.logFiles.splice(index, 1)
                                logUploadDialog.logFiles = logUploadDialog.logFiles.slice() // trigger UI update
                            }
                        }
                    }

                    Button {
                        text: "Cancel"
                        onClicked: {
                            console.log("Cancel clicked:", modelData)
                            logUploadDialog.logFiles.splice(index, 1)
                            logUploadDialog.logFiles = logUploadDialog.logFiles.slice() // trigger UI update
                        }
                    }
                }
            }
        }
    }





    // Animation block - declare at same level as startupOverlay
    SequentialAnimation {
        id: fadeOutAnim
        running: false
        PropertyAnimation {
            target: startupOverlay
            property: "opacity"
            from: 1
            to: 0
            duration: 500
        }
        ScriptAction {
            script: startupOverlay.visible = false
        }
    }



}


