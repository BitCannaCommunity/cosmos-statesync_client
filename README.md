# State Sync - Client Script
Script to bootstrap the syncing when a new peer/validator join to BitCanna-Cosmos.

## The Problem
When a new peer tries to join a running chain it can take days to fully synchronise and this can take up a huge amount of disk space.

## The Solution
StateSync is a feature which would allow a new node to receive a snapshot of the application state without downloading blocks or going through consensus. Deploying the new State Sync function on StateSync servers could help to boost the synchronizing of new peers/validators. It also reduces the disk space usage. 

Bitcanna StateSync servers will include this function in mainnet. 

## Usage

This script will download the binary and the genesis by you and will setup the peers and seeds.  

Don't start the BitCanna daemon manually, the script will do it for you and will synchronize the whole chain. Press CTRL + C to stop it when you see the peer synced with last block

If you are running a validator/peer, this script will save space in disk for you, will backup your current data and config folder and resync in several minutes.
**Very important**, daemon should turned off if is not a clean installation.

* Install `jq` and download the script:

```
sudo apt install jq
wget https://raw.githubusercontent.com/BitCannaGlobal/cosmos-statesync_client/main/statesync_client.sh
chmod +x statesync_client.sh
```

### As a previous step before launch the script, STOP your `bcnad` daemon or `cosmovisor` if you already was running a peer/validator.
* Then launch the script (CTLR + C to stop it):
```
./statesync_client.sh
```

### When your peer is synced, set up a service file if you hadn't it previously.
Setup `bcnad` systemd service (copy and paste all to create the file service):
```
    cd $HOME
    echo "[Unit]
    Description=BitCanna Node
    After=network-online.target
    [Service]
    User=${USER}
    ExecStart=$(which bcnad) start
    Restart=always
    RestartSec=3
    LimitNOFILE=4096
    [Install]
    WantedBy=multi-user.target
    " >bcnad.service
```
    
Enable and activate the BCNAD service.

```
    sudo mv bcnad.service /lib/systemd/system/
    sudo systemctl enable bcnad.service && sudo systemctl start bcnad.service
```
Check the logs to see if it is working:
    ```
    sudo journalctl -u bcnad -f
    ``` 

### If you want to run a validator see this guide:
https://github.com/BitCannaGlobal/bcna/blob/main/README.md#3Create-a-validator

### DISCLAIMER:
This script is experimental, StateSync is experimental, run it at your own risk, make your own backups of the configuration and do not run it before reading and understanding the contents of the script.
