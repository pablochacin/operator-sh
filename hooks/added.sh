#!/bin/bash
set -x
echo "$(date +'%y-%m-%d %H:%m:%S') Processing event ${EVENT_TYPE} for object ${EVENT_OBJECT_KIND}/${EVENT_OBJECT_METADATA_NAME}" >> $LOG_FILE

