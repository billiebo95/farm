/**
 * PriceSync — держит прайс из Google Drive (файл "Прайс.xlsx") синхронизированным
 * и отдаёт его как JSON по HTTP для мобильного приложения apteka_opt.
 *
 * Как это работает:
 *  1. checkAndSync() запускается по расписанию (см. setup()) каждые 10 минут.
 *     Смотрит modifiedTime и размер файла "Прайс.xlsx" в Google Drive.
 *     Если файл изменился (заменили целиком ИЛИ отредактировали ячейки
 *     через встроенный просмотрщик Office) — конвертирует его во временную
 *     Google Таблицу (через Drive REST API), читает лист "Город", собирает
 *     JSON и кладёт его в кэш-файл на Диске.
 *  2. doGet() — веб-приложение, отдаёт содержимое кэш-файла по ссылке.
 *     Приложение просто делает HTTP GET на эту ссылку.
 *  3. doPost() — принимает оформленный в приложении заказ (JSON) и дописывает
 *     его строкой в отдельную Google Таблицу "Заказы (Аптека Опт)" на Диске
 *     (создаётся автоматически при первом заказе). Файл "Прайс.xlsx" при
 *     этом не трогается. То же doPost, по полю `type` в теле запроса,
 *     принимает операции по долгу клиента ("debt" — в свою Google Таблицу
 *     "Долги (Аптека Опт)") и отправку СМС ("sms" — через smsc.ru, см.
 *     SMSC_LOGIN/SMSC_PASSWORD ниже). doGet() с ?type=debts отдаёт текущий
 *     журнал долгов, сгруппированный по клиенту, — так все устройства
 *     администратора видят одни и те же остатки.
 *
 * НАСТРОЙКА (один раз, БЕЗ "Advanced Services"):
 *  1. script.google.com -> New project.
 *  2. Слева, в списке файлов, нажми на шестерёнку "Project Settings" и
 *     поставь галочку "Show 'appsscript.json' manifest file in editor".
 *  3. Вернись в редактор (иконка "<>" Editor). В списке файлов появится
 *     appsscript.json — открой его и замени содержимое на файл
 *     appsscript.json из этого же комплекта.
 *  4. Открой Code.gs, удали заглушку, вставь этот код.
 *  5. Проверь SOURCE_FILE_ID ниже — сейчас он указывает на "Прайс.xlsx".
 *  6. Наверху в списке функций выбери "setup" -> Run.
 *     Google спросит разрешения — это твой аккаунт, скрипт трогает
 *     только твой Drive, разреши (может быть экран "Google не проверил
 *     это приложение" — жми "Дополнительно" -> "Перейти на PriceSync").
 *  7. Deploy -> New deployment -> тип "Web app".
 *     Execute as: Me. Who has access: Anyone.
 *  8. Скопируй итоговый URL (заканчивается на /exec) и пришли его мне.
 */

// ID файла "Прайс.xlsx" в папке "Прайсы" на Google Drive.
const SOURCE_FILE_ID = '14pBOP4Y9kkULQJMJx0d1TBUFcTM4vL4b';

// Имя листа с товарами внутри файла.
const SHEET_NAME = 'Город';

// Как часто проверять файл на изменения (минуты).
const SYNC_INTERVAL_MINUTES = 10;

// Имя кэш-файла с готовым JSON (создаётся автоматически в корне Drive).
const CACHE_FILE_NAME = 'price_cache.json';

// Имя Google Таблицы с журналом заказов (создаётся автоматически).
const ORDERS_SHEET_NAME = 'Заказы (Аптека Опт)';

const PROP_CACHE_FILE_ID = 'cacheFileId';
const PROP_LAST_MODIFIED = 'lastModifiedIso';
const PROP_LAST_SIZE = 'lastSize';
const PROP_ORDERS_SHEET_ID = 'ordersSheetId';

const ORDERS_HEADER = [
  'Дата',
  'Номер заказа',
  'Клиент',
  'Код доставки',
  'Регион',
  'Комментарий',
  'Позиций',
  'Сумма',
  'Товары (JSON)',
];

// Имя Google Таблицы с журналом долгов (создаётся автоматически).
const DEBTS_SHEET_NAME = 'Долги (Аптека Опт)';
const PROP_DEBTS_SHEET_ID = 'debtsSheetId';

const DEBTS_HEADER = [
  'Дата',
  'Код доставки',
  'Клиент',
  'Операция',
  'Сумма',
  'Остаток после операции',
  'Комментарий',
];

