# Troubleshooting

<details>
  <summary>Installation failed?</summary>
<br>

[Try the offline Entware installer with SKeen preinstalled](https://github.com/jinndi/SKeen/tree/static/entware).
</details>

<details>
  <summary>Lost access to SSH Entware?</summary>
<br>

If access to Entware over SSH is lost, run the following in the router's Web CLI:

```sh
exec /opt/etc/init.d/S51dropbear restart
```

This restarts the Dropbear SSH service and usually restores access to Entware quickly.

</details>
