#!/bin/bash

# Copyright 2020 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

ver="master"
if [[ "$#" -gt 0 ]]; then
  ver="$1"
fi

repo="https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/$ver/deploy"
if [[ "$#" -gt 1 ]]; then
  if [[ "$2" == *"local"* ]]; then
    echo "use local deploy"
    repo="./deploy"
  fi
fi

if [ $ver != "master" ]; then
	repo="$repo/$ver"
fi

echo "Installing Azure Disk CSI driver, version: $ver ..."

kubectl apply -f $repo/csi-azuredisk-driver.yaml
kubectl apply -f $repo/rbac-csi-azuredisk-controller.yaml
kubectl apply -f $repo/rbac-csi-azuredisk-node.yaml
kubectl apply -f $repo/csi-azuredisk-controller.yaml
kubectl apply -f $repo/csi-azuredisk-node.yaml
kubectl apply -f $repo/csi-azuredisk-node-windows.yaml

if [[ $ver == "v2"* ]]; then
  kubectl apply -f $repo/csi-azuredisk-scheduler-extender.yaml
  kubectl apply -f $repo/rbac-csi-azuredisk-scheduler-extender.yaml
  kubectl apply -f $repo/namespace-azure-disk-csi.yaml
  kubectl apply -f $repo/disk.csi.azure.com_azdrivernodes.yaml
  kubectl apply -f $repo/disk.csi.azure.com_azvolumeattachments.yaml
  kubectl apply -f $repo/disk.csi.azure.com_azvolumes.yaml
fi

if [[ "$#" -gt 1 ]]; then
  if [[ "$2" == *"snapshot"* ]]; then
    echo "install snapshot driver ..."
    kubectl apply -f $repo/crd-csi-snapshot.yaml
    kubectl apply -f $repo/rbac-csi-snapshot-controller.yaml
    kubectl apply -f $repo/csi-snapshot-controller.yaml
  fi

  if [[ "$2" == *"enable-avset"* ]]; then
    echo "set disable-avset-nodes as false ..."
    if [[ "$2" == *"local"* ]]; then
      cat $repo/csi-azuredisk-controller.yaml | sed 's/disable-avset-nodes=true/disable-avset-nodes=false/g' | kubectl apply -f -
    else
      curl -s $repo/csi-azuredisk-controller.yaml | sed 's/disable-avset-nodes=true/disable-avset-nodes=false/g' | kubectl apply -f -
    fi
  else
    kubectl apply -f $repo/csi-azuredisk-controller.yaml
  fi
else
  kubectl apply -f $repo/csi-azuredisk-controller.yaml
fi

echo 'Azure Disk CSI driver installed successfully.'
