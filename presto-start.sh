#!/bin/bash

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/jre
export PATH=$JAVA_HOME/bin:$PATH

if [ "$HOSTNAME" = "presto001-sjc1" ]; then
    is_coordinator=true
else
    is_coordinator=false
fi
echo "is_coordinator ? $is_coordinator"

TMP_DIR=/tmp/presto
INSTALL_DIR=/opt/presto
PRESTOTAR="presto-server-0.142-SNAPSHOT.tar.gz"
PRESTOVER=`basename $PRESTOTAR .tar.gz`
HADOOPLZOJAR="hadoop-lzo-0.4.20-SNAPSHOT.jar"

pkill -f PrestoServer

mkdir -p $TMP_DIR
rm -rf $TMP_DIR/*
mkdir -p $INSTALL_DIR
chmod 755 $INSTALL_DIR
rm -rf $INSTALL_DIR/*

hadoop fs -get /lib/presto/$PRESTOTAR $TMP_DIR
hadoop fs -get /lib/presto/$HADOOPLZOJAR $TMP_DIR
hadoop fs -get /lib/presto/coordinator $TMP_DIR
hadoop fs -get /lib/presto/worker $TMP_DIR

cp $TMP_DIR/$PRESTOTAR $INSTALL_DIR
cd $INSTALL_DIR
tar -xvvf $PRESTOTAR
cp $TMP_DIR/$HADOOPLZOJAR $INSTALL_DIR/$PRESTOVER/plugin/hive-hadoop2/

if [ "$is_coordinator" == "true" ]; then
    cp -r $TMP_DIR/coordinator/etc $INSTALL_DIR/$PRESTOVER/
else
    cp -r $TMP_DIR/worker/etc $INSTALL_DIR/$PRESTOVER/
fi

ENVNAME="production"
NODEID=$HOSTNAME
PRESTOLOG="/var/log/presto"

mkdir -p $PRESTOLOG

cat << EOF > /opt/presto/$PRESTOVER/etc/node.properties
node.environment=$ENVNAME
node.id=$NODEID
node.data-dir=$PRESTOLOG
EOF

/opt/presto/$PRESTOVER/bin/launcher start

rm -rf $TMP_DIR
