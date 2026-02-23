#!/bin/bash
set -e

# Sliplane often mounts persistent volumes with root permissions.
# This script ensures that the OpenClaw state directory exists and is accessible.

STATE_DIR=${OPENCLAW_STATE_DIR:-/app/storage}

# Hardcode skip build to prevent runtime compilation in production
export OPENCLAW_SKIP_BUILD=1

# Ensure HOME is set to storage for config discovery
export HOME="$STATE_DIR"

# Print assigned port for visibility
echo "[openclaw] Starting gateway on PORT: ${PORT:-default (8080)}"

echo "[openclaw] Ensuring state directory exists: $STATE_DIR"
mkdir -p "$STATE_DIR"

# Inject GOG OAuth Token & Credentials if provided
if [ -n "$GOG_OAUTH_TOKEN" ] && [ -n "$GOG_OAUTH_CREDENTIALS" ]; then
    echo "[openclaw] Attempting to inject GOG authentication..."
    
    # Run in a subshell to ensure errors are non-fatal to the main boot sequence
    (
        set -e
        # Ensure gogcli configuration folder exists
        export XDG_CONFIG_HOME="$STATE_DIR"
        mkdir -p "$XDG_CONFIG_HOME"
        
        # Explicitly configure file keyring
        export GOG_KEYRING_PASSWORD="openclaw_internal_keyring_pass"
        gog auth keyring file
        
        # Auto-wrap credentials if they are missing the 'installed' or 'web' key
        # We use node to safely parse and wrap the JSON
        CLEAN_CREDS=$(node -e "
            try {
                const creds = JSON.parse(process.env.GOG_OAUTH_CREDENTIALS);
                if (!creds.installed && !creds.web) {
                    console.log(JSON.stringify({ installed: creds }));
                } else {
                    console.log(JSON.stringify(creds));
                }
            } catch (e) {
                process.exit(1);
            }
        ")

        echo "$CLEAN_CREDS" | gog auth credentials set -
        echo "$GOG_OAUTH_TOKEN" | gog auth tokens import -

        echo "[openclaw] GOG authentication injected successfully."
        
        # Pre-configure the gog skill
        node /app/openclaw.mjs skills enable gog || true
    ) || echo "[openclaw] WARNING: GOG authentication setup failed. The server will start, but GOG tools may be unavailable."
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
