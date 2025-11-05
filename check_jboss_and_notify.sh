#!/bin/bash

# ================================
# CONFIGURATION
# ================================

JBOSS_PORT=8080
SERVER_NAME=$(hostname)
POWER_AUTOMATE_URL="https://default05e1a00f674a436089659e4350e553.44.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/b717512223a54825b2849f17248a2a0e/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=uWgzRHZsP2Npj0K9lPd4gqXFA81ONbEYVuqWG8zYkaY"

FLAG_FILE="/tmp/jboss_down.flag"

if curl -fs "http://localhost:${JBOSS_PORT}" >/dev/null 2>&1; then
    echo "$(date) - ✅ JBoss is running"
    [ -f "$FLAG_FILE" ] && rm -f "$FLAG_FILE"  # clear flag when recovered
else
    if [ ! -f "$FLAG_FILE" ]; then
        echo "$(date) - ❌ JBoss is DOWN, sending alert"
        touch "$FLAG_FILE"

        STATUS="NOT RUNNING"
        MESSAGE="⚠️ *JBoss is DOWN* on server **$SERVER_NAME** (Port: $JBOSS_PORT)"

        JSON_PAYLOAD=$(cat <<EOF
{
    "status": "$STATUS",
    "server": "$SERVER_NAME",
    "port": $JBOSS_PORT,
    "message": "$MESSAGE"
}
EOF
)

        curl -s -X POST "$POWER_AUTOMATE_URL" \
             -H "Content-Type: application/json" \
             -d "$JSON_PAYLOAD"
    else
        echo "$(date) - ⚠️ JBoss still down (alert already sent)"
    fi
fi
