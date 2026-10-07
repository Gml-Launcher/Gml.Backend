![Frame 39262](https://github.com/user-attachments/assets/4ac0a227-a246-474a-8aab-1af34b6f8497)

**Сменить язык:** [English](README.md)

# Gml.Backend

Gml.Backend — комплексный проект для быстрого развёртывания серверной инфраструктуры игровых профилей Minecraft, включая Forge, Fabric и LiteLoader. В состав проекта входят три основных сервиса:

- **Gml.Web.Api** — REST API для взаимодействия с серверными данными.
- **Gml.Web.Client** — панель мониторинга и администрирования игровых профилей и лаунчера.
- **Gml.Web.Skin.Service** — сервис управления текстурами и персонализацией игроков.

Вместе эти сервисы образуют готовую основу для управления игровыми профилями Minecraft с модами.

## Документация

- [Официальный сайт](https://gml-launcher.ru)
- [Официальная документация](https://gml-launcher.ru/docs/welcome)

## Быстрая установка через Gml Manager

Самый простой способ запустить менеджер установки:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh
```

Gml Manager интерактивно предложит выбрать язык, действие, директорию установки, версию и режим прокси. Язык по умолчанию определяется по системной локали, версия — по последнему стабильному тегу GitHub, а проект устанавливается в `/srv/gml`.

Доступны два режима прокси:

- `external` — GML работает по HTTP на `PORT_GML_FRONTEND` за существующим nginx или другим reverse proxy;
- `global` — Angie занимает публичные порты 80/443 и автоматически получает сертификат Let’s Encrypt для `GML_PROXY_DOMAIN`.

Перед включением `global` менеджер проверяет, что порты 80/443 свободны, DNS A указывает на публичный IPv4 сервера, а существующая AAAA-запись — на его публичный IPv6. Проксирование DNS через Cloudflare/CDN этим режимом не поддерживается.

Если вы уже работаете от имени `root`, используйте `sh` без `sudo`:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sh
```

Для установки без интерактивных запросов передайте аргументы через `sh -s --`:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --dir /srv/gml
```

Неинтерактивная установка Angie как основного HTTPS-прокси:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --dir /srv/gml --proxy-mode global --domain gml.example.com --accept-acme-terms
```

Те же параметры можно передать команде `update`, чтобы перейти между `external` и `global`. Если `--proxy-mode` при обновлении не указан, текущий режим сохраняется.

Минимальная поддерживаемая версия для новой установки — `v2026.2`; ограничение не применяется к обновлению.

Указывайте `--version`, только если хотите закрепить определённый тег Docker-образов:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --version v2026.2 --dir /srv/gml
```

Для обновления или удаления используйте следующие команды:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- update --dir /srv/gml
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- delete --dir /srv/gml
```

## Локальная разработка и Rider

Нужны .NET SDK 10, .NET/ASP.NET Core Runtime 8 для сервиса скинов, Node.js 20+ и npm.
Подготовьте подмодули и зависимости из корня репозитория:

```bash
git submodule update --init --recursive
npm --prefix src/Gml.Web.Client ci
dotnet restore Gml.Backend.sln
```

При первом запуске в Development API автоматически создаёт случайный ключ в
`src/Gml.Web.Api/src/Gml.Web.Api/database/development.key` и переиспользует его при следующих
запусках из Rider и скрипта. Файл исключён из Git. Переменная окружения `SECURITY_KEY` имеет
приоритет; в production задавайте её через окружение.

Откройте `Gml.Backend.sln` в Rider, выберите сохранённую конфигурацию **GML Development**
и нажмите Run или Debug. Она одновременно запускает Frontend, Backend (development)
и Skins (development); Debug подключает отладчики к обоим .NET-сервисам.
Рабочие каталоги .NET-сервисов берутся из каталогов их проектов.

Для запуска из терминала Linux/macOS используйте:

```bash
./scripts/dev.sh
```

Скрипт можно вызывать из любого каталога по его полному пути. Он проверяет инструменты,
зависимости и порты, останавливает все свои процессы по Ctrl+C, SIGTERM или при выходе
любого сервиса. В Rider останавливайте всю Compound-конфигурацию кнопкой Stop All.
База SQLite и файлы сервисов сохраняются в обычных каталогах локальной разработки.

Откройте **http://localhost:3000**. Next.js проксирует `/api*`, `/swagger*`, `/ws*` и точный
`/health` к API на `http://127.0.0.1:5002`; `/skins` и `/skins/*` — к сервису на порту 5086
с удалением префикса `/skins`. WebSocket и запросы браузера используют тот же адрес фронтенда.
API использует HTTP-профиль `frontend` с публичным marketplace `https://gml-market.recloud.tech`,
скины — профиль `http`. Отдельный marketplace запускать не требуется.

Как в Angie, незавершённая установка перенаправляет `/` на `/mnt`; после установки `/mnt`
и вложенные страницы возвращают на `/`. Если API недоступен или проверка дольше 3 секунд,
главная страница остаётся доступной, а `/mnt` возвращает на `/`.

При отдельном запуске фронтенда upstream можно переопределить в
`src/Gml.Web.Client/.env.development.local`: `DEV_BACKEND_URL` и `DEV_SKINS_URL`.
По умолчанию это `http://127.0.0.1:5002` и `http://127.0.0.1:5086`.


## Установка вручную

### Шаг 1. Клонируйте репозиторий

Клонируйте стабильную версию репозитория:

```bash
git clone --recursive https://github.com/GamerVII-NET/Gml.Backend.git
```

### Шаг 2. Перейдите в директорию проекта

```bash
cd Gml.Backend
```

### Шаг 3. Настройте файл `.env`

Создайте или измените файл `.env` в корневой директории `Gml.Backend`:

```plaintext
# Идентификаторы пользователя и группы Linux
UID=0
GID=0

# Ключ безопасности (замените на собственный безопасный ключ)
SECURITY_KEY=<your-security-key>

# Настройки проекта
PROJECT_NAME=GmlBackendPanel
PROJECT_DESCRIPTION=
PROJECT_POLICYNAME=GmlServerPolicy
PROJECT_PATH=

# Настройки внешнего доступа
PORT_GML_BACKEND=5000
PORT_GML_FRONTEND=5003
PORT_GML_SKINS=5006

# Микросервисы
SERVICE_TEXTURE_ENDPOINT=http://gml-web-skins:8085
MARKET_ENDPOINT=https://gml-market.recloud.tech
```

### Шаг 4. Настройте клиентский файл `.env`

Создайте или измените файл `.env` в директории `src/Gml.Web.Client/`:

```plaintext
# Адрес Web API
NEXT_PUBLIC_BACKEND_URL=http://localhost:5000/api/v1
NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech
```

### Шаг 5. Запустите проект через Docker

Убедитесь, что Docker установлен и запущен, затем соберите и запустите проект:

```bash
docker compose up -d --build
```

Docker загрузит необходимые образы и запустит контейнеры. После запуска сервисы будут доступны по указанным ниже адресам.

## Инфраструктура

> **Примечание:** начиная с версии `0.1.0-rc1`, серверные файлы хранятся в директории установки. [Подробнее](#).

### Серверные сервисы

- **Web API:** `http://localhost:5000` — основной сервис.
- **Web Dashboard:** `http://localhost:5003` — требуется регистрация.
- **Gml.Web.Skin.Service:** `http://localhost:5006` — доступен только внутри контейнера.

## Важные примечания

- FileBrowser удалён начиная с версии `0.1.0-rc1`. [Подробнее](#).
- Minio удалён начиная с версии `1.0.3`. [Подробнее](#).
- Перед запуском проекта убедитесь, что файлы `.env` настроены корректно. При необходимости измените параметры под своё окружение.