// Шлюз СМС (smsc.ru, send.php) — впиши логин/пароль своего аккаунта, чтобы
// заработала отправка истории долга клиенту. Пока не заполнено, doPost с
// type "sms" отвечает ok:false с понятной причиной — ничего не ломает.
const SMSC_LOGIN = '';
const SMSC_PASSWORD = '';

/** Разовая настройка: создаёт триггер по расписанию и делает первую синхронизацию. */
function setup() {
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (t.getHandlerFunction() === 'checkAndSync') {
      ScriptApp.deleteTrigger(t);
    }
  });

  ScriptApp.newTrigger('checkAndSync')
    .timeBased()
    .everyMinutes(SYNC_INTERVAL_MINUTES)
    .create();

  checkAndSync();

  Logger.log('Готово. Триггер создан, первая синхронизация выполнена.');
}

/** Вызывается по расписанию. Проверяет изменения и пересобирает кэш при необходимости. */
function checkAndSync() {
  const file = DriveApp.getFileById(SOURCE_FILE_ID);
  const modifiedIso = file.getLastUpdated().toISOString();
  const size = file.getSize();

  const props = PropertiesService.getScriptProperties();
  const lastModified = props.getProperty(PROP_LAST_MODIFIED);
  const lastSize = props.getProperty(PROP_LAST_SIZE);

  const changed = modifiedIso !== lastModified || String(size) !== lastSize;
  if (!changed) {
    return;
  }

  const items = convertAndReadPriceList_(SOURCE_FILE_ID, SHEET_NAME);

  const payload = {
    updatedAt: new Date().toISOString(),
    sourceModifiedAt: modifiedIso,
    count: items.length,
    items: items,
  };

  writeCache_(JSON.stringify(payload));

  props.setProperty(PROP_LAST_MODIFIED, modifiedIso);
  props.setProperty(PROP_LAST_SIZE, String(size));

  Logger.log('Синхронизировано: ' + items.length + ' товаров.');
}

/**
 * Конвертирует xlsx во временную Google Таблицу (через Drive REST API v3,
 * без Advanced Services), читает лист SHEET_NAME, превращает строки
 * в массив объектов и удаляет временную копию.
 */
function convertAndReadPriceList_(fileId, sheetName) {
  const tmpId = driveCopyConvertToSheet_(fileId);

  try {
    const ss = SpreadsheetApp.openById(tmpId);
    const sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      throw new Error('Лист "' + sheetName + '" не найден в файле.');
    }

    const values = sheet.getDataRange().getValues();
    // Наименование, Производитель, Срок Годности, Цена, Остаток,
    // Мин\заказ, Штрих-код, Код товара, Маркировка.
    const rows = values.slice(1);

    const items = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const name = (r[0] || '').toString().trim();
      if (!name) continue;

      items.push({
        id: (r[7] || '').toString().trim(),
        name: name,
        producer: (r[1] || '').toString().trim(),
        period: formatDate_(r[2]),
        basePrice: toNumber_(r[3]),
        stock: Math.trunc(toNumber_(r[4])),
        minOrder: Math.trunc(toNumber_(r[5])) || 1,
        barcode: (r[6] || '').toString().trim(),
        marking: (r[8] || '').toString().trim(),
      });
    }

    return items;
  } finally {
    driveDeleteFile_(tmpId); // не засоряем Drive временными копиями
  }
}

/** Копирует файл в Google Таблицу через чистый REST-вызов (без Advanced Services). */
function driveCopyConvertToSheet_(fileId) {
  const token = ScriptApp.getOAuthToken();
  const url = 'https://www.googleapis.com/drive/v3/files/' + fileId + '/copy';
  const resp = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    headers: { Authorization: 'Bearer ' + token },
    payload: JSON.stringify({
      name: 'tmp_price_conversion_' + new Date().getTime(),
      mimeType: 'application/vnd.google-apps.spreadsheet',
    }),
    muteHttpExceptions: true,
  });

  const code = resp.getResponseCode();
  if (code !== 200) {
    throw new Error('Drive copy failed (' + code + '): ' + resp.getContentText());
  }
  return JSON.parse(resp.getContentText()).id;
}

function driveDeleteFile_(fileId) {
  const token = ScriptApp.getOAuthToken();
  const url = 'https://www.googleapis.com/drive/v3/files/' + fileId;
  UrlFetchApp.fetch(url, {
    method: 'delete',
    headers: { Authorization: 'Bearer ' + token },
    muteHttpExceptions: true,
  });
}

