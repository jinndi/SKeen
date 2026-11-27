# Entware Offline for Netcraze / Keenetic

## Русский

В этой папке публикуются готовые архивы rootfs Entware для поддерживаемых архитектур. Архивы собраны для установки через OPKG на роутеры Netcraze/Keenetic. Это не официальные пакеты Netcraze или Entware.

### Какой архив выбрать

| Имя файла | Содержимое |
| --- | --- |
| `entware-offline-skeen-aarch64.tar.gz` | Entware для AArch64 с предустановленными SKeen и sing-box. |
| `entware-offline-skeen-mips.tar.gz` | Entware для MIPS с предустановленными SKeen и sing-box. |
| `entware-offline-skeen-mipsel.tar.gz` | Entware для MIPSel с предустановленными SKeen и sing-box. |
| `entware-offline-aarch64.tar.gz` | Базовый Entware для AArch64, без SKeen и sing-box. |
| `entware-offline-mips.tar.gz` | Базовый Entware для MIPS, без SKeen и sing-box. |
| `entware-offline-mipsel.tar.gz` | Базовый Entware для MIPSel, без SKeen и sing-box. |

Суффикс обозначает вариант сборки: `-skeen` — SKeen уже установлен; без него — только базовая среда Entware. Архитектура должна соответствовать процессору роутера. Для Netcraze Giga (NC-1012) нужна AArch64-сборка; для других моделей проверьте архитектуру в документации своей модели. Не устанавливайте архив для другой архитектуры.

Архивы включают базовые компоненты Entware, необходимые для запуска. Вариант `-skeen` дополнительно содержит SKeen, API и sing-box. После установки потребуется настроить SKeen и его конфигурацию; наличие программы в архиве само по себе не означает, что прокси уже настроен.

### Установка во встроенную память

