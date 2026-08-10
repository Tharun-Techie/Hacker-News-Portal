#!/bin/bash
# Deploy per-feature package.xml (direct deployment, no validation / no tests)
# Usage: ./scripts/validate-and-deploy.sh manifest/package-<feature>.xml [devOrg]
set -e
MANIFEST=${1:-manifest/package-top-stories-tiles.xml}
ORG=${2:-devOrg}
echo "=== Deploying $MANIFEST to $ORG ==="
sf project deploy start -o "$ORG" -x "$MANIFEST" --ignore-warnings --wait 10
echo "=== Deploy succeeded for $MANIFEST ==="
