#!/usr/bin/env bash

# linuxtutor - Linux command & concepts tutor (vimtutor-style)
# Uses questions.txt with format:
# CATEGORY|QUESTION|ANSWER|SOURCE(optional)
# Lines starting with # or empty are ignored.

QUESTIONS_FILE="${QUESTIONS_FILE:-questions.txt}"
STATS_FILE="${STATS_FILE:-$HOME/.linuxturtor_stats}"

if [[ ! -f "$QUESTIONS_FILE" ]]; then
  echo "ERROR: '$QUESTIONS_FILE' not found."
  echo "Place your questions in $QUESTIONS_FILE in the format:"
  echo "CATEGORY|Question text|exact answer|source(optional)"
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

# Bash 3.x (macOS default) doesn't support mapfile, so use while-read.
while IFS= read -r line || [[ -n "$line" ]]; do
  ALL_LINES+=("$line")
done < "$QUESTIONS_FILE"

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

# ------------ Game state ----------------
XP=0
LEVEL=1
TOTAL_CORRECT=0
TOTAL_QUESTIONS=0
BEST_STREAK=0
PLAY_DAYS=0
LAST_PLAY_DATE=""
SESSION_HEARTS=3

save_stats() {
  cat > "$STATS_FILE" <<EOF
XP=$XP
LEVEL=$LEVEL
TOTAL_CORRECT=$TOTAL_CORRECT
TOTAL_QUESTIONS=$TOTAL_QUESTIONS
BEST_STREAK=$BEST_STREAK
PLAY_DAYS=$PLAY_DAYS
LAST_PLAY_DATE=$LAST_PLAY_DATE
EOF
}

