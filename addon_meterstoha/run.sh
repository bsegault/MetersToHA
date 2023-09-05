#!/usr/bin/with-contenv bashio

#
# Cloning on each run at this moment for testing
#
git clone --depth=1 "https://github.com/mdeweerd/MetersToHA.git" --no-checkout MetersToHA
(
  cd MetersToHA || exit 255
  git sparse-checkout set apps
  git checkout
)

echo "Generate configuration file"

CONFIG_FILE="$(realpath .)/m2h_config.json"
RUN_OPT=""
TYPE="ha"

# Defaults

keys="veolia_login veolia_password veolia_contract grdf_login grdf_password grdf_pce timeout download_folder domoticz_idx domoticz_server domoticz_login domoticz_password mqtt_server mqtt_port mqtt_login mqtt_password"
event_keys="veolia grdf"
event_conf=""
events=""

config=""
if bashio::config.has_value "captchaservice"; then
  captchaservice=$(bashio::config "captchaservice")
  if bashio::config.has_value "token_captchaservice"; then
    token_captchaservice=$(bashio::config "token_captchaservice")
    token_config="\"${captchaservice}_token\":\"${token_captchaservice//\"/\\\"}\""
    config="$config$token_config,
    "
  fi
fi

# shellcheck disable=SC2086
for key in $keys ; do
  if bashio::config.has_value $key; then
    value="$(bashio::config "$key")"
    config="$config\"${key//\"/\\\"}\":\"${value/\"/\\\"}\",
    "
  fi
done

event_matching=""
# shellcheck disable=SC2086
for key in $event_keys ; do
  if bashio::config.has_value "${key}_event"; then
    value="$(bashio::config "${key}_event")"
    event_conf="$key:$value"
    event_matching="$event_matching""[[ \"\$1\" == \"${value/\"/\\\"}\" ]] && TARGET_OPT=--$key
"
    # shellcheck disable=SC2089
    events="$events ${value//\"/\\\"}"
  fi
done


if bashio::config.has_value DISPLAY ; then
  DISPLAY="$(bashio::config DISPLAY)"
  export DISPLAY
fi

LOG_LEVEL=info
if bashio::config.has_value log_level ; then
  LOG_LEVEL="$(bashio::config log_level)"
fi

if bashio::config.has_value logs_folder ; then
  # shellcheck disable=SC2089
  RUN_OPT="${RUN_OPT} -l $(bashio::config logs_folder)"
  LOGS_FOLDER="$(bashio::config logs_folder)"
fi

if bashio::config.has_value type ; then
  TYPE="$(bashio::config type)"
  TYPE="${TYPE//\"/\\\"}"
fi

if bashio::config.true debug ; then
  RUN_OPT="${RUN_OPT} --debug"
fi

if bashio::config.true local_config ; then
  RUN_OPT="${RUN_OPT} --local-config"
fi

if bashio::config.true screenshot ; then
  RUN_OPT="${RUN_OPT} --screenshot"
fi

if bashio::config.true insecure ; then
  RUN_OPT="${RUN_OPT} --insecure"
fi

if bashio::config.true skip_download ; then
  RUN_OPT="${RUN_OPT} --skip-download"
fi

if bashio::config.true keep_output ; then
  RUN_OPT="${RUN_OPT} --keep-output"
fi

TRACE_OPT=""
if bashio::config.true trace ; then
  TRACE_OPT="-m trace --ignore-dir=/usr/lib -t"
fi


cat > "$CONFIG_FILE" <<EOJSON
{
  $config
  "ha_server": "http://supervisor/core",
  "ha_token": "$SUPERVISOR_TOKEN",
  "type": "$TYPE"
}
EOJSON

echo "Generated configuration file '$CONFIG_FILE':"
cat "$CONFIG_FILE"
echo "DISPLAY:'$DISPLAY'"
echo "EVENT CONF:$event_conf"

# ls -lRrt /MetersToHA

EXEC_EVENT_SH="$(realpath .)/execEvent.sh"
cat > "$EXEC_EVENT_SH" <<SCRIPT
#!/bin/bash
#!/usr/bin/with-contenv bashio
{
TARGET_OPT=""
$event_matching
[[ "\$TARGET_OPT" == "" ]] && ( echo "Unrecognized event '\$1'" ; exit 1 )
date
echo "python3 $TRACE_OPT MetersToHA/apps/meters_to_ha/meters_to_ha.py $RUN_OPT -c \"$CONFIG_FILE\" \$TARGET_OPT -r"
python3 $TRACE_OPT MetersToHA/apps/meters_to_ha/meters_to_ha.py $RUN_OPT -c "$CONFIG_FILE" \$TARGET_OPT -r
echo "Done \$(date)"
} >> "$LOGS_FOLDER/m2h_exec.log" 2>&1
SCRIPT
chmod +x "$EXEC_EVENT_SH"

echo "Generated script '$EXEC_EVENT_SH':"
cat "$EXEC_EVENT_SH"

HAEVENT2EXEC=./haevent2exec.py
# shellcheck disable=SC2086,SC2090
"${HAEVENT2EXEC}" --config-json "$CONFIG_FILE" --external-program "$EXEC_EVENT_SH" --log-level="${LOG_LEVEL//\"/\\\"}" $events
