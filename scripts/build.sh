#!/usr/bin/env bash
# 统一构建入口：根据语言类型执行对应编译
set -euo pipefail

ROOT="${1:-.}"
LANG="${2:-auto}"
OUTPUT_DIR="${3:-./dist}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$LANG" == "auto" ]]; then
  LANG="$("$SCRIPT_DIR/detect-language.sh" "$ROOT")"
fi

echo "==> 项目目录: $ROOT"
echo "==> 检测语言: $LANG"
echo "==> 输出目录: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"
cd "$ROOT"

build_go() {
  echo "==> 构建 Go 项目..."
  go mod download 2>/dev/null || true
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    go build -v -o "$OUTPUT_DIR/app" ./...
  fi
}

build_rust() {
  echo "==> 构建 Rust 项目..."
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    cargo build --release
    cp -r target/release/* "$OUTPUT_DIR/" 2>/dev/null || cp target/release/* "$OUTPUT_DIR/" 2>/dev/null || true
  fi
}

build_java_maven() {
  echo "==> 构建 Java Maven 项目..."
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    mvn -B package -DskipTests
    find . -path "*/target/*.jar" ! -name "*-sources.jar" ! -name "*-javadoc.jar" -exec cp {} "$OUTPUT_DIR/" \;
  fi
}

build_java_gradle() {
  echo "==> 构建 Java Gradle 项目..."
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    if [[ -f "./gradlew" ]]; then
      chmod +x ./gradlew
      ./gradlew build -x test
    else
      gradle build -x test
    fi
    find . -path "*/build/libs/*.jar" -exec cp {} "$OUTPUT_DIR/" \;
  fi
}

build_node() {
  echo "==> 构建 Node.js 项目..."
  if [[ -f "pnpm-lock.yaml" ]]; then
    pnpm install --frozen-lockfile 2>/dev/null || pnpm install
  elif [[ -f "yarn.lock" ]]; then
    yarn install --frozen-lockfile 2>/dev/null || yarn install
  else
    npm ci 2>/dev/null || npm install
  fi
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  elif grep -q '"build"' package.json 2>/dev/null; then
    npm run build
    cp -r dist build out .next "$OUTPUT_DIR/" 2>/dev/null || true
  else
    echo "无 build 脚本，跳过编译"
  fi
}

build_python() {
  echo "==> 构建 Python 项目..."
  if [[ -f "requirements.txt" ]]; then
    pip install -r requirements.txt
  elif [[ -f "pyproject.toml" ]]; then
    pip install . 2>/dev/null || pip install -e .
  fi
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    python -m compileall -q . || true
    echo "Python 项目已安装依赖并完成语法检查"
  fi
}

build_make() {
  echo "==> 使用 Makefile 构建..."
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    make
    cp -r bin "$OUTPUT_DIR/" 2>/dev/null || true
  fi
}

build_cmake() {
  echo "==> 构建 CMake 项目..."
  mkdir -p build && cd build
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    cmake .. && cmake --build . --config Release
    cp -r Release/* "$OUTPUT_DIR/" 2>/dev/null || cp * "$OUTPUT_DIR/" 2>/dev/null || true
  fi
}

build_docker() {
  echo "==> 构建 Docker 镜像..."
  IMAGE_NAME="${IMAGE_NAME:-custom-build:latest}"
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    docker build -t "$IMAGE_NAME" .
  fi
}

build_dotnet() {
  echo "==> 构建 .NET 项目..."
  if [[ -n "${BUILD_CMD:-}" ]]; then
    eval "$BUILD_CMD"
  else
    dotnet restore
    dotnet build --configuration Release
    dotnet publish --configuration Release -o "$OUTPUT_DIR"
  fi
}

case "$LANG" in
  go)           build_go ;;
  rust)         build_rust ;;
  java-maven)   build_java_maven ;;
  java-gradle)  build_java_gradle ;;
  node)         build_node ;;
  python)       build_python ;;
  make)         build_make ;;
  cmake)        build_cmake ;;
  docker)       build_docker ;;
  dotnet)       build_dotnet ;;
  unknown)
    if [[ -n "${BUILD_CMD:-}" ]]; then
      echo "==> 未知语言，执行自定义命令..."
      eval "$BUILD_CMD"
    else
      echo "错误: 无法识别项目类型，请指定 language 或 build_command"
      exit 1
    fi
    ;;
  *)
    echo "错误: 不支持的语言类型: $LANG"
    exit 1
    ;;
esac

echo "==> 构建完成"
