#!/bin/bash

STATE_FILE="/tmp/jar_dynamic_state.state"
TEAMS_WEBHOOK_URL= "https://default05e1a00f674a436089659e4350e553.44.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/2e88b251801241168a686be341dd7f3e/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=Fm5qTuQgGEyH_XWip-ZFKfIHOPvBSuUuLgplYuqc8Vw"
HOST=$(hostname)

mkdir -p /tmp

# Initialize state file
if [ ! -f "$STATE_FILE" ]; then
    touch "$STATE_FILE"
fi

# --- Load previous state ---
declare -A PREV_STATE
while IFS="|" read -r jar prev
do
    [ -z "$jar" ] && continue
    PREV_STATE["$jar"]="$prev"
done < "$STATE_FILE"

# --- Detect current running jars dynamically ---
CURRENT_JARS=$(ps -ef | grep ".jar" | grep -v grep | awk '{for(i=8;i<=NF;i++) if($i ~ /\.jar$/) print $i}')

declare -A CURRENT_STATE
for jar in $CURRENT_JARS; do
    CURRENT_STATE["$jar"]="UP"
done

UP_LIST=()
DOWN_LIST=()

# --- Detect UP events ---
for jar in "${!CURRENT_STATE[@]}"; do
    prev="${PREV_STATE[$jar]}"

    # First time appearing OR changed from DOWN → UP
    if [ -z "$prev" ] || [ "$prev" = "DOWN" ]; then
        UP_LIST+=("$jar")
    fi
done

# --- Detect DOWN events ---
for jar in "${!PREV_STATE[@]}"; do
    if [ -z "${CURRENT_STATE[$jar]}" ] && [ "${PREV_STATE[$jar]}" = "UP" ]; then
        DOWN_LIST+=("$jar")
    fi
done

# --- Build NEW state file ---
> "$STATE_FILE.tmp"

for jar in "${!CURRENT_STATE[@]}"; do
    echo "$jar|UP" >> "$STATE_FILE.tmp"
done

for jar in "${!PREV_STATE[@]}"; do
    if [ -z "${CURRENT_STATE[$jar]}" ]; then
        echo "$jar|DOWN" >> "$STATE_FILE.tmp"
    fi
done

mv "$STATE_FILE.tmp" "$STATE_FILE"

# --- Only send Teams message if any changes occur ---
if [ ${#UP_LIST[@]} -eq 0 ] && [ ${#DOWN_LIST[@]} -eq 0 ]; then
    exit 0
fi

# --- Build Teams message content ---
MESSAGE="JAR Status Update from *$HOST*:

"

if [ ${#UP_LIST[@]} -gt 0 ]; then
    MESSAGE+="**🟩 Started / UP:**\n"
    for jar in "${UP_LIST[@]}"; do
        MESSAGE+="• $jar\n"
    done
    MESSAGE+="\n"
fi

if [ ${#DOWN_LIST[@]} -gt 0 ]; then
    MESSAGE+="**🟥 Stopped / DOWN:**\n"
    for jar in "${DOWN_LIST[@]}"; do
        MESSAGE+="• $jar\n"
    done
    MESSAGE+="\n"
fi

# --- Send one combined message ---
curl -s -H "Content-Type: application/json" \
    -d "{\"text\": \"$MESSAGE\"}" \
    "$TEAMS_WEBHOOK_URL" >/dev/null
