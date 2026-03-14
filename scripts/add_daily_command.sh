#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QUESTIONS_FILE="$REPO_DIR/questions.txt"
BANK_FILE="$REPO_DIR/data/daily_commands_bank.txt"
CATEGORY="DAILY-BOOST"
COUNT="${1:-3}"

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || (( COUNT < 1 )); then
  echo "ERROR: count must be a positive integer"
  exit 1
fi

if [[ ! -f "$QUESTIONS_FILE" ]]; then
  echo "ERROR: questions.txt not found at $QUESTIONS_FILE"
  exit 1
fi

if [[ ! -f "$BANK_FILE" ]]; then
  echo "ERROR: bank file not found at $BANK_FILE"
  exit 1
fi

added=0
added_lines=()

for ((n=1; n<=COUNT; n++)); do
  selected=""

  # find first unused line from bank
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    question="${line%%|*}"
    answer="${line#*|}"

    # exact match for existing QA pair anywhere in questions file
    if grep -Fq "|$question|$answer" "$QUESTIONS_FILE"; then
      continue
    fi

    selected="$line"
    break
  done < "$BANK_FILE"

  if [[ -z "$selected" ]]; then
    break
  fi

  question="${selected%%|*}"
  answer="${selected#*|}"
  printf "\n%s|%s|%s\n" "$CATEGORY" "$question" "$answer" >> "$QUESTIONS_FILE"
  added=$((added + 1))
  added_lines+=("$question|$answer")
done

if (( added == 0 )); then
  echo "NOOP: all daily bank commands already added."
  exit 0
fi

echo "ADDED_COUNT: $added"
for qa in "${added_lines[@]}"; do
  echo "ADDED: $CATEGORY|$qa"
done
