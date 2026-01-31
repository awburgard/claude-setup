#!/bin/bash

# Auto-Dev Project Detection Script
# Analyzes codebase and outputs complexity JSON

set -euo pipefail

# Initialize detection arrays
STACK=()
PATTERNS=()
COMPLEXITY_FACTORS=0

# Detect React
if [[ -f "package.json" ]] && grep -q '"react"' package.json 2>/dev/null; then
  STACK+=("react")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))

  # Check for React ecosystem
  if grep -q '"react-router"' package.json 2>/dev/null || grep -q '"react-router-dom"' package.json 2>/dev/null; then
    PATTERNS+=("react-router")
  fi
  if grep -q '"redux"' package.json 2>/dev/null || grep -q '"@reduxjs/toolkit"' package.json 2>/dev/null; then
    PATTERNS+=("redux")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
  fi
  if grep -q '"zustand"' package.json 2>/dev/null; then
    PATTERNS+=("zustand")
  fi
fi

# Detect Next.js
if [[ -f "package.json" ]] && grep -q '"next"' package.json 2>/dev/null; then
  STACK+=("nextjs")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))
fi

# Detect Expo
if [[ -f "app.json" ]] && grep -q '"expo"' app.json 2>/dev/null; then
  STACK+=("expo")
  PATTERNS+=("mobile")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))

  # Check for Expo Router
  if [[ -f "package.json" ]] && grep -q '"expo-router"' package.json 2>/dev/null; then
    PATTERNS+=("expo-router")
  fi
fi

# Detect React Native (without Expo)
if [[ -f "package.json" ]] && grep -q '"react-native"' package.json 2>/dev/null; then
  if [[ ! " ${STACK[*]} " =~ " expo " ]]; then
    STACK+=("react-native")
    PATTERNS+=("mobile")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))
  fi
fi

# Detect Supabase
if [[ -f "package.json" ]] && grep -q '"@supabase/supabase-js"' package.json 2>/dev/null; then
  STACK+=("supabase")
  PATTERNS+=("baas")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
fi

# Detect TypeScript
if [[ -f "tsconfig.json" ]]; then
  STACK+=("typescript")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
fi

# Detect Node.js backend
if [[ -f "package.json" ]]; then
  if grep -q '"express"' package.json 2>/dev/null; then
    STACK+=("express")
    PATTERNS+=("rest-api")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
  fi
  if grep -q '"fastify"' package.json 2>/dev/null; then
    STACK+=("fastify")
    PATTERNS+=("rest-api")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
  fi
  if grep -q '"nestjs"' package.json 2>/dev/null || grep -q '"@nestjs/core"' package.json 2>/dev/null; then
    STACK+=("nestjs")
    PATTERNS+=("dependency-injection")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))
  fi
fi

# Detect Python
if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
  STACK+=("python")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))

  # Check for Python frameworks
  if [[ -f "requirements.txt" ]]; then
    if grep -qi "django" requirements.txt 2>/dev/null; then
      STACK+=("django")
      PATTERNS+=("mvt")
      COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))
    fi
    if grep -qi "fastapi" requirements.txt 2>/dev/null; then
      STACK+=("fastapi")
      PATTERNS+=("async-api")
      COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
    fi
    if grep -qi "flask" requirements.txt 2>/dev/null; then
      STACK+=("flask")
      COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
    fi
  fi
fi

# Detect Go
if [[ -f "go.mod" ]]; then
  STACK+=("go")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 2))
fi

# Detect Rust
if [[ -f "Cargo.toml" ]]; then
  STACK+=("rust")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 3))
fi

# Detect databases
if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
  if grep -qi "postgres" docker-compose.y* 2>/dev/null; then
    STACK+=("postgresql")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
  fi
  if grep -qi "mysql" docker-compose.y* 2>/dev/null; then
    STACK+=("mysql")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
  fi
  if grep -qi "mongo" docker-compose.y* 2>/dev/null; then
    STACK+=("mongodb")
    COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
  fi
  if grep -qi "redis" docker-compose.y* 2>/dev/null; then
    STACK+=("redis")
  fi
fi

# Check for Prisma ORM
if [[ -f "prisma/schema.prisma" ]]; then
  PATTERNS+=("prisma-orm")
  COMPLEXITY_FACTORS=$((COMPLEXITY_FACTORS + 1))
fi

# Check for testing frameworks
if [[ -f "package.json" ]]; then
  if grep -q '"jest"' package.json 2>/dev/null || grep -q '"vitest"' package.json 2>/dev/null; then
    PATTERNS+=("testing")
  fi
fi
if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null; then
  PATTERNS+=("testing")
fi

# Calculate file counts for complexity
# Use subshell with || true to handle empty grep results with pipefail
TS_FILES=$( (find . -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v node_modules || true) | wc -l | tr -d ' ')
JS_FILES=$( (find . -name "*.js" -o -name "*.jsx" 2>/dev/null | grep -v node_modules || true) | wc -l | tr -d ' ')
PY_FILES=$( (find . -name "*.py" 2>/dev/null | grep -v __pycache__ | grep -v venv || true) | wc -l | tr -d ' ')
GO_FILES=$( (find . -name "*.go" 2>/dev/null || true) | wc -l | tr -d ' ')
RS_FILES=$( (find . -name "*.rs" 2>/dev/null | grep -v target || true) | wc -l | tr -d ' ')

TOTAL_FILES=$((TS_FILES + JS_FILES + PY_FILES + GO_FILES + RS_FILES))

# Calculate complexity score (1-10)
if [[ $TOTAL_FILES -lt 10 ]]; then
  FILE_COMPLEXITY=1
elif [[ $TOTAL_FILES -lt 50 ]]; then
  FILE_COMPLEXITY=2
elif [[ $TOTAL_FILES -lt 100 ]]; then
  FILE_COMPLEXITY=3
elif [[ $TOTAL_FILES -lt 200 ]]; then
  FILE_COMPLEXITY=4
else
  FILE_COMPLEXITY=5
fi

# Final complexity score: file complexity + factors, capped at 10
COMPLEXITY_SCORE=$((FILE_COMPLEXITY + COMPLEXITY_FACTORS))
if [[ $COMPLEXITY_SCORE -gt 10 ]]; then
  COMPLEXITY_SCORE=10
fi

# Build JSON arrays (handle empty arrays properly)
if [[ ${#STACK[@]} -eq 0 ]]; then
  STACK_JSON="[]"
else
  STACK_JSON=$(printf '%s\n' "${STACK[@]}" | jq -R . | jq -s .)
fi

if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  PATTERNS_JSON="[]"
else
  PATTERNS_JSON=$(printf '%s\n' "${PATTERNS[@]}" | jq -R . | jq -s .)
fi

# Output JSON
jq -n \
  --argjson stack "$STACK_JSON" \
  --argjson patterns "$PATTERNS_JSON" \
  --argjson complexity "$COMPLEXITY_SCORE" \
  --argjson total_files "$TOTAL_FILES" \
  --argjson ts_files "$TS_FILES" \
  --argjson js_files "$JS_FILES" \
  --argjson py_files "$PY_FILES" \
  --argjson go_files "$GO_FILES" \
  --argjson rs_files "$RS_FILES" \
  '{
    stack: $stack,
    detected_patterns: $patterns,
    complexity_score: $complexity,
    file_counts: {
      typescript: $ts_files,
      javascript: $js_files,
      python: $py_files,
      go: $go_files,
      rust: $rs_files,
      total: $total_files
    }
  }'
