# Сборка Notebook App под Windows (.exe)

Здесь лежит всё необходимое, чтобы собрать Windows-версию приложения на любом
компьютере с Windows. Кросс-сборка с Linux/macOS невозможна — Flutter собирает
Windows-приложение только на Windows.

```
win/
├── source/            ← исходный код Flutter-проекта (уже включает папку windows/)
├── build.bat          ← сборка «в один клик»
└── BUILD_WINDOWS.md   ← этот файл
```

Результат сборки — **портативное приложение** (папка с `notebook_app.exe` и
сопутствующими DLL/ресурсами) и `.zip`-архив рядом с `build.bat`.

---

## 1. Требования

| Компонент | Версия / примечание |
|---|---|
| Windows | 10 или 11, 64-бит |
| Flutter SDK | **3.47.x** (та же линейка, что у проекта) — <https://docs.flutter.dev/get-started/install/windows> |
| Visual Studio 2022 | с рабочей нагрузкой **«Разработка классических приложений на C++» / “Desktop development with C++”**. Подойдёт и бесплатный **Build Tools for Visual Studio 2022** с тем же компонентом C++. |
| Git | опционально (только чтобы клонировать этот репозиторий) |

> Только «Desktop development with C++» — Android Studio, VS Code и т.п. для
> сборки Windows-версии не нужны.

### Проверка окружения

```bat
flutter doctor
```

В выводе должны быть отмечены галочкой строки:

```
[√] Flutter (Channel stable, 3.47.x, ...)
[√] Visual Studio - develop Windows apps (Visual Studio Community 2022 ...)
```

Если Visual Studio отмечена крестиком — доустановите компонент
«Desktop development with C++» через Visual Studio Installer.

---

## 2. Сборка «в один клик»

1. Откройте каталог `win\` (этот).
2. Дважды кликните `build.bat` (или запустите его из `cmd` / PowerShell).

Скрипт сам выполнит `flutter config --enable-windows-desktop`,
`flutter pub get`, `flutter build windows --release`, соберёт результат в папку
`NotebookApp-<версия>-windows-x64\` и упакует её в
`NotebookApp-<версия>-windows-x64.zip` рядом с `build.bat`.

---

## 3. Сборка вручную

```bat
cd source
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
```

Готовое приложение появится в:

```
source\build\windows\x64\runner\Release\
```

Эта папка целиком и есть приложение:

```
Release\
├── notebook_app.exe        ← запускаемый файл
├── flutter_windows.dll
├── *.dll                    ← плагины (secure storage, local_auth, url_launcher …)
└── data\                    ← ресурсы Flutter (assets, icudtl.dat …)
```

**Распространять нужно всю папку** (или её `.zip`), а не только `.exe` —
без DLL и `data\` приложение не запустится.

---

## 4. Куда положить результат

Готовый `NotebookApp-<версия>-windows-x64.zip` кладётся в этот же каталог
`win/` — это и есть дистрибутив Windows-версии для конечных пользователей
(см. `../INSTALL.md`, раздел «Windows»).

---

## 5. Частые проблемы

| Симптом | Решение |
|---|---|
| `flutter` не распознаётся | Flutter не в `PATH`. Добавьте `...\flutter\bin` в переменную среды `Path`, перезапустите терминал. |
| `Unable to find suitable Visual Studio toolchain` | Не установлен компонент C++. Visual Studio Installer → Изменить → «Desktop development with C++». |
| `CMake Error ... MSVC` | То же — нет C++ toolchain, либо не перезапущен терминал после установки VS. |
| Антивирус удаляет `.exe` | Свежесобранный неподписанный `.exe` иногда попадает под эвристику. Добавьте папку сборки в исключения. |
| Приложение запускается, но «нет сети» | По умолчанию клиент ходит на `https://nb.test-zc.ru/api`. Адрес сервера можно сменить в приложении: **Настройки**. |

---

## 6. Обновление исходников

`source/` — снимок клиента из основного репозитория `notebook-app` (ветка `dev`)
на момент версии из `source/pubspec.yaml`. Чтобы собрать более новую версию —
замените содержимое `source/` актуальным каталогом `client/` из основного
репозитория (можно без папок `android/`, `linux/`, `build/`, `.dart_tool/`) и
повторите сборку.
