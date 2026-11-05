import QtQuick 2.6
import Sailfish.Silica 1.0
import QtPositioning 5.2
import QtLocation 5.0
import Nemo.Configuration 1.0
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    // ---- состояние ----
    property bool followUser: true
    property bool hasHome: false
    property real homeLat: 0
    property real homeLon: 0

    // Текущая позиция валидна, только если есть и широта, и долгота
    readonly property bool hasPosition: positionSource.position.latitudeValid
                                        && positionSource.position.longitudeValid
    readonly property var coord: positionSource.position.coordinate

    // Текст предупреждения (пустой — предупреждения нет)
    readonly property string warningText: {
        if (positionSource.sourceError === PositionSource.AccessError
                || positionSource.sourceError === PositionSource.ClosedError) {
            return qsTr("Нет доступа к геолокации. Разрешите приложению определять местоположение.")
        }
        if (positionSource.sourceError !== PositionSource.NoError) {
            return qsTr("Ошибка получения данных о местоположении.")
        }
        if (!positionSource.valid) {
            return qsTr("Источник геолокации недоступен.")
        }
        if (!positionSource.active) {
            return qsTr("Геолокация отключена. Включите её в настройках устройства.")
        }
        if (!hasPosition) {
            return qsTr("Позиция ещё не определена. Подождите или выйдите на открытое место.")
        }
        return ""
    }

    // ---- сохранение домашней позиции ----
    ConfigurationGroup {
        id: settings
        path: "/ru/template/GeoPos/home"
        property bool saved: false
        property double latitude: 0
        property double longitude: 0
    }

    Component.onCompleted: {
        if (settings.saved) {
            homeLat = settings.latitude
            homeLon = settings.longitude
            hasHome = true
        }
    }

    function centerOnUser() {
        if (!hasPosition) return
        followUser = true
        map.center = coord
        if (map.zoomLevel < 15) map.zoomLevel = 15
    }

    function goHome() {
        if (!hasHome) return
        followUser = false
        map.center = QtPositioning.coordinate(homeLat, homeLon)
        if (map.zoomLevel < 15) map.zoomLevel = 15
    }

    function saveHome() {
        if (!hasPosition) return
        homeLat = coord.latitude
        homeLon = coord.longitude
        settings.latitude = homeLat
        settings.longitude = homeLon
        settings.saved = true
        hasHome = true
    }

    // ---- источник позиции ----
    PositionSource {
        id: positionSource
        updateInterval: 1000
        active: true
        preferredPositioningMethods: PositionSource.AllPositioningMethods

        onPositionChanged: {
            if (page.followUser && page.hasPosition) {
                map.center = position.coordinate
            }
        }
    }

    // ---- карта ----
    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        zoomLevel: 14
        center: QtPositioning.coordinate(55.751244, 37.618423) // пока позиция неизвестна

        // Пользователь двигает карту — перестаём следить
        gesture.onPanStarted: page.followUser = false

        // Маркер текущей позиции
        MapQuickItem {
            id: userMarker
            visible: page.hasPosition
            coordinate: page.coord
            anchorPoint.x: Theme.itemSizeExtraSmall / 2
            anchorPoint.y: Theme.itemSizeExtraSmall / 2
            z: 2

            sourceItem: Item {
                width: Theme.itemSizeExtraSmall
                height: width

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    radius: width / 2
                    color: Theme.rgba("#2a7de1", 0.25)
                }
                Rectangle {
                    id: userDot
                    anchors.centerIn: parent
                    width: parent.width / 2
                    height: width
                    radius: width / 2
                    color: "#2a7de1"
                    border.color: "white"
                    border.width: Theme.paddingSmall / 2
                }
            }
        }

        // Маркер дома
        MapQuickItem {
            id: homeMarker
            visible: page.hasHome
            coordinate: QtPositioning.coordinate(page.homeLat, page.homeLon)
            anchorPoint.x: Theme.itemSizeExtraSmall / 2
            anchorPoint.y: Theme.itemSizeExtraSmall
            z: 1

            sourceItem: Item {
                id: homeIcon
                width: Theme.itemSizeExtraSmall
                height: width

                Rectangle {
                    anchors.fill: parent
                    radius: width / 4
                    color: "#d9534f"
                    border.color: "white"
                    border.width: Theme.paddingSmall / 2
                }
                Icon {
                    anchors.centerIn: parent
                    source: "image://theme/icon-m-home"
                    width: parent.width * 0.7
                    height: width
                    color: "white"
                }
            }
        }
    }

    // ---- информационная панель ----
    Rectangle {
        id: infoPanel
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: infoColumn.height + 2 * Theme.paddingMedium
        color: Theme.rgba(Theme.overlayBackgroundColor, 0.85)
        z: 10

        Column {
            id: infoColumn
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.paddingSmall

            Label {
                width: parent.width
                text: qsTr("Моё местоположение")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
            }
            Label {
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                text: page.hasPosition
                      ? qsTr("Широта: %1°").arg(page.coord.latitude.toFixed(6))
                      : qsTr("Широта: —")
            }
            Label {
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                text: page.hasPosition
                      ? qsTr("Долгота: %1°").arg(page.coord.longitude.toFixed(6))
                      : qsTr("Долгота: —")
            }
            Label {
                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                visible: page.hasHome
                text: qsTr("Дом: %1°, %2°")
                      .arg(page.homeLat.toFixed(6)).arg(page.homeLon.toFixed(6))
            }
            Label {
                width: parent.width
                visible: page.warningText !== ""
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                text: "⚠ " + page.warningText
            }
        }
    }

    // ---- кнопки ----
    Column {
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Theme.paddingLarge
        }
        spacing: Theme.paddingMedium
        z: 10

        MapButton {
            iconSource: "image://theme/icon-m-gps"
            enabled: page.hasPosition
            onClicked: page.centerOnUser()
        }
        MapButton {
            iconSource: "image://theme/icon-m-home"
            enabled: page.hasHome
            onClicked: page.goHome()
        }
        MapButton {
            iconSource: "image://theme/icon-m-add"
            enabled: page.hasPosition
            onClicked: {
                page.saveHome()
                notice.show(qsTr("Домашняя позиция сохранена"))
            }
        }
    }

    // ---- краткое уведомление ----
    Rectangle {
        id: notice
        function show(text) { noticeLabel.text = text; opacity = 1; hideTimer.restart() }
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.itemSizeLarge
        }
        width: noticeLabel.width + 2 * Theme.paddingLarge
        height: noticeLabel.height + 2 * Theme.paddingMedium
        radius: Theme.paddingSmall
        color: Theme.rgba(Theme.overlayBackgroundColor, 0.9)
        opacity: 0
        z: 20
        Behavior on opacity { FadeAnimator { } }

        Label {
            id: noticeLabel
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeSmall
        }
        Timer { id: hideTimer; interval: 2000; onTriggered: notice.opacity = 0 }
    }
}

