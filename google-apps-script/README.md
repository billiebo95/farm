# PriceSync — автообновление прайса из Google Drive

Живая копия скрипта, развёрнутого в Google Apps Script (script.google.com)
на аккаунте владельца прайса. Держится здесь для истории/резервной копии —
сам скрипт живёт и выполняется на стороне Google, это репо на него никак
не влияет во время работы.

## Что делает

- `checkAndSync()` — раз в 10 минут проверяет `Прайс.xlsx` на Google Drive
  (по `modifiedTime`/размеру). При изменении — конвертирует xlsx во
  временную Google Таблицу, читает лист «Город», собирает JSON и кладёт
  в кэш-файл на Диске же.
- `doGet()` — веб-приложение, отдаёт содержимое кэша по HTTP GET. Именно
  этот URL зашит в `PriceSyncService.defaultEndpoint`
  (`app/lib/data/price_sync_service.dart`).

Работает при любом способе изменения прайса — полной перезаливке файла
или правке ячеек прямо в Drive — оба варианта меняют `modifiedTime`.

## Если нужно развернуть заново (например, скрипт случайно удалили)

1. script.google.com → New project.
2. Project Settings → включить «Show appsscript.json manifest file in editor».
3. Вставить содержимое `appsscript.json` и `PriceSync.gs` из этой папки.
4. Запустить функцию `setup` (потребует авторизации — это тот же Google-аккаунт).
5. Deploy → New deployment → Web app → Execute as: Me, Access: Anyone.
6. Обновить `PriceSyncService.defaultEndpoint` новым URL, если он изменился.
