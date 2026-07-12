#!/usr/bin/env bash
# 自动检测项目语言/构建类型
set -euo pipefail

ROOT="${1:-.}"

detect() {
  # Makefile 优先：很多 Go/Rust 项目用 Makefile 作为标准构建入口
  if [[ -f "$ROOT/Makefile" ]] || [[ -f "$ROOT/makefile" ]] || [[ -f "$ROOT/GNUmakefile" ]]; then
    echo "make"
  elif [[ -f "$ROOT/go.mod" ]]; then
    echo "go"
  elif [[ -f "$ROOT/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$ROOT/pom.xml" ]]; then
    echo "java-maven"
  elif [[ -f "$ROOT/build.gradle" ]] || [[ -f "$ROOT/build.gradle.kts" ]]; then
    echo "java-gradle"
  elif [[ -f "$ROOT/package.json" ]]; then
    echo "node"
  elif [[ -f "$ROOT/requirements.txt" ]] || [[ -f "$ROOT/pyproject.toml" ]] || [[ -f "$ROOT/setup.py" ]]; then
    echo "python"
  elif [[ -f "$ROOT/CMakeLists.txt" ]]; then
    echo "cmake"
  elif [[ -f "$ROOT/Dockerfile" ]]; then
    echo "docker"
  elif compgen -G "$ROOT/*.csproj" > /dev/null || compgen -G "$ROOT/**/*.csproj" > /dev/null 2>&1; then
    echo "dotnet"
  else
    echo "unknown"
  fi
}

detect
