#!/usr/bin/env bash

# linuxtutor - Linux command & concepts tutor (vimtutor-style)
# Uses questions.txt with format:
# CATEGORY|QUESTION|ANSWER
# Lines starting with # or empty are ignored.

QUESTIONS_FILE="${QUESTIONS_FILE:-questions.txt}"

if [[ ! -f "$QUESTIONS_FILE" ]]; then
  echo "ERROR: '$QUESTIONS_FILE' not found."
  echo "Place your questions in $QUESTIONS_FILE in the format:"
  echo "CATEGORY|Question text|exact answer"
  exit 1
fi

# ------------ Helper: trim whitespace ----------------
trim() {
  local s="$*"
  # Leading
  s="${s#"${s%%[![:space:]]*}"}"
  # Trailing
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# ------------ Load and parse questions ----------------
declare -a ALL_LINES
declare -a CATEGORIES

mapfile -t ALL_LINES < "$QUESTIONS_FILE"

# Build unique category list
for line in "${ALL_LINES[@]}"; do
  # Skip comments and blanks
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^# ]] && continue

  # Extract CATEGORY (before first '|')
  category="${line%%|*}"
  category="$(trim "$category")"

  # Skip if somehow empty
  [[ -z "$category" ]] && continue

  # Check if already in CATEGORIES
  found=0
  for c in "${CATEGORIES[@]}"; do
    if [[ "$c" == "$category" ]]; then
      found=1
      break
    fi
  done

  (( found == 0 )) && CATEGORIES+=("$category")
done

if (( ${#CATEGORIES[@]} == 0 )); then
  echo "ERROR: No valid questions found in $QUESTIONS_FILE."
  exit 1
fi

EXIT_TO_MENU=0

# ------------ Category selection ----------------

choose_category() {
  echo "======================================="
  echo "            Linux Tutor"
  echo "======================================="
  echo "Questions file: $QUESTIONS_FILE"
  echo
  echo "Choose a category:"
  local i=1
  for cat in "${CATEGORIES[@]}"; do
    printf "  %2d) %s\n" "$i" "$cat"
    ((i++))
  done

  # Hardcore DevOps mode (special)
  printf "  %2d) %s\n" "$i" "HARDCORE DEVOPS MODE 💀"
  local hardcore_index=$i
  ((i++))

  # ALL mixed
  printf "  %2d) %s\n" "$i" "ALL (mixed)"
  local all_index=$i

  echo

  local choice
  while true; do
    read -rp "Enter number: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if (( choice >= 1 && choice <= i )); then
        break
      fi
    fi
    echo "Invalid choice. Please enter a number from 1 to $i."
  done

  if (( choice == hardcore_index )); then
    SELECTED_CATEGORY="__HARDCORE__"
  elif (( choice == all_index )); then
    SELECTED_CATEGORY="__ALL__"
  else
    SELECTED_CATEGORY="${CATEGORIES[choice-1]}"
  fi
}

# ------------ Collect questions for selected category ----------------

collect_questions() {
  QUESTIONS=()

  for line in "${ALL_LINES[@]}"; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    # Parse category, question, answer
    local cat rest question answer

    cat="${line%%|*}"
    rest="${line#*|}"
    question="${rest%%|*}"
    answer="${rest#*|}"

    cat="$(trim "$cat")"
    question="$(trim "$question")"
    answer="$(trim "$answer")"

    [[ -z "$cat" || -z "$question" || -z "$answer" ]] && continue

    if [[ "$SELECTED_CATEGORY" == "__ALL__" ]]; then
      QUESTIONS+=("$cat|$question|$answer")
    elif [[ "$SELECTED_CATEGORY" == "__HARDCORE__" ]]; then
      [[ "$cat" == "DEVOPS-HARDCORE" ]] && QUESTIONS+=("$cat|$question|$answer")
    else
      [[ "$cat" == "$SELECTED_CATEGORY" ]] && QUESTIONS+=("$cat|$question|$answer")
    fi
  done

  if (( ${#QUESTIONS[@]} == 0 )); then
    echo "No questions found for selected category."
    exit 1
  fi
}

# ------------ Shuffle questions (Fisher–Yates) ----------------

shuffle_questions() {
  local i j tmp
  local n=${#QUESTIONS[@]}
  for ((i = n-1; i > 0; i--)); do
    j=$((RANDOM % (i+1) ))
    tmp="${QUESTIONS[i]}"
    QUESTIONS[i]="${QUESTIONS[j]}"
    QUESTIONS[j]="$tmp"
  done
}

# ------------ Main quiz loop ----------------

run_quiz() {
  local total=${#QUESTIONS[@]}
  local score=0
  local index=1

  echo
  if [[ "$SELECTED_CATEGORY" == "__ALL__" ]]; then
    echo "Category: ALL"
  elif [[ "$SELECTED_CATEGORY" == "__HARDCORE__" ]]; then
    echo "Category: HARDCORE DEVOPS EXAM MODE 💀"
  else
    echo "Category: $SELECTED_CATEGORY"
  fi
  echo "Total questions: $total"
  echo
  echo "Rules:"
  echo "  - Type the exact answer shown in questions.txt"
  echo "  - Type '?' or 'skip' to skip and immediately see the answer"
  echo "  - Type 'end' to quit this lesson and go back to the menu"
  echo "  - You have 3 attempts per question"
  echo "  - After 3 mistakes, the correct answer is shown"
  echo "  - Ctrl+C to quit completely at any time"
  echo
  echo "======================================="
  echo

  for line in "${QUESTIONS[@]}"; do
    local cat rest question correct
    cat="${line%%|*}"
    rest="${line#*|}"
    question="${rest%%|*}"
    correct="${rest#*|}"

    question="$(trim "$question")"
    correct="$(trim "$correct")"

    echo "[$index/$total] $question"

    local attempts=0

    while true; do
      printf "> "
      IFS= read -r answer || { echo; EXIT_TO_MENU=1; return 0; }
      answer="$(trim "$answer")"

      # Skip feature
      if [[ "$answer" == "?" || "$answer" == "skip" ]]; then
        echo "⏭ Skipped."
        echo "   Correct answer: $correct"
        echo
        break
      fi

      # End lesson and go back to menu
      if [[ "$answer" == "end" ]]; then
        echo "🚪 Ending this lesson and returning to the main menu..."
        echo
        EXIT_TO_MENU=1
        return 0
      fi

      # Normal check
      if [[ "$answer" == "$correct" ]]; then
        echo "✅ Correct!"
        ((score++))
        echo
        break
      else
        ((attempts++))
        if (( attempts >= 3 )); then
          echo "❌ Wrong 3 times."
          echo "   Correct answer: $correct"
          echo
          break
        else
          echo "❌ Not quite. Try again. (Attempt $attempts/3)"
        fi
      fi
    done

    ((index++))
  done

  echo "======================================="
  echo "  Finished!"
  echo "  Score: $score / $total"
  if (( total > 0 )); then
    local pct=$(( 100 * score / total ))
    echo "  Accuracy: $pct %"
  fi
  echo "======================================="
}

# ------------ Entry point ----------------

while true; do
  choose_category
  collect_questions
  shuffle_questions

  EXIT_TO_MENU=0
  run_quiz

  # If user typed 'end', just loop and show menu again
  if (( EXIT_TO_MENU == 1 )); then
    continue
  fi

  # Otherwise, ask if they want to choose again or exit
  echo
  read -rp "Play another lesson? (y/n): " again
  case "$again" in
    y|Y|yes|YES)
      echo
      ;;
    *)
      echo "Bye 👋"
      exit 0
      ;;
  esac
done

