<a id="english"></a>

# Gml.Backend manager

**Language:** English | [Русский](#russian)

This directory contains a single `gml-manager.sh` script for installing, updating, and removing Gml.Backend.

The script stops on the first failed step and prints the failed step name plus the last log lines. The default installation directory is `/srv/gml`, but you can choose another directory with `--dir` or through the interactive prompt.

## Installation

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/gml-manager.sh
chmod +x ./gml-manager.sh
sudo ./gml-manager.sh install --version v2025.3.3.2 --dir /srv/gml
```

## Update

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/gml-manager.sh
chmod +x ./gml-manager.sh
sudo ./gml-manager.sh update --version v2025.3.3.2 --dir /srv/gml
```

## Removal

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/gml-manager.sh
chmod +x ./gml-manager.sh
sudo ./gml-manager.sh delete --dir /srv/gml
```

## Interactive mode

Run the script without arguments to choose the action, installation directory, and version interactively:

```sh
sudo ./gml-manager.sh
```

<a id="russian"></a>

# Менеджер Gml.Backend

**Язык:** [English](#english) | Русский

Эта директория содержит единый скрипт `gml-manager.sh` для установки, обновления и удаления Gml.Backend.

Скрипт останавливается на первом упавшем шаге и выводит название шага вместе с последними строками лога. Папка установки по умолчанию: `/srv/gml`, но ее можно выбрать через `--dir` или интерактивный ввод.

## Установка

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/gml-manager.sh
chmod +x ./gml-manager.sh
sudo ./gml-manager.sh install --version v2025.3.3.2 --dir /srv/gml
```

## Обновление

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/gml-manager.sh
chmod +x ./gml-manager.sh
sudo ./gml-manager.sh update --version v2025.3.3.2 --dir /srv/gml
```

## Удаление

```sh
curl -O https://raw.githubusercontent.com/serega404/ReGml.Backend/refs/heads/master/installer/gml-manager.sh
chmod +x ./gml-manager.sh
sudo ./gml-manager.sh delete --dir /srv/gml
```

## Интерактивный режим

Запустите скрипт без аргументов, чтобы выбрать действие, папку установки и версию интерактивно:

```sh
sudo ./gml-manager.sh
```
