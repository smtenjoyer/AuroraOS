import QtQuick 2.6
import Sailfish.Silica 1.0
import QtWebSockets 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property string serverUrl: "wss://echo.websocket.org"
    property int maxMessageLength: 500
    property int maxReconnectAttempts: 5
    property int reconnectDelay: 3000
    property int reconnectAttempts: 0
    property bool userDisconnected: true   // не переподключаться, если отключились сами
    property var pendingMessages: []

    readonly property bool isOpen: socket.status === WebSocket.Open

    function timeNow() { return Qt.formatTime(new Date(), "hh:mm:ss") }

    function addMessage(author, text) {
        chatModel.append({ author: author, text: text, time: timeNow(), isSystem: false })
        chatView.positionViewAtEnd()
    }

    function addSystem(text) {
        chatModel.append({ author: "", text: text, time: timeNow(), isSystem: true })
        chatView.positionViewAtEnd()
    }

    function connectToServer() {
        userDisconnected = false
        reconnectAttempts = 0
        socket.active = false
        socket.url = urlField.text.trim()
        socket.active = true
    }

    function disconnectFromServer() {
        userDisconnected = true
        reconnectTimer.stop()
        socket.active = false
    }

    function attemptReconnect() {
        if (userDisconnected) return
        if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++
            addSystem(qsTr("Переподключение %1/%2…").arg(reconnectAttempts).arg(maxReconnectAttempts))
            reconnectTimer.start()
        } else {
            addSystem(qsTr("Не удалось переподключиться. Попытки исчерпаны."))
        }
    }

    function send() {
        var t = messageInput.text.trim()
        if (t === "" || !isOpen) return
        socket.sendTextMessage(t)
        addMessage(qsTr("Вы"), t)
        messageInput.text = ""
    }

    ListModel { id: chatModel }

    WebSocket {
        id: socket
        active: false

        onStatusChanged: {
            if (status === WebSocket.Open) {
                reconnectAttempts = 0
                addSystem(qsTr("Соединение установлено"))
            } else if (status === WebSocket.Closed) {
                addSystem(qsTr("Соединение закрыто"))
                attemptReconnect()
            } else if (status === WebSocket.Error) {
                addSystem(qsTr("Ошибка: %1").arg(errorString))
                attemptReconnect()
            }
        }

        onTextMessageReceived: addMessage(qsTr("Сервер"), message)
    }

    Timer {
        id: reconnectTimer
        interval: page.reconnectDelay
        onTriggered: {
            socket.active = false
            socket.active = true
        }
    }

    RemorsePopup { id: remorse }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: height

        PullDownMenu {
            MenuItem {
                text: qsTr("Очистить историю")
                onClicked: remorse.execute(qsTr("Очистка истории"), function() { chatModel.clear() })
            }
        }

        Column {
            id: top
            width: parent.width

            PageHeader { title: qsTr("WebSocket-чат") }

            TextField {
                id: urlField
                width: parent.width
                label: qsTr("Адрес сервера (ws:// или wss://)")
                placeholderText: label
                text: page.serverUrl
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText
                enabled: socket.status === WebSocket.Closed || socket.status === WebSocket.Error
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            Row {
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingMedium
                height: Theme.itemSizeSmall

                Rectangle {
                    id: dot
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.paddingLarge
                    height: width
                    radius: width / 2
                    color: {
                        switch (socket.status) {
                        case WebSocket.Open: return "#4caf50"
                        case WebSocket.Connecting:
                        case WebSocket.Closing: return "#ffc107"
                        case WebSocket.Error: return "#f44336"
                        default: return "gray"
                        }
                    }
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.secondaryHighlightColor
                    text: {
                        switch (socket.status) {
                        case WebSocket.Connecting: return qsTr("Подключение…")
                        case WebSocket.Open: return qsTr("Подключено")
                        case WebSocket.Closing: return qsTr("Отключение…")
                        case WebSocket.Closed: return qsTr("Отключено")
                        case WebSocket.Error: return qsTr("Ошибка")
                        default: return qsTr("Неизвестно")
                        }
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (page.isOpen || socket.status === WebSocket.Connecting)
                      ? qsTr("Отключиться") : qsTr("Подключиться")
                enabled: socket.status !== WebSocket.Closing
                onClicked: {
                    if (page.isOpen || socket.status === WebSocket.Connecting) {
                        page.disconnectFromServer()
                    } else {
                        page.connectToServer()
                    }
                }
            }
        }

        SilicaListView {
            id: chatView
            anchors {
                top: top.bottom
                topMargin: Theme.paddingMedium
                left: parent.left
                right: parent.right
                bottom: inputRow.top
            }
            clip: true
            model: chatModel

            delegate: Item {
                width: chatView.width
                height: msgColumn.height + Theme.paddingMedium

                Column {
                    id: msgColumn
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    spacing: 0

                    Row {
                        spacing: Theme.paddingMedium
                        visible: !model.isSystem
                        Label {
                            text: model.author
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.bold: true
                            color: Theme.highlightColor
                        }
                        Label {
                            text: model.time
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                    Label {
                        width: parent.width
                        text: model.isSystem ? model.time + "  " + model.text : model.text
                        wrapMode: Text.Wrap
                        font.pixelSize: model.isSystem ? Theme.fontSizeExtraSmall : Theme.fontSizeSmall
                        font.italic: model.isSystem
                        color: model.isSystem ? Theme.secondaryColor : Theme.primaryColor
                    }
                }
            }

            VerticalScrollDecorator { }
        }

        Row {
            id: inputRow
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            TextField {
                id: messageInput
                width: parent.width - sendButton.width
                placeholderText: qsTr("Сообщение")
                label: text.length + "/" + page.maxMessageLength
                maximumLength: page.maxMessageLength
                enabled: page.isOpen
                EnterKey.enabled: text.trim() !== ""
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.send()
            }

            IconButton {
                id: sendButton
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-message"
                enabled: page.isOpen && messageInput.text.trim() !== ""
                onClicked: page.send()
            }
        }
    }
}

