# linux-server-status
Quick output of server status. Similar to info upon login via ssh.

# Prerequisities
Install Bash

```bash
sudo apt update
sudo apt install bash
```

# Usage
```bash
bash /path/to/get_info.sh
```

# Output Files for messaging.
Also writes percentages of server usage into files so that they can be mapped into docker images. These files can be used to monitor the server state and send server state infos via Telegram, email or other messaging tools.

## Json

#### Default json output file
Writes output to path/to/server-states/system_info.json
```bash
bash /path/to/get_info.sh --json
```

#### Custom file
You can also provide a custom file where to write the json file to
```bash
# Ensure custom file exists.
mkdir -p /custom/path
touch /custom/path/file.json

# Command option short.
bash /path/to/get_info.sh --json -o /custom/path/file.json
# Command option long.
bash /path/to/get_info.sh --json --output-file /custom/path/file.json
```


### Cronjob
Setup cron to get periodic system info.

```bash
# Open crontab in edit mode.
crontab -e
```

```bash
# Execute command every hour at :59 min .
59 * * * * /bin/bash /path/to/get_info.sh --json --output-file /custom/path/file.json
```



