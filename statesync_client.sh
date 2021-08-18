#!/bin/bash
# Based on the work of Joe (Chorus-One) for Microtick - https://github.com/microtick/bounties/tree/main/statesync
# You need config in two peers (avoid seed servers) this values in app.toml:
#     [state-sync]
#     snapshot-interval = 1000
#     snapshot-keep-recent = 10
# Pruning should be fine tuned also, for this testings is set to nothing
#     pruning = "nothing"

set -e

# Change for your custom chain
BINARY="https://github.com/BitCannaGlobal/bcna/releases/download/v0.2-beta/bcnad"
GENESIS="https://raw.githubusercontent.com/BitCannaGlobal/testnet-bcna-cosmos/main/instructions/public-testnet/genesis.json"
APP="BCNA: ~/.bcna"

read -p "$APP folder, your keys and config will be erased, proced (y/n)? " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  # BitCanna State Sync client config.
  rm -f bcnad #deletes a previous downloaded binary
  rm -rf $HOME/.bcna/ #deletes previous installation   
  wget -nc $BINARY
  chmod +x bcnad
  ./bcnad init New_peer --chain-id bitcanna-testnet-6
  rm -rf $HOME/./bcnad/config/genesis.json #deletes the default created genesis
  curl -s $GENESIS > $HOME/.bcna/config/genesis.json
  
  NODE1_IP="178.128.247.173"
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
  s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"d6aa4c9f3ccecb0cc52109a95962b4618d69dd3f@seed1.bitcanna.io:26656,23671067d0fd40aec523290585c7d8e91034a771@seed2.bitcanna.io:16656\"|" $HOME/.bcna/config/config.toml

 
  sed -E -i 's/minimum-gas-prices = \".*\"/minimum-gas-prices = \"0.01bcna\"/' $HOME/.bcna/config/app.toml

  ./bcnad unsafe-reset-all
  ./bcnad start
   echo If your node is synced considerate to create a service file. 
fi
