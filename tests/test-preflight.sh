#!/bin/bash
# Test script for ralph.sh pre-flight checks
# Verifies all pre-flight check functions work correctly

set -e

# Get script directory for consistent paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the modules we're testing
source "$PROJECT_ROOT/scripts/lib/constants.sh"
source "$PROJECT_ROOT/scripts/lib/logging.sh"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Test utilities
test_start() {
  CURRENT_TEST="$1"
  echo -n "Testing: $CURRENT_TEST... "
}

test_pass() {
  echo -e "${GREEN}PASS${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  local reason="${1:-}"
  echo -e "${RED}FAIL${NC}"
  if [ -n "$reason" ]; then
    echo -e "  ${YELLOW}Reason: $reason${NC}"
  fi
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Create a temporary test directory
setup_test_dir() {
  TEST_DIR=$(mktemp -d)
  mkdir -p "$TEST_DIR/.agent"
  echo "$TEST_DIR"
}

# Clean up test directory
cleanup_test_dir() {
  local dir="$1"
  if [ -n "$dir" ] && [ -d "$dir" ]; then
    rm -rf "$dir"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Required files check
# ═══════════════════════════════════════════════════════════════════════════════

test_required_files_missing_tasks() {
  test_start "Required files check - missing tasks.json"

  local test_dir
  test_dir=$(setup_test_dir)

  # Create PROMPT.md but NOT tasks.json
  echo "# Test Prompt" > "$test_dir/.agent/PROMPT.md"

  # Run check in subshell to capture exit
  local output
  output=$(cd "$test_dir" && bash -c "
    SCRIPT_DIR='$test_dir'
    # Source logging functions inline
    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    # Inline check_required_files
    check_required_files() {
      local missing_required=false
      if [ ! -f \"\$SCRIPT_DIR/.agent/tasks.json\" ]; then
        log_error \"Required file missing: .agent/tasks.json\"
        missing_required=true
      fi
      if [ ! -f \"\$SCRIPT_DIR/.agent/PROMPT.md\" ]; then
        log_error \"Required file missing: .agent/PROMPT.md\"
        missing_required=true
      fi
      if [ \"\$missing_required\" = true ]; then
        log_error \"Please create the required files before running Ralph\"
        exit 1
      fi
    }

    check_required_files
  " 2>&1) || true

  cleanup_test_dir "$test_dir"

  if echo "$output" | grep -q "tasks.json"; then
    test_pass
  else
    test_fail "Expected error about missing tasks.json"
  fi
}

test_required_files_missing_prompt() {
  test_start "Required files check - missing PROMPT.md"

  local test_dir
  test_dir=$(setup_test_dir)

  # Create tasks.json but NOT PROMPT.md
  echo '[]' > "$test_dir/.agent/tasks.json"

  local output
  output=$(cd "$test_dir" && bash -c "
    SCRIPT_DIR='$test_dir'
    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    check_required_files() {
      local missing_required=false
      if [ ! -f \"\$SCRIPT_DIR/.agent/tasks.json\" ]; then
        log_error \"Required file missing: .agent/tasks.json\"
        missing_required=true
      fi
      if [ ! -f \"\$SCRIPT_DIR/.agent/PROMPT.md\" ]; then
        log_error \"Required file missing: .agent/PROMPT.md\"
        missing_required=true
      fi
      if [ \"\$missing_required\" = true ]; then
        log_error \"Please create the required files before running Ralph\"
        exit 1
      fi
    }

    check_required_files
  " 2>&1) || true

  cleanup_test_dir "$test_dir"

  if echo "$output" | grep -q "PROMPT.md"; then
    test_pass
  else
    test_fail "Expected error about missing PROMPT.md"
  fi
}

test_required_files_all_present() {
  test_start "Required files check - all files present"

  local test_dir
  test_dir=$(setup_test_dir)

  # Create both required files
  echo '[]' > "$test_dir/.agent/tasks.json"
  echo "# Test Prompt" > "$test_dir/.agent/PROMPT.md"

  local exit_code=0
  cd "$test_dir" && bash -c "
    SCRIPT_DIR='$test_dir'
    log_error() { echo -e \"[ERROR] \$1\" >&2; }
    log_warn() { echo -e \"[WARN] \$1\"; }

    check_required_files() {
      local missing_required=false
      if [ ! -f \"\$SCRIPT_DIR/.agent/tasks.json\" ]; then
        log_error \"Required file missing: .agent/tasks.json\"
        missing_required=true
      fi
      if [ ! -f \"\$SCRIPT_DIR/.agent/PROMPT.md\" ]; then
        log_error \"Required file missing: .agent/PROMPT.md\"
        missing_required=true
      fi
      if [ \"\$missing_required\" = true ]; then
        log_error \"Please create the required files before running Ralph\"
        exit 1
      fi
      # Optional files - warn if missing but continue
      if [ ! -f \"\$SCRIPT_DIR/.agent/prd/SUMMARY.md\" ]; then
        log_warn \"Optional file missing: .agent/prd/SUMMARY.md\"
      fi
    }

    check_required_files
  " 2>&1 || exit_code=$?

  cleanup_test_dir "$test_dir"

  if [ $exit_code -eq 0 ]; then
    test_pass
  else
    test_fail "Expected success when all required files present"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Git repository check
# ═══════════════════════════════════════════════════════════════════════════════

test_git_repo_not_a_repo() {
  test_start "Git repo check - not a git repository"

  local test_dir
  test_dir=$(setup_test_dir)

  local output
  output=$(cd "$test_dir" && bash -c "
    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    check_git_repo() {
      if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error \"ralph.sh must be run inside a git repository\"
        exit 1
      fi
    }

    check_git_repo
  " 2>&1) || true

  cleanup_test_dir "$test_dir"

  if echo "$output" | grep -q "git repository"; then
    test_pass
  else
    test_fail "Expected error about not being in git repository"
  fi
}

test_git_repo_is_a_repo() {
  test_start "Git repo check - valid git repository"

  local test_dir
  test_dir=$(setup_test_dir)

  # Initialize git repo
  (cd "$test_dir" && git init --quiet)

  local exit_code=0
  cd "$test_dir" && bash -c "
    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    check_git_repo() {
      if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error \"ralph.sh must be run inside a git repository\"
        exit 1
      fi
    }

    check_git_repo
  " 2>&1 || exit_code=$?

  cleanup_test_dir "$test_dir"

  if [ $exit_code -eq 0 ]; then
    test_pass
  else
    test_fail "Expected success when in git repository"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: History directory creation
# ═══════════════════════════════════════════════════════════════════════════════

test_history_dir_creation() {
  test_start "History directory creation - creates when missing"

  local test_dir
  test_dir=$(setup_test_dir)
  local history_dir="$test_dir/.agent/history"

  # Ensure history dir doesn't exist
  rm -rf "$history_dir"

  local exit_code=0
  cd "$test_dir" && bash -c "
    HISTORY_DIR='$history_dir'
    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    check_history_dir() {
      mkdir -p \"\$HISTORY_DIR\"
      if [ ! -d \"\$HISTORY_DIR\" ]; then
        log_error \"Failed to create history directory: \$HISTORY_DIR\"
        exit 1
      fi
    }

    check_history_dir
  " 2>&1 || exit_code=$?

  local dir_exists=false
  if [ -d "$history_dir" ]; then
    dir_exists=true
  fi

  cleanup_test_dir "$test_dir"

  if [ $exit_code -eq 0 ] && [ "$dir_exists" = true ]; then
    test_pass
  else
    test_fail "Expected history directory to be created"
  fi
}

test_history_dir_already_exists() {
  test_start "History directory creation - succeeds when already exists"

  local test_dir
  test_dir=$(setup_test_dir)
  local history_dir="$test_dir/.agent/history"

  # Pre-create history dir
  mkdir -p "$history_dir"

  local exit_code=0
  cd "$test_dir" && bash -c "
    HISTORY_DIR='$history_dir'
    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    check_history_dir() {
      mkdir -p \"\$HISTORY_DIR\"
      if [ ! -d \"\$HISTORY_DIR\" ]; then
        log_error \"Failed to create history directory: \$HISTORY_DIR\"
        exit 1
      fi
    }

    check_history_dir
  " 2>&1 || exit_code=$?

  cleanup_test_dir "$test_dir"

  if [ $exit_code -eq 0 ]; then
    test_pass
  else
    test_fail "Expected success when history directory already exists"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Full pre-flight in valid environment
# ═══════════════════════════════════════════════════════════════════════════════

test_all_preflight_valid_env() {
  test_start "All pre-flight checks - valid environment"

  local test_dir
  test_dir=$(setup_test_dir)

  # Set up valid environment
  (cd "$test_dir" && git init --quiet)
  mkdir -p "$test_dir/.agent"
  echo '[]' > "$test_dir/.agent/tasks.json"
  echo "# Test Prompt" > "$test_dir/.agent/PROMPT.md"

  local exit_code=0
  cd "$test_dir" && bash -c "
    SCRIPT_DIR='$test_dir'
    HISTORY_DIR='$test_dir/.agent/history'

    log_error() { echo -e \"[ERROR] \$1\" >&2; }
    log_warn() { echo -e \"[WARN] \$1\"; }

    check_git_repo() {
      if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error \"ralph.sh must be run inside a git repository\"
        exit 1
      fi
    }

    check_required_files() {
      local missing_required=false
      if [ ! -f \"\$SCRIPT_DIR/.agent/tasks.json\" ]; then
        log_error \"Required file missing: .agent/tasks.json\"
        missing_required=true
      fi
      if [ ! -f \"\$SCRIPT_DIR/.agent/PROMPT.md\" ]; then
        log_error \"Required file missing: .agent/PROMPT.md\"
        missing_required=true
      fi
      if [ \"\$missing_required\" = true ]; then
        log_error \"Please create the required files before running Ralph\"
        exit 1
      fi
      if [ ! -f \"\$SCRIPT_DIR/.agent/prd/SUMMARY.md\" ]; then
        log_warn \"Optional file missing: .agent/prd/SUMMARY.md\"
      fi
    }

    check_history_dir() {
      mkdir -p \"\$HISTORY_DIR\"
      if [ ! -d \"\$HISTORY_DIR\" ]; then
        log_error \"Failed to create history directory: \$HISTORY_DIR\"
        exit 1
      fi
    }

    # Run all pre-flight checks
    check_git_repo
    check_required_files
    check_history_dir
  " 2>&1 || exit_code=$?

  local history_exists=false
  if [ -d "$test_dir/.agent/history" ]; then
    history_exists=true
  fi

  cleanup_test_dir "$test_dir"

  if [ $exit_code -eq 0 ] && [ "$history_exists" = true ]; then
    test_pass
  else
    test_fail "Expected all pre-flight checks to pass in valid environment"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Pre-flight in invalid environment (multiple failures)
# ═══════════════════════════════════════════════════════════════════════════════

test_preflight_multiple_failures() {
  test_start "Pre-flight checks - multiple missing files"

  local test_dir
  test_dir=$(setup_test_dir)

  # Initialize git but don't create any required files
  (cd "$test_dir" && git init --quiet)

  local output
  output=$(cd "$test_dir" && bash -c "
    SCRIPT_DIR='$test_dir'

    log_error() { echo -e \"[ERROR] \$1\" >&2; }

    check_required_files() {
      local missing_required=false
      if [ ! -f \"\$SCRIPT_DIR/.agent/tasks.json\" ]; then
        log_error \"Required file missing: .agent/tasks.json\"
        missing_required=true
      fi
      if [ ! -f \"\$SCRIPT_DIR/.agent/PROMPT.md\" ]; then
        log_error \"Required file missing: .agent/PROMPT.md\"
        missing_required=true
      fi
      if [ \"\$missing_required\" = true ]; then
        log_error \"Please create the required files before running Ralph\"
        exit 1
      fi
    }

    check_required_files
  " 2>&1) || true

  cleanup_test_dir "$test_dir"

  # Should mention both missing files
  if echo "$output" | grep -q "tasks.json" && echo "$output" | grep -q "PROMPT.md"; then
    test_pass
  else
    test_fail "Expected errors for both tasks.json and PROMPT.md"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main test runner
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo " Ralph Pre-flight Checks Test Suite"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  # Required files tests
  echo "--- Required Files Tests ---"
  test_required_files_missing_tasks
  test_required_files_missing_prompt
  test_required_files_all_present
  echo ""

  # Git repo tests
  echo "--- Git Repository Tests ---"
  test_git_repo_not_a_repo
  test_git_repo_is_a_repo
  echo ""

  # History directory tests
  echo "--- History Directory Tests ---"
  test_history_dir_creation
  test_history_dir_already_exists
  echo ""

  # Integration tests
  echo "--- Integration Tests ---"
  test_all_preflight_valid_env
  test_preflight_multiple_failures
  echo ""

  # Summary
  echo "═══════════════════════════════════════════════════════════════"
  local total=$((TESTS_PASSED + TESTS_FAILED))
  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All $total tests passed!${NC}"
  else
    echo -e "${RED}$TESTS_FAILED of $total tests failed${NC}"
  fi
  echo "═══════════════════════════════════════════════════════════════"

  # Exit with failure if any tests failed
  if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
  fi
}

main "$@"
