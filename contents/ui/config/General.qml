import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

import "../LocationData.js" as LocationData

KCM.SimpleKCM {
    id: root

    property string cfg_locationUid
    property alias cfg_customLocationUid: customUidField.text
    property alias cfg_customLocationName: customNameField.text
    property alias cfg_notificationsEnabled: notificationsCheck.checked
    property alias cfg_notifyClear: clearCheck.checked
    property alias cfg_alertSound: soundCheck.checked
    property int cfg_refreshInterval
    property string cfg_mapLabelBehavior

    function valueIndex(model, value, fallback) {
        const index = model.findIndex(item => item.value === value);
        return index === -1 ? fallback : index;
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.ComboBox {
            id: locationCombo

            Kirigami.FormData.label: i18n("Location:")
            Layout.fillWidth: true
            model: LocationData.locations.map(location => ({
                uid: location.uid,
                label: i18n(location.label)
            }))
            textRole: "label"
            valueRole: "uid"
            currentIndex: LocationData.locationIndex(root.cfg_locationUid)
            onActivated: root.cfg_locationUid = String(currentValue)
        }

        QQC2.TextField {
            id: customUidField

            Kirigami.FormData.label: i18n("Location UID:")
            Layout.fillWidth: true
            visible: root.cfg_locationUid === "custom"
            enabled: visible
            placeholderText: i18n("Numeric UID from the official location list")
            inputMethodHints: Qt.ImhDigitsOnly
            validator: RegularExpressionValidator { regularExpression: /[0-9]+/ }
        }

        QQC2.TextField {
            id: customNameField

            Kirigami.FormData.label: i18n("Display name:")
            Layout.fillWidth: true
            visible: root.cfg_locationUid === "custom"
            enabled: visible
            placeholderText: i18n("City, community, or district")
        }

        QQC2.Label {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
            visible: root.cfg_locationUid === "custom"
            text: i18n("Find the UID in the official alerts.in.ua location list.")
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://docs.google.com/spreadsheets/d/1XnTOzcPHd1LZUrarR1Fk43FUyl8Ae6a6M7pcwDRjNdA/edit?usp=sharing")
            }
        }

        QQC2.ComboBox {
            id: refreshCombo

            Kirigami.FormData.label: i18n("Refresh every:")
            model: [
                { text: i18n("15 seconds"), value: 15 },
                { text: i18n("30 seconds"), value: 30 },
                { text: i18n("1 minute"), value: 60 },
                { text: i18n("2 minutes"), value: 120 },
                { text: i18n("5 minutes"), value: 300 }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: root.valueIndex(model, root.cfg_refreshInterval, 2)
            onActivated: root.cfg_refreshInterval = Number(currentValue)
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Map labels:")
            Layout.fillWidth: true
            model: [
                { text: i18n("Automatic (regions in alert and your location)"), value: "auto" },
                { text: i18n("Only hovered or focused"), value: "hover" },
                { text: i18n("Always visible"), value: "always" }
            ]
            textRole: "text"
            valueRole: "value"
            currentIndex: root.valueIndex(model, root.cfg_mapLabelBehavior, 0)
            onActivated: root.cfg_mapLabelBehavior = String(currentValue)
        }

        QQC2.CheckBox {
            id: notificationsCheck

            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Notify when an alert starts")
        }

        QQC2.CheckBox {
            id: clearCheck

            text: i18n("Notify when the alert ends")
            enabled: notificationsCheck.checked
        }

        QQC2.CheckBox {
            id: soundCheck

            text: i18n("Play a sound when an alert starts")
            enabled: notificationsCheck.checked
        }
    }
}
