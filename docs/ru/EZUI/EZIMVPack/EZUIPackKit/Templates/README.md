# Xcode File Templates для IMV

Шаблоны для быстрого создания структуры Pack (Interactor + Mediator + View) в Xcode.

Доступны два шаблона:
- **IMV** — UIKit пак (EZUIPackKit)
- **SUI IMV** — SwiftUI пак (EZSUIPackKit)

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

## UIKit шаблон (IMV)

### Использование

1. В Xcode: **File → New → File...** (или `⌘N`)
2. В разделе шаблонов найдите **EZSDK**
3. Выберите **IMV**
4. Укажите целевые платформы (iPhone, iPad, Mac, или комбинации)
5. Введите имя Pack (например, `Profile`)
6. Нажмите **Create**

### Структура генерируемых файлов

При создании Pack с именем `Profile` и платформой `IPhone`:

```
Profile/
├── Profile.swift        # enum фабрика + View платформы
├── ProfileI.swift       # Interactor (UIViewController)
├── ProfileM.swift       # Mediator
└── ProfileV/
    └── ProfileIOSV.swift   # View для iOS (UIView)
```

Для мультиплатформенных конфигураций (например, `IPhoneIPadMac`) будут созданы View для каждой платформы.

### Что делать после создания

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

## SwiftUI шаблон (SUI IMV)

### Использование

1. В Xcode: **File → New → File...** (или `⌘N`)
2. В разделе шаблонов найдите **EZSDK**
3. Выберите **SUI IMV**
4. Введите имя Pack (например, `Profile`)
5. Нажмите **Create**

### Структура генерируемых файлов

При создании Pack с именем `Profile`:

```
Profile/
├── Profile.swift        # enum фабрика, возвращающая some View
├── ProfileI.swift       # Interactor (обычный класс)
├── ProfileM.swift       # Mediator с ObservableObject ViewModel
└── ProfileV.swift       # View (SwiftUI)
```

### Что делать после создания

1. Откройте `*M.swift` (Mediator) и добавьте:
   - `@Published` свойства в `ViewModel`
   - Методы в `InputIProtocol`

2. Откройте `*I.swift` (Interactor) и:
   - Реализуйте `start()`, `onAppear()`, `onDisappear()`
   - Добавьте бизнес-логику
   - Реализуйте `InputIProtocol`

3. Откройте `*V.swift` (View) и:
   - Постройте UI в `body`
   - Используйте `viewModel` для состояния и `inputI` для действий

---

## См. также

- [Быстрый старт EZUIPackKit](../QuickStart/README.md) — пошаговое создание UIKit Pack
- [Быстрый старт EZSUIPackKit](../../EZSUIPackKit/QuickStart/README.md) — пошаговое создание SwiftUI Pack
