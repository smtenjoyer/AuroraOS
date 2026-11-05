import QtQuick 2.6
import Sailfish.Silica 1.0

// Круглая кнопка поверх карты
MouseArea {
    id: btn
    property alias iconSource: btnIcon.source

    width: Theme.itemSizeMedium
    height: width
    opacity: enabled ? 1.0 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: btn.pressed ? Theme.highlightBackgroundColor
                           : Theme.rgba(Theme.overlayBackgroundColor, 0.9)
        border.color: Theme.highlightColor
        border.width: 1
    }
    Icon {
        id: btnIcon
        anchors.centerIn: parent
    }
}
