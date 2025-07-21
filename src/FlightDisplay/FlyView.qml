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
import QtQuick.Controls.Material 2.15
import Qt5Compat.GraphicalEffects






import QGroundControl.FactControls

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
        visible: isLoggedIn && isLoggedout
        Timer {
            id: logoutTimers
            interval: 200
            running: false
            repeat: false
            onTriggered: isLoggedout = false
        }

        MouseArea {
            anchors.fill: parent
            enabled: true
            preventStealing: true
            z: 0
            propagateComposedEvents: false
            onClicked: {}  // Block underlying click
        }

        Column {
            anchors.fill: parent


            // Header with image and gradient overlay
            Rectangle {
                width: parent.width
                height: parent.height * 0.8
                border.width: 0
                clip: true

                Image {
                    anchors.fill: parent
                    source: "/qmlimages/homepage.jpg"
                    fillMode: Image.PreserveAspectCrop
                }

            }

            // Card section
            Row {
                width: parent.width
                height: parent.height * 0.2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 30
                padding: 30

                // Card 1 - Log Upload
                Rectangle {
                    width: 350
                    height: 130
                    radius: 12
                    color: "white"
                    border.color: "#cccccc"
                    border.width: 1


                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            logUploadDialog.logFiles = logHelper.getBinFiles("C:/Users/gfhgd/OneDrive/Desktop/binfiles")
                            logUploadDialog.open()
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10


                        QGCLabel {
                            text: "Log Upload"
                            font.bold: true
                            font.pointSize: 20
                            color: "#00796B"
                        }

                        // Image {
                        //     source: "/qmlimages/docbg.png"
                        //     width: 32
                        //     height: 32
                        // }
                    }
                }                

                // Card 2 - Device Info
                Rectangle {
                    width: 350
                    height: 130
                    radius: 12
                    color: "white"
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
                        spacing: 8
                        QGCLabel {
                            text: "Device Management"
                            font.pointSize: 17
                            font.bold: true
                            color: "#37474F"
                        }

                        QGCLabel {
                            id: versionInfoLabel
                            text: ""
                            font.pointSize: 12
                            color: "#666"
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 3
                        }
                    }
                }

                // Card 3 - Connection & Begin
                Rectangle {
                    width: 720
                    height: 130
                    radius: 12
                    color: "white"
                    border.color: "#cccccc"

                    MouseArea {
                        anchors.fill: parent
                        id: hoverArea12
                        hoverEnabled: true
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 60

                        QGCLabel {
                            id: statusText1
                            width: parent.width * 0.5
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pointSize: 17
                            font.bold: true
                            wrapMode: Text.WordWrap
                            color: {
                                var v = QGroundControl.multiVehicleManager.activeVehicle
                                var q = v ? v.rcRSSI : -1
                                if (q >= 200) return "green"
                                if (q >= 150) return "orange"
                                return "red"
                            }
                            text: {
                                var v = QGroundControl.multiVehicleManager.activeVehicle
                                var q = v ? v.rcRSSI : -1
                                if (hoverArea12.containsMouse) {
                                    if (!v) {
                                        if (q < 1) return "Disconnected\nConnection: " + 0 + "%"
                                        return "Disconnected\nConnection: " + ((q / 255) * 100).toFixed(2) + "%"
                                    }
                                    if (q >= 200) return "Connected\nConnection: " + ((q / 255) * 100).toFixed(2) + "%"
                                    if (q >= 150) return "Weak Signal\nConnection: " + ((q / 255) * 100).toFixed(2) + "%"
                                    if (q < 1) return "Disconnected\nConnection: " + 0 + "%"
                                    return "Disconnected\nConnection: " + ((q / 255) * 100).toFixed(2) + "%"
                                }
                                if (!v) return "Aircraft\n not Connected"
                                if (q >= 200) return "Aircraft\n Connected"
                                if (q >= 150) return "Weak Signal"

                                return "Aircraft Disconnected"
                            }
                        }

                        Rectangle {
                            id: beginButton
                            width: 260
                            height: 70
                            radius: 10
                            color: mouseArea.containsMouse ? "#00C853" : "#00C853" // hover color transition
                            border.color: "#00A843"
                            anchors.verticalCenter: parent.verticalCenter
                            scale: mouseArea.pressed ? 0.97 : 1.0
                            Behavior on color { NumberAnimation { duration: 200 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            // Drop shadow effect
                            layer.enabled: true
                            layer.effect: DropShadow {
                                color: mouseArea.containsMouse ? "#A5D6A7" : "transparent"
                                radius: 12
                                samples: 16
                                spread: 0.2
                                verticalOffset: 4
                                horizontalOffset: 0
                            }

                            QGCLabel {
                                anchors.centerIn: parent
                                text: "Begin"
                                color: "white"
                                font.bold: true
                                font.pointSize: 16
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: logoutTimers.start()
                            }
                        }

                    }
                }



            }
        }
    }


    Dialog {
        id: logUploadDialog
        width: parent.width * 0.6
        height: parent.height * 0.8
        title: "Log Files"
        modal: true
        standardButtons: Dialog.NoButton

        property var logFiles: []

        function uploadToFirebase(filePath) {
            console.log("Uploading to Firebase:", filePath)
            return true
        }

        contentItem: Column {
            spacing: 16
            padding: 24

            ListView {
                width: parent.width
                height: parent.height - 100
                model: logUploadDialog.logFiles
                spacing: 12

                delegate: Frame {
                    width: parent.width - 100
                    height: 60
                    padding: 12
                    background: Rectangle {
                        color: "#f2f2f2"
                        radius: 8
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 16

                        // Center-aligned file name
                        Label {
                            text: modelData
                            font.pixelSize: 16
                            verticalAlignment: Label.AlignVCenter
                            horizontalAlignment: Label.AlignLeft
                            elide: Label.ElideRight
                            width: parent.width * 0.7
                        }

                        Item { width: 1; Layout.fillWidth: true }  // Spacer

                        Button {
                            text: "Upload"
                            width: 80
                            height: 40

                            onClicked: {
                                console.log("Upload clicked:", modelData)
                                if (logUploadDialog.uploadToFirebase(modelData)) {
                                    logUploadDialog.logFiles.splice(index, 1)
                                    logUploadDialog.logFiles = logUploadDialog.logFiles.slice()
                                }
                            }

                            background: Rectangle {
                                color: "#4CAF50"
                                radius: 6
                            }

                            contentItem: Text {
                                text: "Upload"
                                color: "white"
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }

                        Button {
                            text: "Cancel"
                            width: 80
                            height: 40

                            onClicked: {
                                console.log("Cancel clicked:", modelData)
                                logUploadDialog.logFiles.splice(index, 1)
                                logUploadDialog.logFiles = logUploadDialog.logFiles.slice()
                            }

                            background: Rectangle {
                                color: "#F44336"
                                radius: 6
                            }

                            contentItem: Text {
                                text: "Cancel"
                                color: "white"
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }

            // Bottom Close Button
            DialogButtonBox {
                alignment: Qt.AlignLeft
                standardButtons: DialogButtonBox.Close
                onRejected: logUploadDialog.close()
            }
        }
    }

    // Animation block - declare at same level as startupOverlay
    // SequentialAnimation {
    //     id: fadeOutAnim
    //     running: false
    //     PropertyAnimation {
    //         target: startupOverlay
    //         property: "opacity"
    //         from: 1
    //         to: 0
    //         duration: 500
    //     }
    //     ScriptAction {
    //         script: startupOverlay.visible = false
    //     }
    // }



}


