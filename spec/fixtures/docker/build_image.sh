#!/bin/bash
WORK_DIR=$( dirname "${BASH_SOURCE[0]}" )
echo "Work dir: ${WORK_DIR} with docker file ${WORK_DIR}/Dockerfile"
docker build --rm --force-rm -t c7-nifi-puppet:1.2 -f $WORK_DIR/Dockerfile .
