#!/usr/bin/env bash

set -eo pipefail

if ! command -v fga &> /dev/null; then
  echo "🚫 'fga' command not found. Please make sure it is installed and available in PATH."
  exit 1
fi

INPUT_PATH="${INPUT_PATH:-.}"

if [ ! -e "$INPUT_PATH" ]; then
  echo "🚫 Given path '$INPUT_PATH' does not exist."
  exit 1
fi

echo -e "\033[1m📂 Searching tests in path: '$INPUT_PATH'...\033[0m"

FOUND_FILES=$(find "$INPUT_PATH" -name "*.fga.yaml" -type f)
if [ -z "$FOUND_FILES" ]; then
  FILE_COUNT=0
else
  FILE_COUNT=$(echo "$FOUND_FILES" | grep -c '^')
fi

if [ "$FILE_COUNT" -eq 0 ]; then
  echo -e "⏭️ Skipping tests as \033[1mno files were found\033[0m..."
  exit 0
fi

printf "🔎 Found \033[1m%d file(s)\033[0m to run tests\n" "$FILE_COUNT"
echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

EXIT_CODE=0
PASSED_COUNT=0
FAILED_COUNT=0
FAILED_FILES=()

for FILE in $FOUND_FILES; do
  if [ -f "$FILE" ]; then
    set +e
    OUTPUT=$(fga model test --tests "$FILE" 2>&1)
    TESTS_RESULT=$?
    set -e

    if [ $TESTS_RESULT -ne 0 ]; then
        echo -e "\033[1;31m\xe2\x9c\x97 Failed $FILE\033[0m"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_FILES+=("$FILE")
        EXIT_CODE=1
    else
        echo -e "\033[1;32m\xe2\x9c\x93 Passed $FILE\033[0m"
        PASSED_COUNT=$((PASSED_COUNT + 1))
    fi

    echo "$OUTPUT" | sed 's/^/    /'
  fi
done

echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

echo -e "\033[1m📊 Test Files Summary:\033[0m"
echo -e "    \033[1;32m✓ Passed: $PASSED_COUNT\033[0m"
echo -e "    \033[1;31m✗ Failed: $FAILED_COUNT\033[0m"

if [ $FAILED_COUNT -gt 0 ]; then
  echo -e "\n\033[1;31m❌ Failed test files:\033[0m"
  for FAILED in "${FAILED_FILES[@]}"; do
    echo -e "    • $FAILED"
  done
fi

exit $EXIT_CODE
