# State Sync - client script
Script to bootstrap the syncing when a new peer/validator join to BitCanna-Cosmos

## The problem...
When a new peer try to join to a running chain maybe could take days to sync completly

## The solution...
Deploying the new State Sync function on seed servers could help to boost the sync of new peers/validators.
Bitcanna seeds server will include this function from MainNet block 1

## Usage
Before executing the script, configure the client as described at http://to.do. But don't start the BitCanna daemon manually, the script will do for you and will sync the whole chain. Press CTRL + C to stop it when you see the peer synced with last block.


Download the script:

```
wget https://raw.githubusercontent.com/BitCannaCommunity/statesync_client/main/statesync_client.sh
chmod +x statesync_client.sh
```

As a previous step before launch the script, edit it with `nano` tool and change the rpc_peers if it needed. 
* Then launch the script (CTLR + C to stop it):
`statesync_client.sh`


