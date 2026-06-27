<a id="english"></a>

# Repository Description

**Language:** English | [Русский](#russian)

This directory contains scripts for installing, updating, and removing Gml.Backend. The scripts simplify backend management for Gml and make the required operations easier to run.

## Installation

To install Gml.Backend, run the following commands in any convenient directory. The script requires `curl`; see the [curl installation guide](https://everything.curl.dev/get) if it is not installed.

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/installer.sh
chmod +x ./installer.sh
./installer.sh --version v2025.3.3.2
```

## Update

To update Gml.Backend, run the following commands in the directory that contains `docker-compose.yml` and `.env`:

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/updater.sh
chmod +x ./updater.sh
./updater.sh --version v2025.3.3.2
```

## Removal

To remove Gml.Backend, run the following command in the directory that contains `docker-compose.yml` and `.env`:

```sh
curl -s https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/delete.sh | sh
```

<a id="russian"></a>

# Описание репозитория

**Язык:** [English](#english) | Русский

Эта директория содержит скрипты для установки, обновления и удаления Gml.Backend. Скрипты упрощают процесс управления серверной частью Gml, обеспечивая легкость и удобство выполнения необходимых операций.

## Установка

Для установки Gml.Backend выполните следующие команды в удобной для вас директории. Для работы скрипта необходим `curl`; если он не установлен, смотрите [инструкцию по установке curl](https://losst.pro/ustanovka-curl-v-ubuntu).

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/installer.sh
chmod +x ./installer.sh
./installer.sh --version v2025.3.3.2
```

## Обновление

Для обновления Gml.Backend выполните следующие команды в директории, где находятся файлы `docker-compose.yml` и `.env`:

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/updater.sh
chmod +x ./updater.sh
./updater.sh --version v2025.3.3.2
```

## Удаление

Для удаления Gml.Backend выполните следующую команду в директории, где находятся файлы `docker-compose.yml` и `.env`:

```sh
curl -s https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/delete.sh | sh
```
