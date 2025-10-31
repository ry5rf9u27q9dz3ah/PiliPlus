# 项目概览

## 目的（Purpose）
PiliPlus 是一个基于 Flutter 的多平台媒体与社交服务客户端，目标是提供高性能的音视频播放、流媒体交互与常见应用级功能（登录、分享、离线缓存、播放列表等），并在 Android、iOS、Linux、macOS、Windows 上提供一致的体验。

本规范文件记录项目背景、技术栈、代码/版本/分支约定，以及本仓库的开发、构建与发布流程，供新加入开发者与自动化代理（如 CI / 代码生成助手）参考。

## 受众
- 本仓库的开发者（Android/iOS/桌面/后端协作工程师）
- 自动化系统（CI、Release 脚本、代码质量工具）
- 外部协作伙伴（需要集成 SDK 或接入 API 的团队）

## 技术栈（Tech Stack）
- 框架：Flutter（主代码位于 `lib/`）
- 语言：Dart（项目 `pubspec.yaml` 指定 Dart SDK 范围：`>=3.9.0 <4.0.0`）
- Flutter 版本建议：3.35.7（仓库提及 `.fvmrc`，建议使用 FVM 管理 Flutter 版本）
- 平台：Android / iOS / macOS / Linux / Windows / Web（跨平台）
- 主要依赖示例（非穷尽）：
  - GetX (`get` 包)（主要用于路由与依赖注入）
  - 网络：dio、cookie_jar、dio_http2_adapter
  - 媒体：media_kit、media_kit_video、audio_service
  - 本地存储：hive、path_provider
  - 其它：flutter_inappwebview、cached_network_image、flutter_smart_dialog、flutter_localizations
- 构建与工具链：flutter CLI、build_runner、flutter_lints、flutter_native_splash、flutter_launcher_icons

## 仓库结构速览
仓库中 `lib/` 的主目录布局（常见位置）
- `lib/main.dart` — 应用入口
- `lib/build_config.dart` — 构建/环境配置
- `lib/pages/` — 页面/路由对应的 UI 组件（每个页面一个文件/目录）
- `lib/models/` 与 `lib/models_new/` — 数据模型（序列化、转换逻辑）
- `lib/services/` — 与后端、平台服务交互的层（API client、存储、媒体控制）
- `lib/common/` — 公共控件、常量、主题样式
- `lib/utils/` — 辅助函数、格式化、扩展方法
- `lib/router/` — 路由表与导航包装器
- `lib/plugin/`、`lib/tcp/` — 本地/原生插件或特殊协议实现
- `assets/`, `images/`, `fonts/` — 静态资源
- `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` — 平台工程
- `openspec/` — 规范与变更提案（包括 `AGENTS.md`）
- `change_log/` — 发布说明与历史记录（请在发布时更新）
- `test/` — 单元/小部件测试

## 项目约定与规范（Project Conventions）

### 最小“契约”（Contract）
- 输入：Flutter 源码（`lib/`），资源（`assets/`）和依赖（`pubspec.yaml`）
- 输出：可在目标平台上运行的应用包（APK、IPA、桌面二进制或 Web 包）
- 错误模式：构建失败需明确报错并阻断发布；运行时错误应记录至 `catcher_2`/日志系统并提供复现步骤
- 成功标准：本地开发可运行，CI 通过静态检查和测试，发布产物通过基本冒烟测试

### 代码风格与静态检查
- 使用 `analysis_options.yaml` 与 `flutter_lints`（仓库已包含）作为静态 lint 约定。
- 代码格式化：保持使用 Dart/Flutter 官方格式（`dart format` / `flutter format`）。
- 提交消息：建议使用语义化 Commit（例如 Conventional Commits：`feat:`, `fix:`, `chore:`），并在 PR 描述中引用 issue/需求编号。

### 命名与目录约定
- 页面/界面放在 `lib/pages/`，业务逻辑/服务放在 `lib/services/`，通用模型放在 `lib/models/`。资源按类型放在 `assets/images/`, `assets/fonts/` 等。

### 架构模式
- 代码中常用的模式包括：分层（UI / State / Service / Data），使用 `get` 作为轻量状态与依赖注入工具；网络层集中使用 `dio`，数据缓存使用 `hive`。

### 测试策略
- 单元与小部件测试（`flutter_test`）放在 `test/`。关键业务逻辑应有单元测试。UI 关键路径建议覆盖小部件测试。
- 集成测试（E2E）视需要补充，建议在 CI 中建立冒烟测试流水线。

### Git 工作流与分支策略
- 主分支：`main`（始终保持可发布/可回滚的状态）
- 功能分支：`feature/<短描述>`，修复分支：`fix/<issue>`，热修复：`hotfix/<version>`。
- 合并策略：提交合并前需通过 PR，并至少由一名 reviewer 审查。PR 应包含变更描述、测试说明与影响范围。

### 版本与发布
- 版本号维护于 `pubspec.yaml`（`version: x.y.z+build`），发布时同步更新 `change_log/` 对应条目并在 PR 中说明变更点。
- Android/iOS 的签名、证书、及商店发布使用 `fastlane/`（仓库已有 `fastlane` 目录，建议维护 fastlane 配置）。

## 外部依赖与服务（External Dependencies）
- 第三方包：详见 `pubspec.yaml`。重要依赖包括 media 相关包（media_kit）、网络（dio）、权限与设备信息（permission_handler_*, device_info_plus）等。
- 外部服务：如有后端 API、鉴权服务或第三方 SDK（比如极验 GT3），请在本节列出接入方式、必需的环境变量与测试凭证位置（若有）。

## 重要约束（Important Constraints）
- Flutter/Dart SDK 限制：`pubspec.yaml` 要求 Dart `>=3.9.0 <4.0.0`，并建议使用 Flutter `3.35.7`。
- 本仓库部分依赖来自私人或 Fork 的 Git 仓库（`git:` 依赖）。CI/构建环境必须能访问这些仓库。

## 开发者上手（Developer setup & expectations）
- 推荐使用 FVM 管理 Flutter 版本（仓库提示 `.fvmrc`）。
- 本地开发环境至少应：安装对应 Flutter SDK、运行 `flutter pub get` 获取依赖、并能在目标平台上运行（模拟器/真机/桌面）。

## 质量门（Quality Gates）
- 本地/CI 必做：
  - 静态检查（`flutter analyze` / lints）
  - 代码格式化（`dart format`）
  - 单元/小部件测试（`flutter test`）
  - 构建冒烟（至少构建 APK / macOS app / web bundle 中的一个目标以验证构建链）

## CI / 自动化建议
- 推荐在 CI 中实现：依赖安装、dart/format check、analyze、测试、构建与静态签名（如有私密证书则用安全变量）。若要自动发布，可用 fastlane 与签名凭据配合 CI。

## 本地调试与故障排查要点
- 日志：使用 `logger` 并在重要业务埋点处记录上下文（userId、API path、参数、错误堆栈）。
- 崩溃/异常：使用 `catcher_2` 或远程错误收集以便集中分析。

## 贡献与变更提案流程
- 小改动（文档/样式/小 bug）：直接提交 PR 到 `main` 分支（仍需 reviewers 审核）。
- 大改动或架构调整：请首先在 `openspec/changes/` 下提交 RFC/提案（草案），并在 PR 中引用该提案；变更通过后再实现代码。

## 参考与附录
- 分支、发布与代码规范：参见本文件与 `analysis_options.yaml`、`change_log/`、`openspec/AGENTS.md`。
- 如需快速了解项目结构，请阅读 `lib/` 根目录的 README（如有）。
