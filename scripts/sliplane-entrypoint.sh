#!/bin/bash
set -e

# Sliplane often mounts persistent volumes with root permissions.
# This script ensures that the OpenClaw state directory exists and is accessible.

STATE_DIR=${OPENCLAW_STATE_DIR:-/app/storage}

echo "[openclaw] Ensuring state directory exists: $STATE_DIR"
mkdir -p "$STATE_DIR"

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
