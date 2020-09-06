#!/bin/bash

source lib/log.sh

LOG_LEVEL=$LOG_LEVEL_DEBUG

log_info "Processing event ${EVENT_TYPE} for object ${EVENT_OBJECT_KIND}/${EVENT_OBJECT_METADATA_NAME}"

log_debug "$(env | grep 'EVENT_' | sort)"

