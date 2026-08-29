# Notebook App — релизы

Каталог для раздачи готовых сборок приложения конечным пользователям.
Исходный код и разработка — в отдельном репозитории `notebook-app`.

```
apk/      готовые сборки для Android (.apk)
deb/      готовые сборки для Linux (.deb)
win/      сборка и дистрибутив для Windows
  ├── source/           исходники Flutter-проекта с папкой windows/
  ├── build.bat         сборка .exe «в один клик» (запускать на Windows)
  └── BUILD_WINDOWS.md   требования и пошаговая инструкция
history/  список изменений по версиям (Release_vX.Y.Z.md)
INSTALL.md   инструкция по установке для конечного пользователя
```

## Установка

См. [`INSTALL.md`](INSTALL.md) — Android, Linux, Windows.

## Сборка Windows-версии

На машине с Windows: см. [`win/BUILD_WINDOWS.md`](win/BUILD_WINDOWS.md).
Кратко — установить Flutter 3.47.x + Visual Studio 2022 с компонентом
«Desktop development with C++», затем запустить `win/build.bat`.

## Версии

Актуальные номера версий — по самому свежему файлу в `history/`
и по именам файлов в `apk/`, `deb/`, `win/`.
