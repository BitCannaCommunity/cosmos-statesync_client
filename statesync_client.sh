#!/bin/bash
# Based on the work of Joe (Chorus-One) for Microtick - https://github.com/microtick/bounties/tree/main/statesync
# You need config in two peers (avoid seed servers) this values in app.toml:
#     [state-sync]
#     snapshot-interval = 1000
#     snapshot-keep-recent = 10
# Pruning should be fine tuned also, for this testings is set to nothing
#     pruning = "nothing"

set -e
export DATE_BACKUP=`date +"%d_%m_%Y-%H_%M"`

# Change for your custom chain
BINARY="https://github.com/BitCannaGlobal/bcna/releases/download/v1.3.1/bcnad"
GENESIS="https://raw.githubusercontent.com/BitCannaGlobal/bcna/main/genesis.json"
APP="BCNA: ~/.bcna"
echo "Welcome to the StateSync script. This script will backup your config, move the current .bcna folder to .old_bcna, sync the last state and restore the previous config. 
You should have a crypted backup of your wallet keys, your node keys and your validator keys, anyway the script will make a clear backup of the last two. Ensure that you can restore your wallet keys if is needed."
read -p "have you stopped the BCNAD service? CTRL + C to exit or any key to continue..."
read -p "$APP folder, your keys and config will be erased, a backup will be made, PROCED (y/n)? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  # BitCanna State Sync client config.
  echo ##################################################
  echo " Making a backup from .bcna config files if exist"
  echo ##################################################
  cd ~
  if [ -d ~/.bcna ];
  then
    echo "There is a BCNA folder there... taking a backup and moving to .old_bcna"
    tar cvfz bcna_folder_backup_$DATE_BACKUP.tgz --exclude=".bcna/data/cs.wal" --exclude=".bcna/data/application.db" --exclude=".bcna/data/blockstore.db" --exclude=".bcna/data/evidence.db" --exclude=".bcna/data/snapshots" --exclude=".bcna/data/state.db"   --exclude=".bcna/data/tx_index.db" .bcna/*
    if [ -d ~/.old_bcna ];

    then 
      echo Folder .old_bcna exist, will maintain this old folder.
      rm  -rf .bcna
    else
      mv .bcna .old_bcna
    fi
  else
      echo "New installation...."
      touch ~/.new_installation
  fi
  if [ -f ~/bcnad ];
  then
    rm -f bcnad #deletes a previous downloaded binary
  fi
  wget -nc $BINARY
  chmod +x bcnad
  ./bcnad init New_peer --chain-id bitcanna-1
  rm -rf $HOME/.bcnad/config/genesis.json #deletes the default created genesis
  curl -s $GENESIS > $HOME/.bcna/config/genesis.json
  
  NODE1_IP="206.189.9.95"
  RPC1="http://$NODE1_IP"
  P2P_PORT1=26656
  RPC_PORT1=26657

  NODE2_IP="159.65.198.245"
  RPC2="http://$NODE2_IP"
  RPC_PORT2=26657
  P2P_PORT2=26656

  #If you want to use a third StateSync Server... 
  #DOMAIN_3=seed1.bitcanna.io     # If you want to use domain names 
  #NODE3_IP=$(dig $DOMAIN_1 +short
  #RPC3="http://$NODE3_IP"
  #RPC_PORT3=26657
  #P2P_PORT3=26656

  INTERVAL=1000

  LATEST_HEIGHT=$(curl -s $RPC1:$RPC_PORT1/block | jq -r .result.block.header.height);
  BLOCK_HEIGHT=$((($(($LATEST_HEIGHT / $INTERVAL)) -10) * $INTERVAL)); #Mark addition
  
  if [ $BLOCK_HEIGHT -eq 0 ]; then
    echo "Error: Cannot state sync to block 0; Latest block is $LATEST_HEIGHT and must be at least $INTERVAL; wait a few blocks!"
    exit 1
  fi

  TRUST_HASH=$(curl -s "$RPC1:$RPC_PORT1/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
  if [ "$TRUST_HASH" == "null" ]; then
    echo "Error: Cannot find block hash. This shouldn't happen :/"
    exit 1
  fi

  NODE1_ID=$(curl -s "$RPC1:$RPC_PORT1/status" | jq -r .result.node_info.id)
  NODE2_ID=$(curl -s "$RPC2:$RPC_PORT2/status" | jq -r .result.node_info.id)
  #NODE3_ID=$(curl -s "$RPC3:$RPC_PORT3/status" | jq -r .result.node_info.id)


  sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
  s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"http://$NODE1_IP:$RPC_PORT1,http://$NODE2_IP:$RPC_PORT2\"| ; \
  s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
  s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
  s|^(persistent_peers[[:space:]]+=[[:space:]]+).*$|\1\"${NODE1_ID}@${NODE1_IP}:${P2P_PORT1},${NODE2_ID}@${NODE2_IP}:${P2P_PORT2}\"| ; \
  s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"d6aa4c9f3ccecb0cc52109a95962b4618d69dd3f@seed1.bitcanna.io:26656,23671067d0fd40aec523290585c7d8e91034a771@seed2.bitcanna.io:26656\"|" $HOME/.bcna/config/config.toml

 
  sed -E -i -s 's/minimum-gas-prices = \".*\"/minimum-gas-prices = \"0.001ubcna\"/' $HOME/.bcna/config/app.toml

  ./bcnad unsafe-reset-all
  echo ##################################################################
  echo "PLEASE HIT CTRL+C WHEN THE CHAIN IS SYNCED, Wait the last block"
  echo ##################################################################
  sleep 5
  ./bcnad start
   if [ -f ~/.new_installation ];
    then
      rm -f .new_installation
      sed -E -i 's/enable = true/enable = false/' $HOME/.bcna/config/config.toml
   else
   echo 
   echo Waiting 10 seconds... your backup will be restored with your previous data.... and BCNAD will start again to test it.
   echo .
   echo HIT CTLR+C when last block is synced again.
   sleep 10
   tar -xzvf bcna_folder_backup_$DATE_BACKUP.tgz
   fi
   ./bcnad start
   echo If your node is synced considerate to create a service file. Be careful, your backup file is not crypted!
   echo If process was sucessful you can delete .old_bcna
fi
