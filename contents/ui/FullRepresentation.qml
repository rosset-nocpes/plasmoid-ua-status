pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

import "LocationData.js" as LocationData

Item {
    id: full

    required property var controller

    // Oblast whose details are shown on the map after clicking its label.
    property string inspectedUid: ""

    readonly property bool darkMap: Kirigami.Theme.backgroundColor.hslLightness < 0.5
    readonly property color mapTextColor: darkMap ? "#f4f5f6" : "#30363c"
    readonly property color mapMutedTextColor: darkMap ? "#c5cbd0" : "#626a72"
    readonly property color labelHaloColor: darkMap ? "#e6101316" : "#d9ffffff"
    readonly property color mapPanelColor: darkMap ? "#f21c2024" : "#f2fbfcfd"

    function statusDetail(status) {
        if (status === "A") {
            return i18n("Go to shelter and follow official guidance");
        }
        const places = full.controller.affectedSummary(full.controller.selectedOblastUid);
        return places ? i18n("Active in: %1", places) : i18n("Alert active in part of the area");
    }

    function toggleInspected(uid) {
        inspectedUid = inspectedUid === uid ? "" : uid;
    }

    component MapBadge: Rectangle {
        property alias text: badgeLabel.text
        property alias textColor: badgeLabel.color
        property alias font: badgeLabel.font
        property string url: ""

        readonly property bool hasUrl: url !== ""

        width: badgeLabel.implicitWidth + Kirigami.Units.largeSpacing
        height: 28
        radius: 6
        z: 5

        PlasmaComponents.Label {
            id: badgeLabel

            anchors.centerIn: parent
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.underline: parent.hasUrl && linkArea.containsMouse
        }

        MouseArea {
            id: linkArea

            anchors.fill: parent
            enabled: parent.hasUrl
            hoverEnabled: true
            cursorShape: parent.hasUrl ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: Qt.openUrlExternally(parent.url)
        }
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 25
    Layout.preferredWidth: Kirigami.Units.gridUnit * 28
    Layout.preferredHeight: Kirigami.Units.gridUnit * 31

    Connections {
        target: full.controller

        function onExpandedChanged() {
            if (!full.controller.expanded) {
                full.inspectedUid = "";
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(full.controller.selectedColor, 0.14)

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: "data-warning"
                    color: full.controller.selectedColor
                    isMask: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: full.controller.selectedLocation.label
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: full.controller.statusText(full.controller.selectedStatus, full.controller.selectedLevel)
                    elide: Text.ElideRight
                }
            }

            PlasmaComponents.ToolButton {
                id: refreshButton

                Layout.minimumWidth: 40
                Layout.minimumHeight: 40
                icon.name: full.controller.loading ? "" : "view-refresh"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                text: i18n("Refresh")
                display: PlasmaComponents.AbstractButton.IconOnly
                enabled: full.controller.canRefresh
                onClicked: full.controller.refreshAll()

                QQC2.ToolTip { text: refreshButton.text }

                PlasmaComponents.BusyIndicator {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    running: full.controller.loading
                    visible: running
                }
            }

            PlasmaComponents.ToolButton {
                id: configureButton

                Layout.minimumWidth: 40
                Layout.minimumHeight: 40
                icon.name: "configure"
                icon.width: Kirigami.Units.iconSizes.smallMedium
                icon.height: Kirigami.Units.iconSizes.smallMedium
                text: i18n("Configure")
                display: PlasmaComponents.AbstractButton.IconOnly
                onClicked: full.controller.openConfiguration()

                QQC2.ToolTip { text: configureButton.text }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: full.controller.errorMessage.length > 0
            // Older data stays on screen, so a failed refresh is only a warning.
            type: full.controller.hasData ? Kirigami.MessageType.Warning : Kirigami.MessageType.Error
            text: full.controller.errorMessage
            actions: Kirigami.Action {
                icon.name: "view-refresh"
                text: i18n("Retry")
                enabled: full.controller.canRefresh
                onTriggered: full.controller.refreshAll()
            }
        }

        Rectangle {
            readonly property color accent: full.controller.selectedColor

            Layout.fillWidth: true
            visible: full.controller.isAlert(full.controller.selectedStatus)
            implicitHeight: statusDetailLabel.implicitHeight + Kirigami.Units.largeSpacing
            radius: Kirigami.Units.cornerRadius
            color: Qt.alpha(accent, 0.10)
            border.width: 1
            border.color: Qt.alpha(accent, 0.34)

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: parent.accent
            }

            PlasmaComponents.Label {
                id: statusDetailLabel

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Kirigami.Units.largeSpacing * 2 + 8
                anchors.rightMargin: Kirigami.Units.largeSpacing
                text: full.statusDetail(full.controller.selectedStatus)
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 13
            radius: Kirigami.Units.cornerRadius
            color: full.darkMap ? "#191c20" : "#e5e8ec"
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.14)
            clip: true

            Item {
                id: mapCanvas

                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing

                Image {
                    id: mapImage

                    anchors.fill: parent
                    source: full.darkMap ? "../images/map-base-dark.svg" : "../images/map-base.svg"
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: Math.max(64, Math.ceil(width / 64) * 64)
                    asynchronous: true

                    Accessible.name: i18n("Map of air raid alerts in Ukraine")
                }

                // Covers the painted map so every overlay shares its coordinates.
                Item {
                    id: mapArea

                    x: (mapCanvas.width - mapImage.paintedWidth) / 2
                    y: (mapCanvas.height - mapImage.paintedHeight) / 2
                    width: mapImage.paintedWidth
                    height: mapImage.paintedHeight

                    Repeater {
                        model: full.controller.activeMapRegions()

                        delegate: Image {
                            id: regionFill

                            required property var modelData
                            readonly property bool alert: modelData.status === "A"
                            readonly property bool selected: full.controller.selectedOblastUid === modelData.region.uid

                            anchors.fill: parent
                            z: 1
                            source: "../images/regions/" + modelData.region.asset + ".svg"
                            sourceSize.width: mapImage.sourceSize.width
                            asynchronous: true
                            opacity: alert ? 0.85 : selected ? 0.07 : 0

                            // The mask is white; alerts tint it with their level color.
                            layer.enabled: alert
                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: full.controller.levelColor(regionFill.modelData.level)
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: Kirigami.Units.shortDuration }
                            }
                        }
                    }

                    Repeater {
                        model: full.controller.geometryLayers()

                        delegate: Item {
                            id: exactArea

                            required property var modelData

                            anchors.fill: parent
                            z: 2

                            Image {
                                id: exactAreaMask

                                anchors.fill: parent
                                source: exactArea.modelData.url
                                sourceSize.width: mapImage.sourceSize.width
                                asynchronous: true
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: exactAreaMask
                                colorization: 1
                                colorizationColor: full.controller.levelColor(exactArea.modelData.alertLevel)
                                opacity: exactAreaMask.status === Image.Ready ? 0.90 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                                }
                            }
                        }
                    }

                    Image {
                        anchors.fill: parent
                        z: 3
                        source: full.darkMap ? "../images/map-lines-dark.svg" : "../images/map-lines.svg"
                        sourceSize.width: mapImage.sourceSize.width
                        asynchronous: true
                    }

                    Repeater {
                        model: LocationData.regions

                        delegate: Item {
                            id: regionLabel

                            required property int index
                            required property var modelData
                            readonly property string status: full.controller.oblastStatuses[index] || "?"
                            readonly property bool selected: full.controller.selectedOblastUid === modelData.uid
                            readonly property bool inspected: full.inspectedUid === modelData.uid
                            readonly property bool labelShown: {
                                switch (full.controller.mapLabelBehavior) {
                                case "always":
                                    return true;
                                case "hover":
                                    return labelMouse.containsMouse || activeFocus;
                                default:
                                    return labelMouse.containsMouse || activeFocus || selected || inspected
                                        || full.controller.isAlert(status);
                                }
                            }
                            readonly property string tooltip: full.controller.regionTooltip(modelData.uid,
                                i18n(modelData.label), status)

                            // Whole-pixel positions keep natively rendered text sharp.
                            x: Math.round(mapArea.x + mapArea.width * modelData.x - width / 2) - mapArea.x
                            y: Math.round(mapArea.y + mapArea.height * modelData.y - height / 2) - mapArea.y
                            width: Math.max(48, Math.min(130, Math.ceil(mapLabelText.implicitWidth) + 12))
                            height: 40
                            z: 4
                            activeFocusOnTab: true
                            opacity: labelShown ? 1 : 0

                            Accessible.name: tooltip
                            Accessible.role: Accessible.Button

                            Behavior on opacity {
                                NumberAnimation { duration: Kirigami.Units.shortDuration }
                            }

                            // Blurred copy behind the text: a soft halo that keeps labels
                            // readable over borders and fills. Only the halo is blurred.
                            Text {
                                x: mapLabelText.x
                                y: mapLabelText.y
                                width: mapLabelText.width
                                height: mapLabelText.height
                                text: mapLabelText.text
                                font: mapLabelText.font
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: full.labelHaloColor
                                style: Text.Outline
                                styleColor: full.labelHaloColor

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: full.labelHaloColor
                                    shadowBlur: 0.45
                                    blurMax: 6
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 0
                                }
                            }

                            Text {
                                id: mapLabelText

                                x: Math.round((parent.width - width) / 2)
                                y: Math.round((parent.height - height) / 2)
                                width: Math.min(Math.ceil(implicitWidth), parent.width - 6)
                                text: full.controller.mapLabel(regionLabel.modelData)
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: full.darkMap ? "#ffffff" : "#1f2429"
                                renderType: Text.NativeRendering
                                font.family: Kirigami.Theme.defaultFont.family
                                font.pixelSize: Math.round(Math.max(11, Math.min(13, mapArea.width / 38)))
                                font.weight: Font.DemiBold
                                font.underline: regionLabel.selected || regionLabel.inspected
                            }

                            MouseArea {
                                id: labelMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: full.toggleInspected(regionLabel.modelData.uid)
                            }

                            QQC2.ToolTip {
                                visible: labelMouse.containsMouse
                                text: regionLabel.tooltip
                                delay: Kirigami.Units.toolTipDelay
                            }

                            Keys.onSpacePressed: full.toggleInspected(modelData.uid)
                            Keys.onReturnPressed: full.toggleInspected(modelData.uid)
                            Keys.onEscapePressed: event => {
                                event.accepted = full.inspectedUid !== "";
                                full.inspectedUid = "";
                            }
                        }
                    }
                }

                MapBadge {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    visible: full.controller.hasData
                    text: full.controller.activeRegionCount > 0
                        ? i18np("%1 region in alert", "%1 regions in alert", full.controller.activeRegionCount)
                        : i18n("No active alerts")
                    color: full.mapPanelColor
                    textColor: full.mapTextColor
                    font.weight: Font.DemiBold
                }

                MapBadge {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    color: full.mapPanelColor
                    textColor: full.mapMutedTextColor
                    text: full.controller.formattedUpdateTime()
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Kirigami.Units.smallSpacing
                    visible: full.controller.activeRegionCount > 0 && !regionCard.visible
                    width: legend.implicitWidth + Kirigami.Units.largeSpacing
                    height: 24
                    radius: 5
                    color: full.mapPanelColor
                    z: 5

                    Row {
                        id: legend

                        anchors.centerIn: parent
                        spacing: Kirigami.Units.largeSpacing

                        Repeater {
                            model: [
                                { "level": "red", "text": i18n("Red level") },
                                { "level": "yellow", "text": i18n("Yellow level") }
                            ]

                            delegate: Row {
                                required property var modelData

                                spacing: Kirigami.Units.smallSpacing

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: full.controller.levelColor(parent.modelData.level)
                                }

                                PlasmaComponents.Label {
                                    text: parent.modelData.text
                                    color: full.mapMutedTextColor
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                            }
                        }
                    }
                }

                MapBadge {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: Kirigami.Units.smallSpacing
                    height: 24
                    radius: 5
                    color: full.mapPanelColor
                    textColor: full.mapMutedTextColor
                    text: "alerts.in.ua"
                    url: "https://alerts.in.ua"
                }

                Rectangle {
                    id: regionCard

                    readonly property var region: LocationData.regions[LocationData.regionIndex(full.inspectedUid)]
                    readonly property string status: full.controller.oblastStatuses[LocationData.regionIndex(full.inspectedUid)] || "?"
                    readonly property string places: full.controller.affectedSummary(full.inspectedUid)
                    readonly property color accent: full.controller.statusColor(status, full.controller.oblastLevel(full.inspectedUid))

                    visible: region !== undefined
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Kirigami.Units.smallSpacing
                    height: cardContent.implicitHeight + Kirigami.Units.smallSpacing * 2
                    radius: 7
                    color: full.mapPanelColor
                    border.width: 1
                    border.color: Qt.alpha(accent, 0.52)
                    z: 6

                    RowLayout {
                        id: cardContent

                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.bottomMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Rectangle {
                            // Centered on the first text line.
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: (cardTitle.implicitHeight - height) / 2
                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8
                            radius: 4
                            color: regionCard.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            PlasmaComponents.Label {
                                id: cardTitle

                                Layout.fillWidth: true
                                text: regionCard.region ? i18n(regionCard.region.label) : ""
                                color: full.mapTextColor
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: full.controller.statusText(regionCard.status,
                                    full.controller.oblastLevel(full.inspectedUid))
                                color: full.mapMutedTextColor
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                elide: Text.ElideRight
                            }

                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                Layout.topMargin: Kirigami.Units.smallSpacing / 2
                                visible: text.length > 0
                                text: regionCard.status === "P"
                                    ? (regionCard.places || i18n("Specific districts or communities are highlighted"))
                                    : regionCard.status === "A" ? i18n("Alert covers the whole oblast") : ""
                                color: full.mapMutedTextColor
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }

                        PlasmaComponents.ToolButton {
                            id: setLocationButton

                            Layout.alignment: Qt.AlignTop
                            visible: full.controller.effectiveUid !== full.inspectedUid
                            icon.name: "mark-location"
                            text: i18n("Set as location")
                            display: regionCard.width > Kirigami.Units.gridUnit * 24
                                ? PlasmaComponents.AbstractButton.TextBesideIcon
                                : PlasmaComponents.AbstractButton.IconOnly
                            onClicked: {
                                full.controller.selectLocation(full.inspectedUid);
                                full.inspectedUid = "";
                            }

                            QQC2.ToolTip {
                                visible: setLocationButton.display === PlasmaComponents.AbstractButton.IconOnly
                                    && setLocationButton.hovered
                                text: setLocationButton.text
                            }
                        }

                        PlasmaComponents.ToolButton {
                            id: closeCardButton

                            Layout.alignment: Qt.AlignTop
                            icon.name: "window-close"
                            text: i18n("Close")
                            display: PlasmaComponents.AbstractButton.IconOnly
                            onClicked: full.inspectedUid = ""

                            QQC2.ToolTip { text: closeCardButton.text }
                        }
                    }
                }
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: i18n("Data may be delayed. Do not use this widget as your only warning source.")
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
