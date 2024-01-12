# linux-server-status
Quick output of server status. Similar to info upon login via ssh.

# Usage.
```bash
sh path/to/get_info.sh
```

# Output Files for messaging.
Also writes percentages of server usage into files so that they can be mapped into docker images. These files can be used to monitor the server state and send server state infos via Telegram, email or other messaging tools.

Use with --json option

Setup cron to get periodic system info.