Инструкция Netcraze: [Установка OPKG Entware на встроенную память роутера](https://support.netcraze.ru/giga/nc-1012/ru/18482-installing-opkg-entware-in-the-router-s-internal-memory.html).

1. Убедитесь, что ваша модель поддерживает установку Entware во встроенную память, и установите компонент **Поддержка открытых пакетов (OPKG)**.
2. В хранилище `storage:` создайте папку `install` и скопируйте в неё архив нужной архитектуры из этой папки репозитория. Не распаковывайте архив вручную.
3. В интерфейсе командной строки роутера выберите встроенное хранилище для OPKG:

   ```text
   opkg disk storage:/
   ```

   Либо задайте накопитель через страницу **Менеджер пакетов OPKG**, если этот способ доступен в вашей версии ОС.
4. Дождитесь окончания установки и проверьте системный журнал роутера.

Встроенная флеш-память имеет ограничения по ресурсу и объёму. Ознакомьтесь с предупреждениями производителя перед установкой.

### Установка на внешний USB-накопитель

Инструкция Netcraze: [Установка репозитория Entware на USB-накопитель](https://support.netcraze.ru/giga/nc-1012/ru/20980-installing-the-entware-repository-on-a-usb-drive.html).

1. Подготовьте USB-накопитель с разделом **ext4** и установите компонент **Поддержка открытых пакетов (OPKG)**. Подключите накопитель к роутеру.
2. Создайте в корне раздела папку `install` и скопируйте туда архив нужной архитектуры. Не распаковывайте архив вручную.
3. Откройте страницу **Менеджер пакетов OPKG**, выберите этот накопитель в поле **Накопитель**, включите **Доступ для учётной записи пользователя** и нажмите **Сохранить**.
4. Дождитесь установки. Подробности и подключение по SSH смотрите в инструкции Netcraze выше.

Используйте полный текст инструкции Netcraze для подготовки хранилища и компонентов ОС: точные названия пунктов интерфейса могут отличаться между версиями прошивки. Архивы из этой папки заменяют стандартный `*-installer.tar.gz`; их не нужно распаковывать или переименовывать.

### Что появится после установки

После первой установки скрипт Entware выполнит начальную настройку: создаст SSH-ключи, включит автозапуск Entware и запустит SSH-сервер Dropbear. В системном журнале появится сообщение об успешной установке. Для SSH-подключения скрипт сообщает логин `root`, временный пароль `keenetic` и порт `222` (если в роутере установлен компонент SSH-сервера; иначе используйте порт, указанный в инструкции Netcraze). **Сразу смените временный пароль.**

В варианте с SKeen после настройки будут доступны, в частности:

- команда управления `skeen` и исполняемые файлы `/opt/bin/skeen`, `/opt/bin/skeen-api`;
- бинарный файл sing-box `/opt/bin/skeen-box`;
- конфигурация SKeen `/opt/etc/skeen/skeen.json`;
- конфигурация sing-box `/opt/etc/skeen/config.json`;
- скрипт автозапуска `/opt/etc/init.d/S99SKeen`.

Некоторые файлы и скрипты перемещаются в рабочее положение при первом запуске установщика, поэтому сразу после распаковки содержимое `/opt` может отличаться от этого списка. Настройте SKeen по [руководству проекта](../README-RU.md) и документации в `docs/`. Если выбрали базовый архив без SKeen, эти файлы и команда `skeen` не устанавливаются.

---

## English

This directory contains ready-to-install Entware rootfs archives for supported architectures. The archives are built for installation through OPKG on Netcraze/Keenetic routers. They are not official Netcraze or Entware packages.

### Choose an archive

| File name | Contents |
| --- | --- |
| `entware-offline-skeen-aarch64.tar.gz` | Entware for AArch64 with SKeen and sing-box preinstalled. |
| `entware-offline-skeen-mips.tar.gz` | Entware for MIPS with SKeen and sing-box preinstalled. |
| `entware-offline-skeen-mipsel.tar.gz` | Entware for MIPSel with SKeen and sing-box preinstalled. |
| `entware-offline-aarch64.tar.gz` | Base Entware for AArch64, without SKeen or sing-box. |
| `entware-offline-mips.tar.gz` | Base Entware for MIPS, without SKeen or sing-box. |
| `entware-offline-mipsel.tar.gz` | Base Entware for MIPSel, without SKeen or sing-box. |

The suffix identifies the build: `-skeen` means SKeen is preinstalled; without it, the archive contains only the base Entware environment. Choose the archive that matches your router's CPU architecture. Netcraze Giga (NC-1012) requires the AArch64 build; check your model's documentation for other devices. Do not install an archive for a different architecture.

Both variants include the base Entware components required to run the environment. The `-skeen` variant additionally includes SKeen, its API, and sing-box. You still need to configure SKeen; the preinstalled software is not a ready-to-use proxy configuration.

### Install to internal storage

Netcraze guide: [Installing OPKG Entware in the router's internal memory](https://support.netcraze.ru/giga/nc-1012/ru/18482-installing-opkg-entware-in-the-router-s-internal-memory.html).

1. Make sure your router model supports Entware on internal storage and install the **OPKG Open Packages support** component.
2. Create an `install` directory in `storage:` and copy the archive for your architecture into it. Do not extract the archive manually.
3. In the router CLI, select internal storage for OPKG:

   ```text
   opkg disk storage:/
   ```

   Alternatively, select the storage in the **OPKG Package Manager** page if that option is available in your OS version.
4. Wait for installation to finish and check the router's system log.

Internal flash has limited capacity and write endurance. Read the manufacturer's warnings before installing Entware there.

### Install to an external USB drive

Netcraze guide: [Installing the Entware repository on a USB drive](https://support.netcraze.ru/giga/nc-1012/ru/20980-installing-the-entware-repository-on-a-usb-drive.html).

1. Prepare a USB drive with an **ext4** partition and install the **OPKG Open Packages support** component. Connect the drive to the router.
2. Create an `install` directory at the root of the partition and copy the archive for your architecture there. Do not extract the archive manually.
3. Open **OPKG Package Manager**, select the drive in the **Storage** field, enable **Access for user account**, and click **Save**.
4. Wait for installation to finish. See the Netcraze guide above for details and SSH access.

Follow the full Netcraze guide for preparing storage and installing OS components; UI labels may vary between firmware versions. These archives replace the standard `*-installer.tar.gz` installer. Do not extract or rename them.

### Expected result

On first installation, the Entware setup script performs initial configuration: it generates SSH keys, enables Entware startup, and starts the Dropbear SSH server. The router's system log reports when installation completes. The script reports SSH login `root`, temporary password `keenetic`, and port `222` (when the router's SSH server component is installed; otherwise use the port specified by the Netcraze guide). **Change the temporary password immediately.**

With the SKeen archive, the installed environment includes, among other files:

- the `skeen` management command and executables `/opt/bin/skeen` and `/opt/bin/skeen-api`;
- the sing-box binary at `/opt/bin/skeen-box`;
- SKeen configuration at `/opt/etc/skeen/skeen.json`;
- sing-box configuration at `/opt/etc/skeen/config.json`;
- startup script `/opt/etc/init.d/S99SKeen`.

Some files and scripts are moved into place by the first-run installer, so `/opt` may differ immediately after extraction. Configure SKeen using the [project guide](../README.md) and the documentation in `docs/`. The base archive does not install these SKeen files or the `skeen` command.
