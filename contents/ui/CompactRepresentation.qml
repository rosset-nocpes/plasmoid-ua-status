import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: compact

    required property var controller

    implicitWidth: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 2
    implicitHeight: implicitWidth

    Accessible.name: compact.controller.selectedLocation.label + ": " + compact.controller.statusText(compact.controller.selectedStatus, compact.controller.selectedLevel)
    Accessible.role: Accessible.Button
    activeFocusOnTab: true

    Kirigami.Icon {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        source: "data-warning"
        color: compact.controller.selectedColor
        isMask: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: compact.controller.expanded = !compact.controller.expanded
    }

    Keys.onSpacePressed: compact.controller.expanded = !compact.controller.expanded
    Keys.onReturnPressed: compact.controller.expanded = !compact.controller.expanded
}