load_stats() {
  if [[ -f "$STATS_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$STATS_FILE" || true
  fi

  local today
  today="$(date +%F)"
  if [[ "${LAST_PLAY_DATE:-}" != "$today" ]]; then
    PLAY_DAYS=$((PLAY_DAYS + 1))
    LAST_PLAY_DATE="$today"
    save_stats
  fi
}

level_from_xp() {
  # 100xp per level (simple and motivating)
  echo $(( XP / 100 + 1 ))
}

rank_title() {
  if (( LEVEL >= 25 )); then echo "🐉 Shell Shogun";
  elif (( LEVEL >= 18 )); then echo "🧠 Command Ninja";
  elif (( LEVEL >= 12 )); then echo "⚔️ Terminal Samurai";
  elif (( LEVEL >= 7 )); then echo "🛡️ Linux Ranger";
  elif (( LEVEL >= 3 )); then echo "🥷 Junior Hacker";
  else echo "🌱 Newbie Adventurer"; fi
}

award_xp() {
  local gained="$1"
  XP=$((XP + gained))
  local new_level
  new_level="$(level_from_xp)"
  if (( new_level > LEVEL )); then
    LEVEL=$new_level
    echo "🎉 LEVEL UP! You are now Lv.$LEVEL ($(rank_title))"
  fi
}

show_badges() {
  echo "Badges:"
  (( TOTAL_CORRECT >= 10 )) && echo "  🥉 10 Correct - Bronze Brain"
  (( TOTAL_CORRECT >= 50 )) && echo "  🥈 50 Correct - Silver Shell"
  (( TOTAL_CORRECT >= 100 )) && echo "  🥇 100 Correct - Gold Grep"
  (( TOTAL_CORRECT >= 250 )) && echo "  👑 250 Correct - Terminal King"
}

# ------------ Welcome screen ----------------
show_welcome_page() {
  clear

  local RESET="\033[0m"
  local C1="\033[38;5;213m"  # pink
  local C2="\033[38;5;219m"  # soft magenta
  local C3="\033[38;5;117m"  # mellow blue
  local C4="\033[38;5;121m"  # mint
  local C5="\033[38;5;228m"  # pastel yellow
  local C6="\033[38;5;216m"  # peach

  echo
  printf "${C1}   ██████╗ ${C2}██╗  ██╗${C3} █████╗ ${C4}███████╗${C5}██████╗ ${C6}██╗${RESET}\n"
  printf "${C2}  ██╔═══██╗${C3}██║ ██╔╝${C4}██╔══██╗${C5}██╔════╝${C6}██╔══██╗${C1}██║${RESET}\n"
  printf "${C3}  ██║   ██║${C4}█████╔╝ ${C5}███████║${C6}█████╗  ${C1}██████╔╝${C2}██║${RESET}\n"
  printf "${C4}  ██║   ██║${C5}██╔═██╗ ${C6}██╔══██║${C1}██╔══╝  ${C2}██╔══██╗${C3}██║${RESET}\n"
  printf "${C5}  ╚██████╔╝${C6}██║  ██╗${C1}██║  ██║${C2}███████╗${C3}██║  ██║${C4}██║${RESET}\n"
  printf "${C6}   ╚═════╝ ${C1}╚═╝  ╚═╝${C2}╚═╝  ╚═╝${C3}╚══════╝${C4}╚═╝  ╚═╝${C5}╚═╝${RESET}\n"
  echo
  printf "${C2}                 🌈  Welcome back, legend.  🌈${RESET}\n"
  printf "${C3}              mellow mode: ON • chaos mode: optional${RESET}\n"
  echo

  # tiny dramatic pause if interactive
  if [[ -t 0 ]]; then
    read -rp "Press Enter to open LinuxTutor RPG... " _
  fi
}

# ------------ Category selection ----------------

choose_category() {
  echo "======================================="
  echo "         LinuxTutor RPG Mode"
  echo "======================================="
  echo "Questions file: $QUESTIONS_FILE"
  echo "Player: Lv.$LEVEL $(rank_title) | XP: $XP | Best Streak: $BEST_STREAK | Days: $PLAY_DAYS"
  echo
  echo "Choose a category:"
  echo "   1) Linux 101"
  echo "   2) Linux 102"
  echo "   3) Linux 201"
  echo "   4) Linux 202"
  echo "   5) Linux 301"
  echo "   6) Linux 302"
  echo "   7) Docker 😍"
  echo "   8) Terraform"
  echo "   9) Kubernetes"
  echo "  10) Git"
  echo "  11) Cloud"
  echo

  local choice
  while true; do
    read -rp "Enter number: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= 11 )); then
      break
    fi
    echo "Invalid choice. Please enter a number from 1 to 11."
  done

  case "$choice" in
    1) SELECTED_CATEGORY="LINUX101" ;;
    2) SELECTED_CATEGORY="LINUX102" ;;
    3) SELECTED_CATEGORY="LINUX201" ;;
    4) SELECTED_CATEGORY="LINUX202" ;;
    5) SELECTED_CATEGORY="LINUX301" ;;
    6) SELECTED_CATEGORY="LINUX302" ;;
    7) SELECTED_CATEGORY="DOCKER" ;;
    8) SELECTED_CATEGORY="TERRAFORM" ;;
    9) SELECTED_CATEGORY="KUBERNETES" ;;
    10) SELECTED_CATEGORY="GIT" ;;
    11)
      echo
      echo "Choose cloud provider:"
      echo "  1) AWS"
      echo "  2) GCP"
      echo "  3) OCI"
      local cloud_choice
      while true; do
        read -rp "Enter provider number: " cloud_choice
        if [[ "$cloud_choice" =~ ^[0-9]+$ ]] && (( cloud_choice >= 1 && cloud_choice <= 3 )); then
          break
        fi
        echo "Invalid choice. Please enter 1, 2, or 3."
      done
      case "$cloud_choice" in
        1) SELECTED_CATEGORY="AWS" ;;
        2) SELECTED_CATEGORY="GCP" ;;
        3) SELECTED_CATEGORY="OCI" ;;
      esac
      ;;
  esac
}

# ------------ Collect questions for selected category ----------------

