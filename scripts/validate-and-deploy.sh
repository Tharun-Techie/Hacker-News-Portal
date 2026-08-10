#!/bin/bash
# Validate and Deploy per-feature package.xml
# Usage: ./scripts/validate-and-deploy.sh manifest/package-<feature>.xml [devOrg]
# Ensures Apex tests run on every deployment (fixes skipped tests)
set -e
MANIFEST=${1:-manifest/package-top-stories-tiles.xml}
ORG=${2:-devOrg}
echo "=== Validating $MANIFEST to $ORG (dry-run) ==="

# Extract test class names from manifest (convention: *Test)
TEST_CLASSES=$(grep -o '<members>[^<]*Test</members>' "$MANIFEST" | sed -E 's/.*<members>(.*)<\/members>/\1/' | tr '\n' ' ' | xargs || true)
TEST_ARGS=""
for tc in $TEST_CLASSES; do
  TEST_ARGS="$TEST_ARGS -t $tc"
done

if [ -n "$TEST_CLASSES" ]; then
  echo "Detected tests in manifest: $TEST_CLASSES"
  TEST_LEVEL_ARGS="-l RunSpecifiedTests $TEST_ARGS"
else
  echo "No tests in manifest - using RunLocalTests to ensure org coverage"
  TEST_LEVEL_ARGS="-l RunLocalTests"
fi

# Validate with tests (previously skipped)
# shellcheck disable=SC2086
sf project deploy validate -o "$ORG" -x "$MANIFEST" --wait 10 --ignore-warnings $TEST_LEVEL_ARGS || sf project deploy start -o "$ORG" -x "$MANIFEST" --dry-run --ignore-warnings --wait 10 $TEST_LEVEL_ARGS
echo "=== Validation succeeded, deploying $MANIFEST to $ORG ==="
# shellcheck disable=SC2086
sf project deploy start -o "$ORG" -x "$MANIFEST" --ignore-warnings $TEST_LEVEL_ARGS --wait 10
echo "=== Deploy succeeded for $MANIFEST ==="
