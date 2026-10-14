## Offline Entware Installers with SKeen

This section provides offline Entware installers for different router architectures of Keenetic/Netcraze devices, with SKeen preinstalled and configured to use an external build of the latest stable sing-box version, compressed with UPX ([our build](https://github.com/jinndi/skeen-box)).

### Installation

The installation process is similar to the official instructions for installing Entware [on a USB drive](https://support.keenetic.com/hero/kn-1012/en/20980-installing-the-entware-repository-on-a-usb-drive.html) or [in the router's internal storage](https://support.keenetic.com/hero/kn-1012/en/18482-installing-opkg-entware-in-the-router-s-internal-memory.html).

We recommend the first option — installing Entware on a USB drive. It is simple and avoids using up or wearing out the router's internal storage.

1. Download the archive for your router's architecture.
2. Prepare a **clean partition** on the USB drive, formatted as `ext4`.
3. Create an `install` directory and place the downloaded `*.tar.gz` archive in it.
4. In the router's web interface, open the **OPKG** page and select the USB drive containing the archive in the **Storage** field. The web interface may become temporarily unresponsive during installation — wait for the process to finish.
5. Open **Diagnostics** → **System log** and wait for the installation completion messages. Since the installation is performed offline, without any network requests, it should take only a short time.

The following messages should appear in the log:

```text
[4/4] Установка "Entware Offline SKeen" успешно завершена!
Не забудьте настроить SKeen (файл /opt/etc/skeen.json)
Можно открыть SSH (логин - root, пароль - keenetic, порт - 222).
```
---

🇷🇺 **Русский**

## Оффлайн-установщики Entware с SKeen


В этом разделе представлены оффлайн-установщики Entware для разных архитектур роутеров Keenetic/Netcraze с предустановленным SKeen, включающим внешнюю сборку sing-box последней стабильной версии, сжатую с помощью UPX ([наша сборка](https://github.com/jinndi/skeen-box)).

### Установка

Установка выполняется аналогично официальным инструкциям: [на диск или флешку](https://support.netcraze.ru/giga/nc-1012/ru/20980-installing-the-entware-repository-on-a-usb-drive.html) или [во встроенную память роутера](https://support.netcraze.ru/giga/nc-1012/ru/18482-installing-opkg-entware-in-the-router-s-internal-memory.html).

Рекомендуем первый вариант — установку на диск или флешку. Он прост и позволяет не занимать и изнашивать встроенную память роутера.

1. Скачайте архив для нужной архитектуры.
2. Подготовьте **чистый раздел** на диске или флешке, отформатированный в `ext4`.
3. Создайте папку `install` и поместите в неё скачанный архив `*.tar.gz`.
4. В веб-интерфейсе роутера откройте страницу **OPKG** и в поле **Накопитель** выберите диск или флешку, на которой находится архив. Установка может ненадолго приостановить работу веб-интерфейса — дождитесь её завершения.
5. Откройте страницу **Диагностика** → **Системный журнал** и дождитесь сообщений об успешном завершении установки. Поскольку установка выполняется оффлайн, без запросов к сети, она должна занять немного времени.

В журнале должны появиться следующие сообщения:

```text
[4/4] Установка "Entware Offline SKeen" успешно завершена!
Не забудьте настроить SKeen (файл /opt/etc/skeen.json)
Можно открыть SSH (логин - root, пароль - keenetic, порт - 222).
```
