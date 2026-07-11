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

Gml Manager интерактивно предложит выбрать действие, директорию установки и версию. По умолчанию используется последний стабильный тег GitHub, а проект устанавливается в `/srv/gml`.

Если вы уже работаете от имени `root`, используйте `sh` без `sudo`:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sh
```

Для установки без интерактивных запросов передайте аргументы через `sh -s --`:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --dir /srv/gml
```

Указывайте `--version`, только если хотите закрепить определённый тег Docker-образов:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- install --version v2025.3.2 --dir /srv/gml
```

Для обновления или удаления используйте следующие команды:

```bash
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- update --dir /srv/gml
curl -sSL https://raw.githubusercontent.com/Gml-Launcher/Gml.Backend/refs/heads/master/installer/gml-manager.sh | sudo sh -s -- delete --dir /srv/gml
```

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
SECURITY_KEY=643866c80c46c909332b30600d3265803a3807286d6eb7c0d2e164877c809519

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
