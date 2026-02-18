# Xcode File Template для IMV

Шаблон позволяет быстро создавать структуру Pack (Interactor + Mediator + View) в Xcode.

---

## Установка

1. Перейдите в корень репозитория и скопируйте папку с шаблонами в директорию Xcode:

```bash
# Из корня репозитория SwiftEZSDK:
cp -R "File Templates/EZSDK" ~/Library/Developer/Xcode/Templates/
```

Или создайте директорию, если её нет:

```bash
mkdir -p ~/Library/Developer/Xcode/Templates/
cp -R "File Templates/EZSDK" ~/Library/Developer/Xcode/Templates/
```

2. Перезапустите Xcode

---

## Использование

1. В Xcode: **File → New → File...** (или `⌘N`)
2. В разделе шаблонов найдите **EZSDK**
3. Выберите **IMV**
4. Укажите целевые платформы (iPhone, iPad, Mac, или комбинации)
5. Введите имя Pack (например, `Profile`)
6. Нажмите **Create**

---

## Структура генерируемых файлов

При создании Pack с именем `Profile` и платформой `IPhone` будет создана следующая структура:

```
Profile/
├── Profile.swift        # typealias + View платформы
├── ProfileI.swift       # Interactor
├── ProfileM.swift       # Mediator
└── ProfileV/
    └── ProfileIOSV.swift   # View для iOS
```

Для мультиплатформенных конфигураций (например, `IPhoneIPadMac`) будут созданы View для каждой платформы.

---

## Что делать после создания

1. Откройте `*M.swift` (Mediator) и добавьте:
   - Свойства в `ViewModel`
   - Методы в `InputIProtocol` и `InputVProtocol`

2. Откройте `*I.swift` (Interactor) и:
   - Реализуйте методы жизненного цикла
   - Добавьте бизнес-логику
   - Реализуйте `InputIProtocol`

3. Откройте `*V.swift` (View) и:
   - Создайте UI в методе `create()`
   - Реализуйте `InputVProtocol`

---

## См. также

- [Быстрый старт](../QuickStart/README.md) — пошаговое создание Pack вручную
- [Главная страница модуля](../README.md) — полный список возможностей
