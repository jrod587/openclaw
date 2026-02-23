#!/bin/bash
set -e

# Sliplane often mounts persistent volumes with root permissions.
# This script ensures that the OpenClaw state directory exists and is accessible.

STATE_DIR=${OPENCLAW_STATE_DIR:-/app/storage}

echo "[openclaw] Ensuring state directory exists: $STATE_DIR"
mkdir -p "$STATE_DIR"

if [ -n "$GOG_OAUTH_TOKEN" ] && [ -n "$GOG_OAUTH_CREDENTIALS" ]; then
    echo "[openclaw] Injecting GOG OAuth Token & Credentials from environment variables..."
    
    # Ensure gogcli configuration folder exists
    export XDG_CONFIG_HOME="$STATE_DIR"
    mkdir -p "$XDG_CONFIG_HOME/gogcli"
    
    # Write credentials directly to bypassing validation of raw GCP json format
    # gog's internal format is slightly different than raw GCP
    echo "$GOG_OAUTH_CREDENTIALS" > "$XDG_CONFIG_HOME/gogcli/credentials.json"
    
    # Write token variable to a temporary file
    echo "$GOG_OAUTH_TOKEN" > /tmp/gog_token.json
    
    # Explicitly configure file keyring to ensure persistent, headless operation
    export GOG_KEYRING_PASSWORD="openclaw_internal_keyring_pass"
    gog auth keyring file
    
    # Import token using gog
    gog auth tokens import /tmp/gog_token.json

    # Clean up
    rm /tmp/gog_token.json
    
    echo "[openclaw] GOG authentication injected successfully."
fi

# If we are running as root (Sliplane default for some plans), 1
# ensure the state directory is writable by us.
# If we were running as 'node', we would need sudo or to have the volume 
# correctly provisioned. Since Sliplane often runs the container as root
# but then potentially drops privileges or has weird mount ownership,
# we force it here if we are root.

if [ "$(id -u)" = "0" ]; then
    echo "[openclaw] Detected root user, ensuring ownership of $STATE_DIR"
    chown -R root:root "$STATE_DIR"
    chmod -R 755 "$STATE_DIR"
fi

echo "[openclaw] Executing: $@"
exec "$@"
