#!/bin/bash

# Usage:
#   sudo bash run.sh $WORK_DIR

if [ $# -eq 0 ]
  then
    echo "No working dir supplied"
    exit 1
fi

WORKING_DIR=$1
source $WORKING_DIR/tools/setup_proxy.sh
source $WORKING_DIR/tools/setup_jdk-21.sh
DCPerf_ROOT=$WORKING_DIR/repos/github/DCPerf/
FLASH23=/flash23

if [ -e $FLASH23/DCPerf-datasets ]
then
  echo "$FLASH23 already existed, skip download DCPerf-datasets"
  echo ""
else
  sudo mkdir $FLASH23
  cd $FLASH23
  git clone https://github.com/facebookresearch/DCPerf-datasets
  mv DCPerf-datasets/bpc_t93586_s2_synthetic ./bpc_t93586_s2_synthetic
  echo ""
fi

ignore=: '
sudo python3 -m pip install --upgrade pip
sudo pip install tabulate
sudo pip install numpy
sudo pip install pandas
echo ""

echo "============ install python package =============="
PROXY_OPTION="--option Acquire::HTTP::Proxy=socks5h://127.0.0.1:9762"
sudo apt install $PROXY_OPTION python3-click
sudo apt install $PROXY_OPTION python3-yaml
sudo apt install $PROXY_OPTION python3-tabulate
sudo apt install $PROXY_OPTION python3-numpy
sudo apt install $PROXY_OPTION python3-pandas
echo ""
'

echo "============ clone DCPerf repo =============="
if [ -e $DCPerf_ROOT ]
then
  echo "$DCPerf_ROOT already existed, skip download DCPerf"
  echo ""
else
  git clone https://github.com/facebookresearch/DCPerf.git
  echo ""
fi

# edit /etc/wgetrc to set wget proxy
pushd $DCPerf_ROOT
echo ""

echo "============ install remote =============="
sudo ./benchpress_cli.py install spark_standalone_remote
echo ""
ignore=:''
echo "============ run remote =============="
sudo ./benchpress_cli.py run spark_standalone_remote
echo ""

echo "============ install local =============="
sudo ./benchpress_cli.py install spark_standalone_local
echo ""
echo "============ run local =============="
sudo ./benchpress_cli.py run spark_standalone_local
echo ""

popd

ignore=: '
# check disck usage by folders:
#   sudo du -hs $FLASH23
#   sudo du -hs $DCPerf_ROOT

# If your system and network need IPV4, please run the following to launch the benchmark:
#   sudo ./benchpress_cli.py run spark_standalone_remote -i '{"ipv4": 1}'
# check if ipv6 enabled
#   ip a | grep inet6

# If you would like to perform the I/O performance sanity check before executing SparkBench workload and report the total IOPS for read and write measured by fio:
#   sudo ./benchpress_cli.py run spark_standalone_remote -i '{"sanity": 1}'

# if the output of hostname command is not resolvable, please specify a resolvable hostname using local_hostname parameter:
#   sudo ./benchpress_cli.py run spark_standalone_remote -i '{"local_hostname": "localhost"}'
'