function toNumber_(v) {
  if (typeof v === 'number') return v;
  const n = parseFloat(String(v).replace(',', '.'));
  return isNaN(n) ? 0 : n;
}

function formatDate_(v) {
  if (v instanceof Date) {
    return Utilities.formatDate(v, Session.getScriptTimeZone(), 'dd.MM.yyyy');
  }
  return (v || '').toString().trim();
}

/** Создаёт (при первом запуске) или перезаписывает кэш-файл с готовым JSON. */
function writeCache_(jsonString) {
  const props = PropertiesService.getScriptProperties();
  const cachedId = props.getProperty(PROP_CACHE_FILE_ID);

  if (cachedId) {
    try {
      const file = DriveApp.getFileById(cachedId);
      file.setContent(jsonString);
      return;
    } catch (e) {
      // Файл кто-то удалил вручную — создадим заново.
    }
  }

  const file = DriveApp.createFile(CACHE_FILE_NAME, jsonString, MimeType.PLAIN_TEXT);
  props.setProperty(PROP_CACHE_FILE_ID, file.getId());
}

/**
 * Веб-приложение: принимает POST от приложения. Тип запроса определяется
 * полем `type` в теле:
 *  - отсутствует или "order" — оформленный заказ (как раньше, без
 *    изменений). Ожидаемое тело: { number, date, client, code, region,
 *    comment, total, lines: [ { code, name, price, quantity, sum }, ... ] }
 *  - "debt" — операция по долгу клиента (начисление или оплата). Ожидаемое
 *    тело: { code, client, kind: "charge"|"payment", amount, balanceAfter,
 *    date, comment }
 *  - "sms" — отправить клиенту СМС (используется для истории долга).
 *    Ожидаемое тело: { phone, text }
 */
function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const type = body.type || 'order';

    if (type === 'debt') {
      return jsonOutput_(appendDebtOperation_(body));
    }
    if (type === 'sms') {
      return jsonOutput_(sendSms_(body.phone, body.text));
    }

    const sheet = getOrCreateOrdersSheet_();
    sheet.appendRow([
      body.date || new Date().toISOString(),
      body.number || '',
      body.client || '',
      body.code || '',
      body.region || '',
      body.comment || '',
      Array.isArray(body.lines) ? body.lines.length : 0,
      toNumber_(body.total),
      JSON.stringify(body.lines || []),
    ]);

    return jsonOutput_({ ok: true });
  } catch (err) {
    return jsonOutput_({ ok: false, error: String(err) });
  }
}

function jsonOutput_(payload) {
  return ContentService.createTextOutput(JSON.stringify(payload)).setMimeType(ContentService.MimeType.JSON);
}

/** Дописывает строку операции по долгу (начисление/оплата) в журнал долгов. */
function appendDebtOperation_(body) {
  const sheet = getOrCreateDebtsSheet_();
  const kind = body.kind === 'payment' ? 'Оплата' : 'Долг';

  sheet.appendRow([
    body.date || new Date().toISOString(),
    body.code || '',
    body.client || '',
    kind,
    toNumber_(body.amount),
    toNumber_(body.balanceAfter),
    body.comment || '',
  ]);

  return { ok: true };
}

/** Находит (или создаёт при первой операции) Google Таблицу — журнал долгов. */
function getOrCreateDebtsSheet_() {
  const props = PropertiesService.getScriptProperties();
  const savedId = props.getProperty(PROP_DEBTS_SHEET_ID);

  if (savedId) {
    try {
      return SpreadsheetApp.openById(savedId).getSheets()[0];
    } catch (e) {
      // Таблицу кто-то удалил вручную — создадим заново.
    }
  }

  const ss = SpreadsheetApp.create(DEBTS_SHEET_NAME);
  const sheet = ss.getSheets()[0];
  sheet.appendRow(DEBTS_HEADER);
  sheet.setFrozenRows(1);

  props.setProperty(PROP_DEBTS_SHEET_ID, ss.getId());
  return sheet;
}

/**
 * Читает весь журнал долгов и группирует строки по коду доставки — у
 * каждого клиента получается его история операций по порядку записи и
 * текущий остаток (Остаток последней операции). Отдаётся по GET
 * ?type=debts, чтобы все устройства администратора видели одни и те же
 * долги, а не только то, что сами туда записали.
 */
