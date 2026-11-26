# Устранение неполадок

<details>
  <summary>Не устанавливается?</summary>
<br>

[Попробуйте оффлайн-установщик Entware с предустановленным SKeen](https://github.com/jinndi/SKeen/tree/static/entware).
</details>

<details>
  <summary>Пропал доступ к SSH Entware?</summary>
<br>

Если доступ к Entware по SSH пропал, выполните в Web CLI роутера:

```sh
exec /opt/etc/init.d/S51dropbear restart
```

Это перезапускает сервис Dropbear SSH и обычно быстро восстанавливает доступ к Entware.

</details>
