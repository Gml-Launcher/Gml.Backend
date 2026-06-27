![Frame 39262](https://github.com/user-attachments/assets/4ac0a227-a246-474a-8aab-1af34b6f8497)

**Сменить язык:** [English](README.md)

# Что изменено в ReGML

- Удалён Yarp proxy, заменён на Nginx.
- Обновлена документация по установке и настройке.

# Gml.Backend

Gml.Backend - комплексный проект для быстрого разворачивания серверной инфраструктуры игровых профилей Minecraft, включая Forge, Fabric и LiteLoader. Набор сервисов включает три основных компонента:

- **Gml.Web.Api**: REST API для взаимодействия с серверными данными.
- **Gml.Web.Client**: панель мониторинга и администрирования игровых профилей и лаунчера.
- **Gml.Web.Skin.Service**: сервис управления текстурами, который отвечает за персонализацию игроков.

Вместе эти сервисы дают готовую основу для управления Minecraft-профилями с модами.

## Документация

- [Официальный сайт](https://gml-launcher.ru)
- [Официальная документация](https://gml-launcher.ru/docs/welcome)

## Установка

### Шаг 1: Клонируйте репозиторий

Клонируйте стабильную версию репозитория:

```bash
git clone --recursive https://github.com/GamerVII-NET/Gml.Backend.git
```

### Шаг 2: Перейдите в директорию проекта

```bash
cd Gml.Backend
```

### Шаг 3: Настройте файл `.env`

Создайте или измените файл `.env` в корне директории `Gml.Backend`. Пример конфигурации:

```plaintext
# Идентификаторы пользователя и группы для Linux
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
BACKEND_ENDPOINT=http://localhost:5000/api/v1
MARKET_ENDPOINT=https://gml-market.recloud.tech
```

### Шаг 4: Настройте клиентский файл `.env`

Создайте или измените файл `.env` в директории `src/Gml.Web.Client/`:

```plaintext
# Адрес Web API
NEXT_PUBLIC_BACKEND_URL=http://localhost:5000/api/v1
NEXT_PUBLIC_MARKETPLACE_URL=https://gml-market.recloud.tech
```

### Шаг 5: Запустите проект через Docker

Убедитесь, что Docker установлен и запущен. Затем выполните команду для сборки и запуска проекта:

```bash
docker compose up -d --build
```

Docker загрузит необходимые образы и запустит контейнеры. После запуска сервисы будут доступны по адресам ниже.

## Инфраструктура

> **Примечание**: начиная с версии `0.1.0-rc1`, файлы серверов хранятся в директории установки. [Подробнее](#).

### Серверная инфраструктура

- **Web API**: `http://localhost:5000` (основной сервис)
- **Web Dashboard**: `http://localhost:5003` (требует регистрации)
- **Gml.Web.Skin.Service**: `http://localhost:5006` (доступен только внутри контейнера)

## Важные примечания

- Перед запуском проекта убедитесь, что файлы `.env` настроены корректно. При необходимости обновите конфигурацию под своё окружение.
