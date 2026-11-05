TARGET = ru.template.GeoPos

CONFIG += \
    auroraapp

PKGCONFIG += \

SOURCES += \
    src/main.cpp \

HEADERS += \

DISTFILES += \
    rpm/ru.template.GeoPos.spec \

AURORAAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += auroraapp_i18n

TRANSLATIONS += \
    translations/ru.template.GeoPos.ts \
    translations/ru.template.GeoPos-ru.ts \

QT += positioning location quick
