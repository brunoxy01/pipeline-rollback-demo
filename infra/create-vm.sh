#!/usr/bin/env bash
# Cria a VM no Azure (k3s + runner ficam nela). Requer `az login` ativo.
# Uso: infra/create-vm.sh [meu-ip-cidr]   (ex.: 203.0.113.10/32; padrão: seu IP público atual)
set -euo pipefail

RG="${RG:-rg-rollback-demo}"
LOCATION="${LOCATION:-eastus}"
VM="${VM:-vm-rollback-demo}"
SIZE="${SIZE:-Standard_B2ms}"
MY_IP="${1:-$(curl -fsS https://api.ipify.org)/32}"

az group create -n "$RG" -l "$LOCATION" -o none

az vm create -g "$RG" -n "$VM" -l "$LOCATION" \
  --image Ubuntu2204 --size "$SIZE" \
  --admin-username azureuser --generate-ssh-keys \
  --custom-data "$(dirname "$0")/cloud-init.yaml" \
  --nsg-rule NONE -o none

az network nsg rule create -g "$RG" --nsg-name "${VM}NSG" -n ssh-me \
  --priority 100 --access Allow --protocol Tcp --destination-port-ranges 22 \
  --source-address-prefixes "$MY_IP" -o none

IP=$(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)
echo "VM criada: ssh azureuser@${IP}"
echo "Aguarde ~3 min pelo cloud-init e valide: ssh azureuser@${IP} 'sudo k3s kubectl get nodes'"
