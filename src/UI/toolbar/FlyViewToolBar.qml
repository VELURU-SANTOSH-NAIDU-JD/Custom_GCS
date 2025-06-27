//qt code updated

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
import QtQuick.Layouts
import QtQuick.Dialogs
import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers
import QtPositioning
import QtCore
import QtNetwork



Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    color:  qgcPal.toolbarBackground

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: qgcPal.brandingPurple

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          "black"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }

    Rectangle {
        anchors.fill: viewButtonRow

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;                                     color: _mainStatusBGColor }
            GradientStop { position: currentButton.x + currentButton.width; color: _mainStatusBGColor }
            GradientStop { position: 1;                                     color: _root.color }
        }
    }

    RowLayout {
        id:                     viewButtonRow
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2

        QGCToolBarButton {
            id:                     currentButton
            Layout.preferredHeight: viewButtonRow.height
            icon.source:            "/res/QGCLogoFull.svg"
            logo:                   true
            onClicked:              mainWindow.showToolSelectDialog()
        }

        MainStatusIndicator {
            id: mainStatusIndicator
            Layout.preferredHeight: viewButtonRow.height
        }

        QGCButton {
            id:                 disconnectButton
            text:               qsTr("Disconnect")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
        }
    }

    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 2
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          parent.right
        contentWidth:           toolIndicators.width
        flickableDirection:     Flickable.HorizontalFlick

        FlyViewToolBarIndicators { id: toolIndicators }
    }

    //-------------------------------------------------------------------------
    //-- Branding Logo
    Image {
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
        visible:                _activeVehicle && !_communicationLost && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
        fillMode:               Image.PreserveAspectFit
        source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
        mipmap:                 true

        property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
        property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
        property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
        property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
        property bool   _userBrandingIndoor:    QGroundControl.settingsManager.brandImageSettings.visible && _userBrandImageIndoor.length != 0
        property bool   _userBrandingOutdoor:   QGroundControl.settingsManager.brandImageSettings.visible && _userBrandImageOutdoor.length != 0
        property string _brandImageIndoor:      brandImageIndoor()
        property string _brandImageOutdoor:     brandImageOutdoor()

        function brandImageIndoor() {
            if (_userBrandingIndoor) {
                return _userBrandImageIndoor
            } else {
                if (_userBrandingOutdoor) {
                    return _userBrandImageOutdoor
                } else {
                    if (_corePluginBranding) {
                        return QGroundControl.corePlugin.brandImageIndoor
                    } else {
                        return _activeVehicle ? _activeVehicle.brandImageIndoor : ""
                    }
                }
            }
        }

        function brandImageOutdoor() {
            if (_userBrandingOutdoor) {
                return _userBrandImageOutdoor
            } else {
                if (_userBrandingIndoor) {
                    return _userBrandImageIndoor
                } else {
                    if (_corePluginBranding) {
                        return QGroundControl.corePlugin.brandImageOutdoor
                    } else {
                        return _activeVehicle ? _activeVehicle.brandImageOutdoor : ""
                    }
                }
            }
        }
    }

    // Small parameter download progress bar
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    // Large parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
            color:          qgcPal.colorGreen
        }

        QGCLabel {
            anchors.centerIn:   parent
            text:               qsTr("Downloading")
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }


    //custom modifications


    ComboBox {
                            id: modeCombo
                            anchors.right:parent.right
                            anchors.top:parent.top
                            anchors.margins:8
                            anchors.rightMargin: 200
                            enabled:QGroundControl.multiVehicleManager.activeVehicle !== null
                            width: 130
                            model: ["Loiter", "Stabilize", "Guided", "Auto", "RTL","Land",]
                            onCurrentTextChanged: {
                                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                                if (vehicle) {
                                    vehicle.flightMode = currentText
                                }
                            }
                        }


    Button{
            id:armtoggler
            anchors.right:modeCombo.left
            anchors.top:parent.top
            anchors.topMargin: 8
            anchors.rightMargin:8
            text:"Arm/Disarm"
            enabled:QGroundControl.multiVehicleManager.activeVehicle !== null

            onClicked:{
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if(vehicle){
                    //toggle btwn arm and disarm
                    vehicle.armed = !vehicle.armed  // Toggle arm state
                }
            }
        }


    Button{
            id: missionControlButton
            anchors.right:armtoggler.left
            anchors.top:parent.top
            anchors.topMargin: 8
            anchors.rightMargin:8
            text: "Mission"
            enabled: QGroundControl.multiVehicleManager.activeVehicle !== null
            onClicked: {
                missionControlDialog.open()
            }
        }
























    // Mission Control Dialog

    Dialog {
            id: missionControlDialog
            title: "Mission Control"
            modal: false
            anchors.centerIn: parent
            width: 700 // Further increased width for better visibility
            height: 850 // Further increased height for better visibility
            standardButtons: Dialog.Close
            background: Rectangle {
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0.2; color: "#1b9500" }
                    GradientStop { position: 0.5; color: "#0e3e04" }
                    GradientStop { position: 1.0; color: "#051302" }
                }
            }


            // Mission state properties
            property bool modeChangeConfirmed: false
            property bool armConfirmed: false
            property bool altitudeReached: false
            property bool targetReached: false
            property var missionPoints: []
            property var missionCoordinates: []
            property bool firebaseLoggingEnabled: false
            property string firebaseUrl: "" // Firebase REST API URL
            property real latitude : 0.00
            property real longitude: 0.00
            property int currentWaypointIndex: 0
            // Timer to check altitude reached
            Timer {
                id: altitudeCheckTimer
                interval: 1000 // check every second
                repeat: true
                running: false
                onTriggered: {
                    var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                    if (vehicle) {
                        var targetAlt = missionControlDialog.missionCoordinates[0].alt
                        var currentAlt = vehicle.altitudeRelative.value
                        var diff = Math.abs(currentAlt - targetAlt)

                        if (diff <= 0.5) {
                            altitudeCheckTimer.stop()
                            missionControlDialog.altitudeReached = true
                            missionControlDialog.currentWaypointIndex = 0
                            missionControlDialog.sendToNextWaypoint()
                        }
                        missionStatusLabel.text = "Climbing: " + currentAlt.toFixed(1) + "m / " + targetAlt.toFixed(1) + "m"
                    }
                    }
                }



            // Timer to check if target location reached
            Timer {
                id: locationCheckTimer
                interval: 2000 // check every 2 seconds
                repeat: true
                running: false
                onTriggered: {
                    var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                    if (vehicle) {
                        var targetLat = missionControlDialog.latitude
                        var targetLon = missionControlDialog.longitude
                        var currentLat = vehicle.coordinate.latitude
                        var currentLon = vehicle.coordinate.longitude

                        // Calculate distance (simple approximation)
                        var latDiff = Math.abs(currentLat - targetLat)
                        var lonDiff = Math.abs(currentLon - targetLon)
                        var distance = Math.sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111000 // rough meters

                        missionStatusLabel.text = "Distance to target: " + distance.toFixed(1) + "m"

                        // If within 5 meters of target (horizontal distance)
                        if (distance < 5) {
                            locationCheckTimer.stop()
                            missionControlDialog.recordPoint("WAYPOINT_" + (missionControlDialog.currentWaypointIndex + 1))
                            missionControlDialog.currentWaypointIndex += 1
                            missionControlDialog.sendToNextWaypoint()
                        }

                    }
                }
            }


            // Timer to check if mode changed successfully
            Timer {
                id: modeCheckTimer
                interval: 1000
                repeat: true
                running: false
                onTriggered: {
                    var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                    console.log(vehicle.flightMode)
                    if (vehicle && vehicle.flightMode.toLocaleUpperCase() === "GUIDED") {
                        missionControlDialog.modeChangeConfirmed = true
                        modeCheckTimer.stop()
                        missionStatusLabel.text = "GUIDED mode confirmed. Arming..."
                        missionControlDialog.recordPoint("MODE_CHANGE")

                        // Arm the vehicle
                        if (!vehicle.armed) {
                            vehicle.armed = true
                            armCheckTimer.start()
                        } else {
                            missionControlDialog.armConfirmed = true
                            missionStatusLabel.text = "Vehicle already armed. Taking off..."
                            missionControlDialog.takeoff()
                        }
                    } else {
                        missionStatusLabel.text = "Failed to change to GUIDED mode"
                    }
                }
            }

            // Timer for Firebase logging
            Timer {
                id: firebaseLoggingTimer
                interval: 1000 // Send data every 1 second
                repeat: true
                running: missionControlDialog.firebaseLoggingEnabled
                onTriggered: {
                    missionControlDialog.sendDataToFirebase()
                }
            }

            // Timer to check if armed successfully
            Timer {
                id: armCheckTimer
                interval: 1000
                repeat: true
                running: false
                onTriggered: {
                    var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                    if (vehicle && vehicle.armed) {
                        missionControlDialog.armConfirmed = true
                        armCheckTimer.stop()
                        missionStatusLabel.text = "Vehicle armed. Taking off..."
                        missionControlDialog.recordPoint("ARMED")

                        // Take off
                        missionControlDialog.takeoff()
                    } else {
                        missionStatusLabel.text = "Failed to arm vehicle"
                    }
                }
            }

            // --- Moved functions inside Dialog scope ---
            function exportToCSV() {
                if (missionControlDialog.missionPoints.length === 0) {
                    missionStatusLabel.text = "No mission data to export"
                    return
                }
                csvFileDialog.open();
            }
            signal saveCSVRequested(string fileUrl, string csvContent)
            function saveCSVToFile(fileUrl) {
                var csvContent = "Latitude,Longitude,Altitude,Status,Timestamp\n"
                for (var i = 0; i < missionControlDialog.missionPoints.length; i++) {
                    var point = missionControlDialog.missionPoints[i]
                    csvContent += point.lat + "," +
                                  point.lon + "," +
                                  point.alt + "," +
                                  point.status + "," +
                                  point.timestamp + "\n"
                }
                saveCSVRequested(fileUrl, csvContent)
                missionStatusLabel.text = "CSV save requested: " + fileUrl
            }

            function sendToNextWaypoint() {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (currentWaypointIndex < missionCoordinates.length) {
                    var wp = missionCoordinates[currentWaypointIndex]
                    missionStatusLabel.text = "Navigating to waypoint " + (currentWaypointIndex + 1)
                    missionControlDialog.latitude = wp.lat
                    missionControlDialog.longitude = wp.lon
                    missionStatusLabel.text = missionControlDialog.latitude + ", " + missionControlDialog.longitude
                    vehicle.guidedModeGotoLocation(QtPositioning.coordinate(wp.lat, wp.lon, wp.alt))
                    locationCheckTimer.start()
                } else {
                    missionControlDialog.returnToLaunch()
                }
            }

            function recordPoint(status) {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (vehicle) {
                    var point = {
                        timestamp: new Date().toISOString(),
                        lat: vehicle.coordinate.latitude,
                        lon: vehicle.coordinate.longitude,
                        alt: vehicle.altitudeRelative.value,
                        status: status
                    }
                    missionControlDialog.missionPoints.push(point)
                }
            }

            function sendDataToFirebase() {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (!vehicle || !missionControlDialog.firebaseLoggingEnabled || missionControlDialog.firebaseUrl === "") {
                    return
                }

                // Create data object to send
                var data = {
                    timestamp: new Date().toISOString(),
                    lat: vehicle.coordinate.latitude,
                    lon: vehicle.coordinate.longitude,
                    alt: vehicle.altitudeRelative.value,
                    armed: vehicle.armed,
                    flightMode: vehicle.flightMode,
                    groundSpeed: vehicle.groundSpeed.value,
                    airSpeed: vehicle.airSpeed.value,
                    heading: vehicle.heading.value,
                    // battery: vehicle.battery.percentRemaining.value
                }

                // Use XMLHttpRequest to send data
                var xhr = new XMLHttpRequest()
                xhr.open("POST", missionControlDialog.firebaseUrl)
                xhr.setRequestHeader("Content-Type", "application/json")
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            console.log("Data sent to Firebase successfully")
                        } else {
                            console.log("Failed to send data to Firebase: " + xhr.status)
                        }
                    }
                }
                if (vehicle.armed === true){
                    xhr.send(JSON.stringify(data))
                }


            }

            function startMission() {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (!vehicle) {
                    missionStatusLabel.text = "No vehicle connected"
                    return
                }

                if (missionControlDialog.missionCoordinates.length === 0) {
                    missionStatusLabel.text = "No waypoints added"
                    return
                }

                // Reset mission state
                missionControlDialog.modeChangeConfirmed = false
                missionControlDialog.armConfirmed = false
                missionControlDialog.altitudeReached = false
                missionControlDialog.targetReached = false

                // Change to GUIDED mode
                vehicle.flightMode = "Guided"
                missionStatusLabel.text = "Changing to GUIDED mode..."

                // Start checking if mode changed
                modeCheckTimer.start()
            }


            function takeoff() {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (vehicle) {
                    var firstAlt = missionControlDialog.missionCoordinates[0].alt
                    vehicle.guidedModeTakeoff(firstAlt)
                    missionStatusLabel.text = "Taking off to " + firstAlt + "m..."
                    missionControlDialog.recordPoint("TAKEOFF_INITIATED")
                    altitudeCheckTimer.start()
                }
            }



            function returnToLaunch() {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (vehicle) {
                    vehicle.flightMode = "RTL"
                    missionStatusLabel.text = "Returning to launch point..."
                    missionControlDialog.recordPoint("RTL_INITIATED")

                    // Stop all timers
                    altitudeCheckTimer.stop()
                    locationCheckTimer.stop()
                }
            }

            function land() {
                var vehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (vehicle) {
                    vehicle.flightMode = "Land"
                    missionStatusLabel.text = "Landing at current location..."
                    missionControlDialog.recordPoint("LAND_INITIATED")

                    // Stop all timers
                    altitudeCheckTimer.stop()
                    locationCheckTimer.stop()
                }
            }
            // --- End moved functions ---

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30 // Increased margin for clarity
                spacing: 20

                // Coordinates input section
                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    Layout.fillWidth: true

                    Label { text: "Latitude:"
                            color:"#ffffff"}
                    TextField {
                        id: latitudeInput
                        placeholderText: "e.g. 37.7749"
                        Layout.fillWidth: true
                        validator: DoubleValidator {}
                    }

                    Label { text: "Longitude:"
                            color:"#ffffff"}
                    TextField {
                        id: longitudeInput
                        placeholderText: "e.g. -122.4194"
                        Layout.fillWidth: true
                        validator: DoubleValidator {}
                    }

                    Label { text: "Altitude (m):"
                            color:"#ffffff"}
                    TextField {
                        id: altitudeInput
                        placeholderText: "e.g. 10"
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 1 }
                    }

                    RowLayout {
                        Layout.columnSpan: 2
                        Layout.alignment: Qt.AlignRight

                        Button {
                            text: "Live location"
                            Layout.alignment: Qt.AlignLeft
                            onClicked: {
                                var vehicle = QGroundControl.multiVehicleManager.activeVehicle

                                if (altitudeInput.text){

                                    var point = {
                                        lat: parseFloat(vehicle.coordinate.latitude),
                                        lon: parseFloat(vehicle.coordinate.longitude),
                                        alt: parseFloat(altitudeInput.text),
                                        status: "WAYPOINT",
                                        timestamp: new Date().toISOString()
                                    }
                                    missionControlDialog.missionCoordinates.push(point)
                                    missionStatusLabel.text = "Point added (" + point.lat + ", " + point.lon + ", " + point.alt + ")" +
                                                              " , " + " Total Waypoints add: " + missionControlDialog.missionCoordinates.length
                                    altitudeInput.text = ""
                                }
                                else{
                                    var points = {
                                        lat: parseFloat(vehicle.coordinate.latitude),
                                        lon: parseFloat(vehicle.coordinate.longitude),
                                        alt: parseFloat(10),
                                        status: "WAYPOINT",
                                        timestamp: new Date().toISOString()
                                    }
                                    missionControlDialog.missionCoordinates.push(points)
                                    missionStatusLabel.text = "Point added (" + points.lat + ", " + points.lon + ", " + points.alt + ")" +
                                                              " , " + " Total Waypoints add: " + missionControlDialog.missionCoordinates.length
                                }



                            }
                        }

                        Button {
                            text: "Add"
                            Layout.alignment: Qt.AlignRight
                            onClicked: {
                                if (latitudeInput.text && longitudeInput.text && altitudeInput.text) {
                                    var point = {
                                        lat: parseFloat(latitudeInput.text),
                                        lon: parseFloat(longitudeInput.text),
                                        alt: parseFloat(altitudeInput.text),
                                        status: "WAYPOINT",
                                        timestamp: new Date().toISOString()
                                    }
                                    missionControlDialog.missionCoordinates.push(point)
                                    missionStatusLabel.text = "Point added (" + point.lat + ", " + point.lon + ", " + point.alt + ")" +
                                                              " , " + " Total Waypoints add: " + missionControlDialog.missionCoordinates.length
                                    latitudeInput.text = ""
                                    longitudeInput.text = ""
                                    altitudeInput.text = ""
                                } else {
                                    missionStatusLabel.text = "Please enter valid coordinates and altitude"
                                }
                            }
                        }
                    }



                }


                // Mission control buttons
                GroupBox {
                    title: "Mission Control"
                    Layout.fillWidth: true
                    label: Label {
                            text: "Mission Control"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                    }

                    ColumnLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        RowLayout {
                            spacing: 10
                            Layout.fillWidth: true
                            Button {
                                text: "Start"
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                onClicked: { missionControlDialog.startMission() }
                            }
                            Button {
                                text: "RTL"
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                onClicked: { missionControlDialog.returnToLaunch() }
                            }
                            Button {
                                text: "Land"
                                Layout.fillWidth: true
                                Layout.preferredWidth: 80
                                onClicked: { missionControlDialog.land() }
                            }

                            Button {
                                text: "Reset"
                                Layout.columnSpan: 2
                                Layout.alignment: Qt.AlignRight
                                onClicked: {
                                    altitudeCheckTimer.stop()
                                    locationCheckTimer.stop()
                                    modeCheckTimer.stop()
                                    armCheckTimer.stop()
                                    firebaseLoggingTimer.stop()
                                    missionControlDialog.missionPoints = []
                                    missionControlDialog.missionCoordinates = []
                                    missionControlDialog.modeChangeConfirmed = false
                                    missionControlDialog.armConfirmed = false
                                    missionControlDialog.altitudeReached = false
                                    missionControlDialog.targetReached = false
                                    missionStatusLabel.text = "Mission reset."
                                }
                            }
                        }
                        // Button {
                        //     text: "Export CSV"
                        //     Layout.fillWidth: true
                        //     Layout.topMargin: 8
                        //     onClicked: { missionControlDialog.exportToCSV() }
                        // }

                        // Firebase logging section
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            Layout.topMargin: 10
                            Layout.bottomMargin: 5
                        }

                        Label {
                            text: "Firebase Cloud Logging"
                            font.bold: true
                            color:"#ffffff"
                        }

                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true

                            Label {
                                text: "Firebase REST API URL:"
                                color:"#ffffff"
                            }

                            TextField {
                                id: firebaseUrlInput
                                Layout.fillWidth: true
                                placeholderText: "https://your-project.firebaseio.com/data.json"
                                onTextChanged: {
                                    missionControlDialog.firebaseUrl = text
                                }
                            }

                            CheckBox {
                                id: firebaseLoggingCheckbox
                                text: "Enable Firebase Logging"
                                checked: missionControlDialog.firebaseLoggingEnabled
                                contentItem: Text {
                                        text: firebaseLoggingCheckbox.text
                                        color: "white"  // Or any hex like "#ff5733"
                                        font.pixelSize: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        leftPadding: firebaseLoggingCheckbox.indicator.width + firebaseLoggingCheckbox.spacing
                                    }
                                onCheckedChanged: {
                                    missionControlDialog.firebaseLoggingEnabled = checked
                                    if (checked && firebaseUrlInput.text === "") {
                                        missionStatusLabel.text = "Please enter a valid Firebase URL"
                                        checked = false
                                    } else if (checked) {
                                        missionStatusLabel.text = "Firebase logging enabled - sending data every 1 second"
                                    } else {
                                        missionStatusLabel.text = "Firebase logging disabled"
                                    }
                                }
                            }

                            Label {
                                text: "Sends telemetry data to Firebase every 1 second"
                                font.italic: true
                                font.pointSize: 8
                                Layout.fillWidth: true
                                color: "#ffffff"
                            }
                        }
                    }
                }

                // Status display
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#f0f0f0"
                    border.color: "#cccccc"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Label {
                            text: "Mission Status:"
                            font.bold: true
                        }

                        Label {
                            id: missionStatusLabel
                            text: "Ready to start mission"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            visible: true // Always visible
                            color: "#222222" // Make text more visible
                            font.pointSize: 14
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#cccccc"
                        }

                        Label {
                            text: "Vehicle Status:"
                            font.bold: true
                            visible: QGroundControl.multiVehicleManager.activeVehicle !== null
                        }

                        GridLayout {
                            columns: 2
                            rowSpacing: 5
                            columnSpacing: 10
                            Layout.fillWidth: true
                            visible: QGroundControl.multiVehicleManager.activeVehicle !== null

                            Label { text: "Mode:" }
                            Label {
                                text: QGroundControl.multiVehicleManager.activeVehicle ?
                                      QGroundControl.multiVehicleManager.activeVehicle.flightMode : ""
                                font.bold: true
                            }

                            Label { text: "Armed:" }
                            Label {
                                text: QGroundControl.multiVehicleManager.activeVehicle ?
                                      (QGroundControl.multiVehicleManager.activeVehicle.armed ? "Yes" : "No") : ""
                                font.bold: true
                            }

                            Label { text: "Altitude:" }
                            Label {
                                text: QGroundControl.multiVehicleManager.activeVehicle ?
                                      QGroundControl.multiVehicleManager.activeVehicle.altitudeRelative.value.toFixed(1) + " m" : ""
                                font.bold: true
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }
            }

            // Add a FileDialog for file selection (CSV export)
            FileDialog {
                id: csvFileDialog
                title: "Save Mission CSV File"
                nameFilters: ["CSV files (*.csv)", "Zip files (*.zip *.7z)"]
                fileMode: FileDialog.SaveFile // Explicitly set to save mode
                onAccepted: {
                    var fileUrl = csvFileDialog.currentFile;
                    if (fileUrl) {
                        var fullPath = "";
                        if (typeof fileUrl === "string") {
                            if (fileUrl.startsWith("file:///")) {
                                fullPath = fileUrl.replace("file:///", "");
                            } else {
                                fullPath = fileUrl;
                            }
                        } else if (fileUrl.toLocalFile) {
                            fullPath = fileUrl.toLocalFile();
                        } else if (fileUrl.toString) {
                            var urlStr = fileUrl.toString();
                            fullPath = urlStr.startsWith("file:///") ? urlStr.replace("file:///", "") : urlStr;
                        }
                        missionControlDialog.saveCSVToFile(fullPath);
                    } else {
                        missionStatusLabel.text = "No file selected for saving CSV.";
                    }
                }
            }
        }

















    // Button {
    //     id: connectionStatusButton
    //     text: "Connection Status"
    //     anchors.right: detailsButton.left
    //     anchors.top: parent.top
    //     anchors.topMargin: 8
    //     anchors.rightMargin: 8
    //     onClicked: connectionDialog.open()
    // }

    // Dialog {
    //     id: connectionDialog
    //     modal: true
    //     width: 350
    //     height: 250
    //     visible: false
    //     x: (Screen.width - width) / 2
    //     y: (Screen.height - height) / 2

    //     Rectangle {
    //         anchors.fill: parent
    //         color: qgcPal.window
    //         radius: 8
    //         border.color: qgcPal.text

    //         Column {
    //             anchors.centerIn: parent
    //             spacing: 20
    //             Rectangle {
    //                 id: linkStatusBox
    //                 width: 250
    //                 height: 70
    //                 radius: 6
    //                 color: Qt.rgba(0.15, 0.15, 0.15, 0.9)
    //                 border.color: "gray"

    //                 MouseArea {
    //                     id: hoverArea1
    //                     anchors.fill: parent
    //                     hoverEnabled: true
    //                 }

    //                 Row {
    //                     anchors.centerIn: parent
    //                     spacing: 10

    //                     QGCLabel {
    //                         id: iconLabel
    //                         text: {
    //                             var v = QGroundControl.multiVehicleManager.activeVehicle
    //                             var q = v ? v.rcRSSI : -1
    //                             if (!hoverArea1.containsMouse) return ""
    //                             if (q >= 80) return "✅"
    //                             if (q >= 40) return "⚠️"
    //                             return "❌"
    //                         }
    //                         color: {
    //                             var v = QGroundControl.multiVehicleManager.activeVehicle
    //                             var q = v ? v.rcRSSI : -1
    //                             if (!hoverArea1.containsMouse) return qgcPal.text
    //                             if (q >= 80) return "green"
    //                             if (q >= 40) return "orange"
    //                             return "red"
    //                         }
    //                     }

    //                     QGCLabel {
    //                         id: statusText
    //                         text: {
    //                             var v = QGroundControl.multiVehicleManager.activeVehicle
    //                             var q = v ? v.rcRSSI : -1
    //                             if (!hoverArea1.containsMouse) return "Up to date"
    //                             if (!v) return "No Vehicle\nConnection: 0%"
    //                             if (q >= 80) return "Connected\nConnection: " + q + "%"
    //                             if (q >= 40) return "Weak Signal\nConnection: " + q + "%"
    //                             return "Disconnected\nConnection: " + (q >= 0 ? q : 0) + "%"
    //                         }
    //                         color: iconLabel.color
    //                     }


    //                 }
    //             }

    //         }
    //     }

    //     Timer {
    //         interval: 1000
    //         running: visible
    //         repeat: true
    //         onTriggered: {
    //             var v = QGroundControl.multiVehicleManager.activeVehicle
    //             reconnectButton.visible = !v || v.linkQuality < 40
    //         }
    //     }

    //     onVisibleChanged: {
    //         if (visible) {
    //             var v = QGroundControl.multiVehicleManager.activeVehicle
    //             reconnectButton.visible = !v || v.linkQuality < 40
    //         }
    //     }
    // }













    // Button {
    //     id: detailsButton
    //     text: "Details"
    //     anchors.right: missionControlButton.left
    //     anchors.top: parent.top
    //     anchors.topMargin: 8
    //     anchors.rightMargin: 8
    //     onClicked: {
    //         // detailsDialog.open()
    //     }
    // }

    // Dialog {
    //     id: detailsDialog
    //     modal: true
    //     focus: true
    //     x: (Screen.width - width) / 2
    //     y: (Screen.height - height) / 2
    //     width: 300
    //     height: 200
    //     visible: false

    //     Rectangle {
    //         anchors.fill: parent
    //         color: qgcPal.window
    //         radius: 6
    //         border.color: qgcPal.text

    //         Column {
    //             anchors.centerIn: parent
    //             spacing: 10

    //             // Hover-based expanding section
    //             Item {
    //                 id: hoverContainer
    //                 width: 200
    //                 height: 60

    //                 Rectangle {
    //                     id: deviceMgmtHeader
    //                     width: parent.width
    //                     height: parent.height
    //                     color: Qt.rgba(0.15, 0.15, 0.15, 0.9)
    //                     radius: 6
    //                     border.color: "gray"

    //                     Column {
    //                         anchors.centerIn: parent
    //                         spacing: 2

    //                         QGCLabel {
    //                             text: "Device Management"
    //                             font.bold: true
    //                             horizontalAlignment: Text.AlignHCenter
    //                             anchors.horizontalCenter: parent.horizontalCenter
    //                             color: qgcPal.text
    //                         }

    //                         QGCLabel {
    //                             id: versionInfoLabel
    //                             text: hoverArea.containsMouse ?
    //                                   ("Firmware: " +
    //                                     (_activeVehicle ? _activeVehicle.firmwareMajorVersion + "." +
    //                                                       _activeVehicle.firmwareMinorVersion + "." +
    //                                                       _activeVehicle.firmwarePatchVersion : "--") +
    //                                    "\nApp: " + QGroundControl.qgcVersion)
    //                                   : "Up to date"
    //                             font.pointSize: ScreenTools.smallFontPointSize
    //                             horizontalAlignment: Text.AlignHCenter
    //                             anchors.horizontalCenter: parent.horizontalCenter
    //                             color: qgcPal.text
    //                             wrapMode: Text.Wrap
    //                             maximumLineCount: 2
    //                         }
    //                     }

    //                     MouseArea {
    //                         id: hoverArea
    //                         anchors.fill: parent
    //                         hoverEnabled: true
    //                         onEntered: versionInfoLabel.text =
    //                             "Firmware: " +
    //                             (_activeVehicle ? _activeVehicle.firmwareMajorVersion + "." +
    //                                               _activeVehicle.firmwareMinorVersion + "." +
    //                                               _activeVehicle.firmwarePatchVersion : "--") +
    //                             "\nApp: " + QGroundControl.qgcVersion
    //                         onExited: versionInfoLabel.text = "Up to date"
    //                     }
    //                 }
    //             }

    //             Button {
    //                 text: "Close"
    //                 onClicked: detailsDialog.close()
    //                 width: 100
    //                 anchors.horizontalCenter: parent.horizontalCenter
    //             }
    //         }
    //     }
    // }















    // Rectangle {
    //         id: deviceMgmtHeader
    //         anchors.right: missionControlButton.left
    //         width: 180
    //         height: 50
    //         radius: 6
    //         anchors.top:parent.top
    //         color: "white"
    //         border.color: "gray"
    //         anchors.topMargin: 3


    //         MouseArea {
    //             id: hoverArea
    //             anchors.fill: parent
    //             hoverEnabled: true
    //             onEntered: versionInfoLabel.text =
    //                 "Firmware: " +
    //                 (_activeVehicle ? _activeVehicle.firmwareMajorVersion + "." +
    //                                   _activeVehicle.firmwareMinorVersion + "." +
    //                                   _activeVehicle.firmwarePatchVersion : "--") +
    //                 "\nApp: " + QGroundControl.qgcVersion
    //             onExited: versionInfoLabel.text = "Up to date"
    //         }


    //         Column {
    //             anchors.centerIn: parent
    //             QGCLabel {
    //                 text: "Device Management"
    //                 font.bold: true
    //                 // horizontalAlignment: Text.AlignTop
    //                 // anchors.horizontalCenter: parent.horizontalTop
    //                 color: "black"
    //             }

    //             QGCLabel {
    //                 id: versionInfoLabel
    //                 text: hoverArea.containsMouse ?
    //                       ("Firmware: " +
    //                         (_activeVehicle ? _activeVehicle.firmwareMajorVersion + "." +
    //                                           _activeVehicle.firmwareMinorVersion + "." +
    //                                           _activeVehicle.firmwarePatchVersion : "--") +
    //                        "\nApp: " + QGroundControl.qgcVersion)
    //                       : ""
    //                 font.pointSize: ScreenTools.smallFontPointSize
    //                 // horizontalAlignment: Text.AlignHCenter
    //                 // anchors.horizontalCenter: parent.horizontalCenter
    //                 color: "black"
    //                 wrapMode: Text.Wrap
    //                 maximumLineCount: 2
    //             }
    //         }


    //     }


















    // Rectangle {
    //     id: linkStatusBox1
    //     anchors.right: deviceMgmtHeader.left
    //     width: 170
    //     height: 40
    //     radius: 6
    //     anchors.top:parent.top
    //     anchors.topMargin: 8
    //     anchors.rightMargin:8
    //     color: "white"
    //     border.color: "gray"

    //     MouseArea {
    //         id: hoverArea12
    //         anchors.fill: parent
    //         hoverEnabled: true
    //     }

    //     Row {
    //         anchors.centerIn: parent
    //         QGCLabel {
    //             id: statusText1
    //             text: {
    //                 var v = QGroundControl.multiVehicleManager.activeVehicle
    //                 var q = v ? v.rcRSSI : -1
    //                 if (hoverArea12.containsMouse){
    //                     if (!v) return "Disconnected\nConnection: " + ((q / 255) * 100).toFixed(3) + "% "
    //                     if (q >= 200) return "Connected\nConnection: "+((q/255)*100)+"%"
    //                     if (q >= 150) return "Weak Signal\nConnection: "+((q/255)*100)+"%"
    //                     return "Disconnected/nConnection: "+((q/255)*100)+"%"
    //                 }
    //                 if (!v) return "Aircraft not Connected"
    //                 if (q >= 200) return "Aircraft Connected"
    //                 if (q >= 150) return "Weak Signal"
    //                 return "Aircraft Disconnected"
    //             }
    //             color: {
    //                 var v = QGroundControl.multiVehicleManager.activeVehicle
    //                 var q = v ? v.rcRSSI : -1
    //                 // if (!hoverArea12.containsMouse){
    //                 //     if (q >= 200) return "green"
    //                 //     if (q >= 150) return "orange"
    //                 //     return "red"
    //                 // }
    //                 if (q >= 200) return "green"
    //                 if (q >= 150) return "orange"
    //                 return "red"
    //             }
    //         }


    //     }
    // }

}

