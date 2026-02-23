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
    mkdir -p "$XDG_CONFIG_HOME"
    
    # Explicitly configure file keyring to ensure persistent, headless operation
    export GOG_KEYRING_PASSWORD="openclaw_internal_keyring_pass"
    gog auth keyring file
    
    # Set credentials using CLI to ensure proper registration
    # Basic validation for common misconfiguration (missing root object)
    if [[ ! "$GOG_OAUTH_CREDENTIALS" =~ \"installed\" && ! "$GOG_OAUTH_CREDENTIALS" =~ \"web\" ]]; then
        echo "[openclaw] WARNING: GOG_OAUTH_CREDENTIALS does not appear to contain the required 'installed' or 'web' wrapper."
        echo "[openclaw] Expected format: { \"installed\": { \"client_id\": \"...\", ... } }"
    fi

    echo "$GOG_OAUTH_CREDENTIALS" | gog auth credentials set -
    
    # Import token using CLI
    echo "$GOG_OAUTH_TOKEN" | gog auth tokens import -

    echo "[openclaw] GOG authentication injected successfully."
    
    # Pre-configure the gog skill so the bot has access to the tools
    echo "[openclaw] Enabling the gog skill in OpenClaw..."
    node /app/openclaw.mjs skills enable gog || true
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
