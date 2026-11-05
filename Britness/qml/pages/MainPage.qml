import QtQuick 2.0
import Sailfish.Silica 1.0
import QtSensors 5.0

Page {
    id: mainPage
    objectName: "mainPage"
    allowedOrientations: Orientation.All

    // ---- Состояние ----
    property bool autoMode: true          // автоматический режим
    property real lux: -1                 // последнее показание, -1 = ещё нет
    property bool near: false             // датчик приближения
    property real threshold: 50           // порог освещённости, лк
    property bool manualDark: false       // ручная тёмная схема (резерв / авто выключен)
    property bool manualHide: false       // ручное скрытие данных (резерв / авто выключен)

    readonly property bool lightOk: lightSensor.connectedToBackend
    readonly property bool proxOk: proxSensor.connectedToBackend

    // Тёмная схема: по датчику, если авто включено, датчик есть и показание получено
    readonly property bool dark: (autoMode && lightOk && lux >= 0)
                                 ? (lux < threshold)
                                 : manualDark
    // Скрытие данных: по датчику приближения, иначе вручную
    readonly property bool hidden: (autoMode && proxOk) ? near : manualHide

    readonly property color bgColor: dark ? "#121212" : "#FAFAFA"
    readonly property color fgColor: dark ? "#EEEEEE" : "#212121"

    // ---- Датчики ----
    LightSensor {
        id: lightSensor
        active: true
        onReadingChanged: {
            if (reading)
                mainPage.lux = reading.illuminance
        }
    }

    ProximitySensor {
        id: proxSensor
        active: true
        onReadingChanged: {
            if (reading)
                mainPage.near = reading.near
        }
    }

    // ---- Фон ----
    Rectangle {
        anchors.fill: parent
        color: mainPage.bgColor
        Behavior on color { ColorAnimation { duration: 250 } }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: mainPage.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Адаптивный экран")
            }

            // --- Сообщения о недоступности датчиков ---
            Label {
                visible: !mainPage.lightOk
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: "#E53935"
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Датчик освещённости недоступен. Тема переключается вручную.")
            }
            Label {
                visible: !mainPage.proxOk
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: "#E53935"
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Датчик приближения недоступен. Данные скрываются вручную.")
            }

            // --- Показания ---
            Label {
                x: Theme.horizontalPageMargin
                color: mainPage.fgColor
                font.pixelSize: Theme.fontSizeLarge
                text: !mainPage.lightOk ? qsTr("Освещённость: нет данных")
                    : mainPage.lux < 0  ? qsTr("Освещённость: ожидание...")
                    : qsTr("Освещённость: %1 лк").arg(Math.round(mainPage.lux))
            }
            Label {
                x: Theme.horizontalPageMargin
                color: mainPage.fgColor
                font.pixelSize: Theme.fontSizeMedium
                text: qsTr("Схема: ") + (mainPage.dark ? qsTr("тёмная") : qsTr("светлая"))
            }
            Label {
                x: Theme.horizontalPageMargin
                color: mainPage.fgColor
                font.pixelSize: Theme.fontSizeMedium
                text: !mainPage.proxOk ? qsTr("Приближение: нет данных")
                    : qsTr("Приближение: ") + (mainPage.near ? qsTr("объект рядом") : qsTr("свободно"))
            }

            // --- Настройки ---
            TextSwitch {
                id: autoSwitch
                text: qsTr("Автоматический режим")
                checked: mainPage.autoMode
                onCheckedChanged: mainPage.autoMode = checked
            }

            Slider {
                width: parent.width
                minimumValue: 0
                maximumValue: 1000
                stepSize: 10
                value: mainPage.threshold
                valueText: Math.round(value) + qsTr(" лк")
                label: qsTr("Порог освещённости (ниже порога - тёмная схема)")
                onValueChanged: mainPage.threshold = value
            }

            // Ручное управление: доступно, если авто выключено или датчика нет
            TextSwitch {
                visible: !mainPage.autoMode || !mainPage.lightOk
                text: qsTr("Тёмная схема вручную")
                checked: mainPage.manualDark
                onCheckedChanged: mainPage.manualDark = checked
            }
            TextSwitch {
                visible: !mainPage.autoMode || !mainPage.proxOk
                text: qsTr("Скрыть данные вручную")
                checked: mainPage.manualHide
                onCheckedChanged: mainPage.manualHide = checked
            }

            // --- Демонстрационные конфиденциальные данные ---
            Rectangle {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: secretColumn.height + 2 * Theme.paddingLarge
                radius: Theme.paddingMedium
                color: "transparent"
                border.width: 2
                border.color: mainPage.fgColor
                opacity: mainPage.hidden ? 0.5 : 1.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Column {
                    id: secretColumn
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.paddingLarge
                    }
                    spacing: Theme.paddingSmall

                    Label {
                        color: mainPage.fgColor
                        text: qsTr("Демо-данные")
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Label {
                        color: mainPage.fgColor
                        font.pixelSize: Theme.fontSizeMedium
                        text: mainPage.hidden ? qsTr("Карта: **** **** **** ****")
                                              : qsTr("Карта: 4276 1234 5678 9010")
                    }
                    Label {
                        color: mainPage.fgColor
                        font.pixelSize: Theme.fontSizeMedium
                        text: mainPage.hidden ? qsTr("Баланс: ******")
                                              : qsTr("Баланс: 125 430 ₽")
                    }
                    Label {
                        visible: mainPage.hidden
                        color: mainPage.fgColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: qsTr("Данные скрыты")
                    }
                }
            }
        }
    }
}

