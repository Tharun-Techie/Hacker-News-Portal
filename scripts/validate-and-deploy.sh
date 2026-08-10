#!/bin/bash
# Validate and Deploy per-feature package.xml
# Usage: ./scripts/validate-and-deploy.sh manifest/package-<feature>.xml [devOrg]
set -e
MANIFEST=${1:-manifest/package-top-stories-tiles.xml}
ORG=${2:-devOrg}
echo "=== Validating $MANIFEST to $ORG (dry-run) ==="
sf project deploy validate -o $ORG -x $MANIFEST --wait 10 --ignore-warnings || sf project deploy start -o $ORG -x $MANIFEST --dry-run --ignore-warnings --wait 10
echo "=== Validation succeeded, deploying $MANIFEST to $ORG ==="
sf project deploy start -o $ORG -x $MANIFEST --ignore-warnings
echo "=== Deploy succeeded for $MANIFEST ==="
