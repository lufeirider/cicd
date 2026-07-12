# GitHub 自定义编译任意项目

输入 GitHub 仓库地址，自动检测语言并编译 Go / Java / Rust / Node / Python 等项目。

## 快速开始

1. 将本仓库 push 到你的 GitHub
2. 打开 **Actions** → **自定义编译任意项目** → **Run workflow**
3. 填写参数并运行

## 输入参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `repo_url` | 仓库地址（必填） | `https://github.com/golang/example` 或 `golang/example` |
| `branch` | 分支 | `main` |
| `language` | 语言，默认 `auto` 自动检测 | `go`, `rust`, `java-maven` |
| `build_command` | 自定义构建命令（可选） | `make release` |

## 支持的语言

| 语言 | 检测依据 | 默认构建 |
|------|----------|----------|
| Go | `go.mod` | `go build -o dist/app ./...` |
| Rust | `Cargo.toml` | `cargo build --release` |
| Java Maven | `pom.xml` | `mvn package -DskipTests` |
| Java Gradle | `build.gradle` | `./gradlew build -x test` |
| Node.js | `package.json` | `npm run build` |
| Python | `requirements.txt` / `pyproject.toml` | 安装依赖 + 语法检查 |
| Make | `Makefile` | `make` |
| CMake | `CMakeLists.txt` | `cmake && make` |
| Docker | `Dockerfile` | `docker build` |
| .NET | `*.csproj` | `dotnet publish` |

## 使用示例

### 编译 Go 项目

```
repo_url: https://github.com/gin-gonic/gin
branch: master
language: auto
```

### 编译 Rust 项目

```
repo_url: tokio-rs/tokio
branch: master
language: rust
```

### 自定义构建命令

```
repo_url: owner/repo
build_command: CGO_ENABLED=0 go build -ldflags="-s -w" -o app ./cmd/main.go
```

## 本地测试

```bash
# 克隆目标项目
git clone https://github.com/owner/repo /tmp/target

# 检测语言
./scripts/detect-language.sh /tmp/target

# 构建
./scripts/build.sh /tmp/target auto ./dist
```

## 目录结构

```
.
├── .github/workflows/
│   ├── build-remote.yml   # 远程仓库编译（手动触发）
│   └── build-local.yml    # 当前仓库编译
└── scripts/
    ├── detect-language.sh # 语言检测
    └── build.sh           # 统一构建入口
```

## 注意事项

- 编译**私有仓库**需在 Settings → Secrets 添加 `GITHUB_TOKEN` 或 PAT
- 默认分支为 `main`，部分老项目可能是 `master`
- 构建产物可在 Actions 页面的 Artifacts 中下载