function buildDebtLedger_() {
  const props = PropertiesService.getScriptProperties();
  const savedId = props.getProperty(PROP_DEBTS_SHEET_ID);
  if (!savedId) return [];

  let sheet;
  try {
    sheet = SpreadsheetApp.openById(savedId).getSheets()[0];
  } catch (e) {
    return [];
  }

  const values = sheet.getDataRange().getValues();
  const rows = values.slice(1); // без заголовка

  const byCode = {};
  const order = [];
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const code = (r[1] || '').toString().trim();
    if (!code) continue;

    if (!byCode[code]) {
      byCode[code] = { code: code, operations: [] };
      order.push(code);
    }

    byCode[code].operations.push({
      date: formatDate_(r[0]),
      kind: (r[3] || '').toString() === 'Оплата' ? 'payment' : 'charge',
      amount: toNumber_(r[4]),
      balanceAfter: toNumber_(r[5]),
      comment: (r[6] || '').toString(),
    });
  }

  return order.map(function (code) { return byCode[code]; });
}

/**
 * Отправляет СМС клиенту через шлюз smsc.ru (send.php, fmt=3 — ответ в
 * JSON). Требует заполненных SMSC_LOGIN/SMSC_PASSWORD выше — пока их нет,
 * возвращает понятную ошибку и ничего не отправляет.
 */
function sendSms_(phone, text) {
  const cleanPhone = (phone || '').toString().trim();
  const cleanText = (text || '').toString().trim();

  if (!cleanPhone) return { ok: false, error: 'Не указан телефон клиента' };
  if (!cleanText) return { ok: false, error: 'Пустой текст СМС' };
  if (!SMSC_LOGIN || !SMSC_PASSWORD) {
    return { ok: false, error: 'СМС-шлюз не настроен (SMSC_LOGIN/SMSC_PASSWORD в PriceSync.gs)' };
  }

  const url = 'https://smsc.ru/sys/send.php?' + [
    'login=' + encodeURIComponent(SMSC_LOGIN),
    'psw=' + encodeURIComponent(SMSC_PASSWORD),
    'phones=' + encodeURIComponent(cleanPhone),
    'mes=' + encodeURIComponent(cleanText),
    'charset=utf-8',
    'fmt=3',
  ].join('&');

  const resp = UrlFetchApp.fetch(url, { muteHttpExceptions: true });
  const code = resp.getResponseCode();
  if (code !== 200) {
    return { ok: false, error: 'СМС-шлюз вернул ошибку ' + code };
  }

  let parsed;
  try {
    parsed = JSON.parse(resp.getContentText());
  } catch (e) {
    return { ok: false, error: 'Не удалось разобрать ответ СМС-шлюза' };
  }

  if (parsed.error) {
    return { ok: false, error: 'СМС-шлюз: ' + parsed.error };
  }

  return { ok: true };
}

/** Находит (или создаёт при первом заказе) Google Таблицу — журнал заказов. */
function getOrCreateOrdersSheet_() {
  const props = PropertiesService.getScriptProperties();
  const savedId = props.getProperty(PROP_ORDERS_SHEET_ID);

  if (savedId) {
    try {
      return SpreadsheetApp.openById(savedId).getSheets()[0];
    } catch (e) {
      // Таблицу кто-то удалил вручную — создадим заново.
    }
  }

  const ss = SpreadsheetApp.create(ORDERS_SHEET_NAME);
  const sheet = ss.getSheets()[0];
  sheet.appendRow(ORDERS_HEADER);
  sheet.setFrozenRows(1);

  props.setProperty(PROP_ORDERS_SHEET_ID, ss.getId());
  return sheet;
}

/**
 * Веб-приложение: по умолчанию отдаёт текущий кэш прайса как JSON (как
 * раньше). С `?type=debts` отдаёт вместо этого текущий журнал долгов
 * (см. buildDebtLedger_) — тем же GET, тем же URL, приложение просто
 * добавляет параметр в запросе.
 */
function doGet(e) {
  const type = (e && e.parameter && e.parameter.type) || 'price';

  if (type === 'debts') {
    return jsonOutput_({ debts: buildDebtLedger_() });
  }

  const props = PropertiesService.getScriptProperties();
  let cachedId = props.getProperty(PROP_CACHE_FILE_ID);

  if (!cachedId) {
    checkAndSync();
    cachedId = props.getProperty(PROP_CACHE_FILE_ID);
  }

  const content = cachedId
    ? DriveApp.getFileById(cachedId).getBlob().getDataAsString()
    : '{"items":[],"count":0}';

  return ContentService.createTextOutput(content).setMimeType(ContentService.MimeType.JSON);
}