collect_questions() {
  QUESTIONS=()

  for line in "${ALL_LINES[@]}"; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^# ]] && continue

    # Parse category, question, answer, optional source
    local cat question answer source
    IFS='|' read -r cat question answer source <<< "$line"

    cat="$(trim "$cat")"
    question="$(trim "$question")"
    answer="$(trim "$answer")"
    source="$(trim "${source:-}")"

    [[ -z "$cat" || -z "$question" || -z "$answer" ]] && continue

    case "$SELECTED_CATEGORY" in
      LINUX101|LINUX102|LINUX201|LINUX202|LINUX301|LINUX302|DOCKER|TERRAFORM|KUBERNETES|GIT|AWS|GCP|OCI)
        [[ "$cat" == "$SELECTED_CATEGORY" ]] && QUESTIONS+=("$cat|$question|$answer|$source")
        ;;
    esac
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
  local streak=0
  local hearts=$SESSION_HEARTS

  echo
  case "$SELECTED_CATEGORY" in
    LINUX101) echo "Category: Linux 101" ;;
    LINUX102) echo "Category: Linux 102" ;;
    LINUX201) echo "Category: Linux 201" ;;
    LINUX202) echo "Category: Linux 202" ;;
    LINUX301) echo "Category: Linux 301" ;;
    LINUX302) echo "Category: Linux 302" ;;
    DOCKER) echo "Category: Docker 😍" ;;
    TERRAFORM) echo "Category: Terraform" ;;
    KUBERNETES) echo "Category: Kubernetes" ;;
    GIT) echo "Category: Git" ;;
    AWS) echo "Category: Cloud / AWS" ;;
    GCP) echo "Category: Cloud / GCP" ;;
    OCI) echo "Category: Cloud / OCI" ;;
    *) echo "Category: $SELECTED_CATEGORY" ;;
  esac
  echo "Total questions: $total"
  echo
  echo "Game Rules:"
  echo "  - Type the exact answer shown in questions.txt"
  echo "  - Type '?' or 'skip' to skip (costs 1 heart)"
  echo "  - Type 'end' to quit this lesson and go back to the menu"
  echo "  - You have 3 attempts per question"
  echo "  - Correct answer gives XP (+combo bonus by streak)"
  echo "  - Wrong 3 times costs 1 heart"
  echo "  - Hearts this run: $hearts"
  echo "  - Ctrl+C to quit completely at any time"
  echo
  echo "======================================="
  echo

  for line in "${QUESTIONS[@]}"; do
    local cat question correct source
    IFS='|' read -r cat question correct source <<< "$line"

    question="$(trim "$question")"
    correct="$(trim "$correct")"
    source="$(trim "${source:-}")"

    echo "[$index/$total] ❤️ $hearts | 🔥 $streak  :: $question"

    local attempts=0

    while true; do
      printf "> "
      IFS= read -r answer || { echo; EXIT_TO_MENU=1; return 0; }
      answer="$(trim "$answer")"

      # Skip feature
      if [[ "$answer" == "?" || "$answer" == "skip" ]]; then
        hearts=$((hearts - 1))
        streak=0
        ((TOTAL_QUESTIONS++))
        echo "⏭ Skipped. (-1 ❤️)"
        echo "   Correct answer: $correct"
        [[ -n "$source" ]] && echo "   📚 Reference: $source"
        echo
        if (( hearts <= 0 )); then
          echo "💀 Game Over! Out of hearts."
          EXIT_TO_MENU=1
          SESSION_HEARTS=3
          return 0
        fi
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
        ((score++))
        ((streak++))
        ((TOTAL_CORRECT++))
        ((TOTAL_QUESTIONS++))
        (( streak > BEST_STREAK )) && BEST_STREAK=$streak

        local bonus=$(( streak / 3 ))
        local gained=$(( 10 + bonus ))
        award_xp "$gained"

        echo "✅ Correct! +${gained}XP (streak: $streak)"
        [[ -n "$source" ]] && echo "   📚 Reference: $source"
        echo
        break
      else
        ((attempts++))
        if (( attempts >= 3 )); then
          hearts=$((hearts - 1))
          streak=0
          ((TOTAL_QUESTIONS++))
          echo "❌ Wrong 3 times. (-1 ❤️)"
          echo "   Correct answer: $correct"
          [[ -n "$source" ]] && echo "   📚 Reference: $source"
          echo
          if (( hearts <= 0 )); then
            echo "💀 Game Over! Out of hearts."
            EXIT_TO_MENU=1
            SESSION_HEARTS=3
            return 0
          fi
          break
        else
          echo "❌ Not quite. Try again. (Attempt $attempts/3)"
        fi
      fi
    done

    ((index++))
  done

  echo "======================================="
  echo "  Stage Clear!"
  echo "  Score: $score / $total"
  if (( total > 0 )); then
    local pct=$(( 100 * score / total ))
    echo "  Accuracy: $pct %"
  fi
  echo "  Player: Lv.$LEVEL ($(rank_title)) | XP: $XP"
  echo "  Best Streak: $BEST_STREAK"
  show_badges
  echo "======================================="

  save_stats
}

# ------------ Entry point ----------------

load_stats
show_welcome_page

while true; do
  choose_category
  collect_questions
  shuffle_questions

  EXIT_TO_MENU=0
  run_quiz
  save_stats

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

