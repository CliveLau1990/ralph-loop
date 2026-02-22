#!/bin/bash
# Test script for ralph.sh ANSI stripping functionality
# Verifies that strip_ansi and strip_ansi_file correctly remove
# control characters, escape sequences, and caret notation

set -e

# Get script directory for consistent paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the output module which contains strip_ansi functions
source "$PROJECT_ROOT/scripts/lib/constants.sh"
source "$PROJECT_ROOT/scripts/lib/terminal.sh"
source "$PROJECT_ROOT/scripts/lib/output.sh"

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

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Caret notation stripping
# ═══════════════════════════════════════════════════════════════════════════════

test_strip_caret_notation() {
  test_start "Strip caret notation (^D, ^@, ^Z, etc.)"

  local input="^D test ^@ ^Z"
  local expected=" test  "
  local result
  result=$(strip_ansi "$input")

  if [ "$result" = "$expected" ]; then
    test_pass
  else
    test_fail "Expected '$expected', got '$result'"
  fi
}

test_strip_caret_brackets() {
  test_start "Strip caret brackets (^[, ^], ^^, ^_)"

  local input="^[ ^] ^^ ^_ test"
  local expected="    test"
  local result
  result=$(strip_ansi "$input")

  if [ "$result" = "$expected" ]; then
    test_pass
  else
    test_fail "Expected '$expected', got '$result'"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: OSC sequence stripping (window title without ESC prefix)
# ═══════════════════════════════════════════════════════════════════════════════

test_strip_osc_window_title() {
  test_start "Strip OSC window title sequence (0;...] at line start)"

  local input='0;[window title]{"json":"data"}'
  local expected='{"json":"data"}'
  local result
  result=$(strip_ansi "$input")

  if [ "$result" = "$expected" ]; then
    test_pass
  else
    test_fail "Expected '$expected', got '$result'"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Control characters stripping
# ═══════════════════════════════════════════════════════════════════════════════

test_strip_backspace() {
  test_start "Strip backspace characters (0x08)"

  # Create temp file with actual backspace characters
  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)
  printf 'test\b\bclean' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")

  rm -f "$tmp_in" "$tmp_out"

  if [ "$result" = "testclean" ]; then
    test_pass
  else
    test_fail "Expected 'testclean', got '$result'"
  fi
}

test_strip_bel() {
  test_start "Strip BEL character (0x07)"

  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)
  printf 'test\aclean' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")

  rm -f "$tmp_in" "$tmp_out"

  if [ "$result" = "testclean" ]; then
    test_pass
  else
    test_fail "Expected 'testclean', got '$result'"
  fi
}

test_strip_eof() {
  test_start "Strip EOF character (0x04)"

  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)
  printf 'test\x04clean' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")

  rm -f "$tmp_in" "$tmp_out"

  if [ "$result" = "testclean" ]; then
    test_pass
  else
    test_fail "Expected 'testclean', got '$result'"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: ANSI escape sequences stripping
# ═══════════════════════════════════════════════════════════════════════════════

test_strip_color_codes() {
  test_start "Strip ANSI color codes (ESC[...m)"

  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)
  printf '\033[32mgreen\033[0m text' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")

  rm -f "$tmp_in" "$tmp_out"

  if [ "$result" = "green text" ]; then
    test_pass
  else
    test_fail "Expected 'green text', got '$result'"
  fi
}

test_strip_cursor_movement() {
  test_start "Strip ANSI cursor movement (ESC[...H, ESC[...A)"

  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)
  printf '\033[2;5Htest\033[3Amore' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")

  rm -f "$tmp_in" "$tmp_out"

  if [ "$result" = "testmore" ]; then
    test_pass
  else
    test_fail "Expected 'testmore', got '$result'"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Misc terminal sequences
# ═══════════════════════════════════════════════════════════════════════════════

test_strip_u0_sequence() {
  test_start "Strip <u0; sequence"

  local input='{"data":"test"}<u0;'
  local expected='{"data":"test"}'
  local result
  result=$(strip_ansi "$input")

  if [ "$result" = "$expected" ]; then
    test_pass
  else
    test_fail "Expected '$expected', got '$result'"
  fi
}

test_preserve_newlines() {
  test_start "Preserve newlines and regular text"

  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)
  printf 'line1\nline2\nline3' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")
  local expected=$'line1\nline2\nline3'

  rm -f "$tmp_in" "$tmp_out"

  if [ "$result" = "$expected" ]; then
    test_pass
  else
    test_fail "Newlines or text not preserved correctly"
  fi
}

test_preserve_json() {
  test_start "Preserve valid JSON content"

  local input='{"type":"message","content":"Hello world"}'
  local expected='{"type":"message","content":"Hello world"}'
  local result
  result=$(strip_ansi "$input")

  if [ "$result" = "$expected" ]; then
    test_pass
  else
    test_fail "Expected '$expected', got '$result'"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: Real-world scenario
# ═══════════════════════════════════════════════════════════════════════════════

test_real_world_scenario() {
  test_start "Real-world scenario (mixed control chars and JSON)"

  local tmp_in=$(mktemp)
  local tmp_out=$(mktemp)

  # Simulate the actual problematic content from history files
  # ^D (caret+D) + backspaces + OSC sequence + JSON + trailing <u0;
  printf '^D\b\b0;[emoji window title]{"type":"system"}\n<u0;' > "$tmp_in"

  strip_ansi_file "$tmp_in" "$tmp_out"
  local result
  result=$(cat "$tmp_out")
  # Expected: JSON with newline (cat preserves the trailing newline from file)
  local expected='{"type":"system"}'

  rm -f "$tmp_in" "$tmp_out"

  # Use grep to check if result contains expected JSON (handles trailing newline)
  if echo "$result" | grep -qF "$expected"; then
    test_pass
  else
    test_fail "Expected clean JSON output, got '$result'"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main test runner
# ═══════════════════════════════════════════════════════════════════════════════

main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo " Ralph ANSI Stripping Test Suite"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  # Caret notation tests
  echo "--- Caret Notation Tests ---"
  test_strip_caret_notation
  test_strip_caret_brackets
  echo ""

  # OSC sequence tests
  echo "--- OSC Sequence Tests ---"
  test_strip_osc_window_title
  echo ""

  # Control character tests
  echo "--- Control Character Tests ---"
  test_strip_backspace
  test_strip_bel
  test_strip_eof
  echo ""

  # ANSI escape sequence tests
  echo "--- ANSI Escape Sequence Tests ---"
  test_strip_color_codes
  test_strip_cursor_movement
  echo ""

  # Misc tests
  echo "--- Misc Terminal Sequence Tests ---"
  test_strip_u0_sequence
  test_preserve_newlines
  test_preserve_json
  echo ""

  # Real-world tests
  echo "--- Real-world Scenario Tests ---"
  test_real_world_scenario
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
