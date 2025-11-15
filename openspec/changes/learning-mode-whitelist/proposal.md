# RFC: 学习模式 — 白名单过滤（learning-mode-whitelist）

状态：草案

作者：你

创建日期：2025-11-08

## 概述

目标：在客户端添加一种“学习模式”（Learning Mode），允许用户将首页推荐行为切换为白名单过滤模式，只展示用户选定的 up（创作者）、视频标签（tag）等内容。视频推荐列表与搜索结果应使用相同的本地过滤规则。主页面应提供明显的入口按钮切换/进入学习模式。

重要限制：这是纯客户端功能，提案不涉及任何后端改动或服务器端筛选。所有白名单与过滤规则均保存在本地（例如 Hive）或应用内设置中。

## 约束与假设
- 不修改后端 API。
- 仅在客户端侧过滤推荐/搜索/列表数据流。
- 假设服务端仍然返回与当前推荐逻辑一致的原始 item 列表，我们在客户端对其进行过滤和/或重新排序。
- 用户应能方便地添加/删除白名单项以及管理 tag/UP 列表。
- 白名单仅用于学习模式开启时生效；关闭时恢复默认推荐。

## 用户故事
1. 作为一个想专注学习的用户，我希望在首页启用“学习模式”，仅看到我关注的 up 与指定标签的视频。
2. 作为一个用户，我希望能通过主页的入口快速切换学习模式，并能编辑白名单（添加/删除 UP、标签或关键字）。
3. 作为一个用户，当我在搜索或浏览推荐列表时，结果应该遵循相同的白名单过滤规则。

## 功能范围（Scope）
- 客户端本地存储与管理白名单（UP 列表、标签、可选关键字）
- 在首页推荐流中应用白名单过滤
- 在搜索结果与推荐列表（例如频道、播放列表接口返回的列表）中应用同样的白名单规则
- 提供 UI：主页入口按钮、白名单管理界面、快速添加（例如视频/UP/标签卡片上的“加入学习模式白名单”）
- 保持隐私：所有设置仅在设备本地，非同步到云或后端

不在本提案范围：
- 后端过滤或对服务端 API 的修改
- 多设备同步/账号级白名单（可作为后续扩展）

## 数据模型（本地存储）
建议使用 Hive（仓库已包含 Hive 依赖）或其他轻量键值存储。

示例模型（伪结构）:

- LearningModeSettings (单例)：
  - enabled: bool
  - mode: enum {whitelist, blacklist, hybrid}  // 当前我们仅实现 whitelist
  - up_whitelist: List<String> // upId 列表
  - tag_whitelist: List<String> // tag 名称或 id 列表
  - keyword_whitelist: List<String> // 可选关键字白名单
  - createdAt/updatedAt: timestamp

实现注意：使用小写/规范化（trim, lowercase）保存字符串以便匹配。

## 过滤策略（客户端）
- 对于从后端拿到的每个 item（视频/帖子/条目），按下列规则判断是否显示：
  1. 若 LearningModeSettings.enabled 为 false → 不做任何过滤，返回原始列表。
  2. 若 enabled 且 mode==whitelist → 仅当 (item.upId 在 up_whitelist) OR (任一 item.tag 在 tag_whitelist) OR (item.title/description 匹配 keyword_whitelist) 时显示。
  3. 其它场景保留（例如有多种匹配时，仍然显示）。

性能注意：不要在主线程执行大量同步过滤。对长列表（如上百条）在 isolate 中或分页时做过滤；对分页 API，仅过滤当前页并允许预取下一页。

## UI / 交互设计
### 首页入口
- 在首页 AppBar 或侧边栏放置醒目的“学习模式”开关/按钮（图标 + 文案）：
  - 点击按钮打开小弹窗，展示当前模式（开启/关闭）和“管理白名单”快捷入口。
  - 长按或次级菜单可快速进入白名单管理页面。

### 白名单管理页面
- 列表视图：Tab 切换（UP / Tags / 关键字）
- 每项支持：显示名字、来源（手动/卡片快速添加）、删除按钮
- 支持批量导入/导出（JSON 文件）作为备份（可选）
- 对单个视频或 UP 提供“快速加入白名单”的上下文菜单（例如在视频卡片、UP 主页或播放页）

### 交互细节
- 添加白名单项时进行去重与规范化（trim、lowercase）
- 提示用户：学习模式开启后，会使用本地白名单过滤结果，若列表为空将显示“无匹配结果”的空态文案与建议操作（如“打开更多标签”或“关闭学习模式”）

## API / 接口点（客户端）
- LearningModeService
  - enable(), disable(), toggle()
  - addUp(String upId), removeUp(String upId)
  - addTag(String tag), removeTag(String tag)
  - matches(Item item): bool
  - stream/notify: Stream<LearningModeSettings> （供 UI 监听）

- View 层
  - 在推荐流与搜索结果的 Adapter/Controller 中调用 LearningModeService.matches(item) 以决定是否显示
  - 在搜索 API wrapper 中，可在接收到结果后执行过滤：results.where(matches)

## 实现步骤（高层任务）
1. 数据模型与存储：在 `lib/services/learning_mode_service.dart` 实现 Hive model 与持久化逻辑
2. 服务接口：实现 `LearningModeService`，包含 settings 的读写、变更通知、以及匹配逻辑
3. UI：
   - 首页入口组件（`lib/pages/home/learning_mode_button.dart`）
   - 白名单管理页面（`lib/pages/settings/learning_mode_page.dart`）
   - 视频卡片/UP 页面：加入快速添加入口（小图标或菜单）
4. 推荐流集成：在 `lib/services/recommendation_service.dart` 或对应 controller 注入并在渲染前过滤
5. 搜索集成：在搜索结果返回后调用 `matches` 进行过滤
6. 性能：对长列表采用 Isolate 或分页过滤策略；添加简单基准测试（过滤 1k 条数据）
7. 测试：编写单元测试覆盖 `matches` 逻辑与服务读写；小部件测试覆盖管理 UI
8. 文档与 RFC：将该 RFC 放入 `openspec/changes/learning-mode-whitelist/proposal.md`（已创建）并在 PR 中引用

## 验收标准（Acceptance criteria）
- 用户可在首页开启/关闭学习模式
- 用户可管理白名单（添加/删除 UP、标签与关键字）
- 在学习模式开启时，首页推荐、推荐列表及搜索结果仅显示符合白名单规则的内容
- UI 有良好的空态提示与引导
- 所有本地设置仅存于设备（未发送至后端）
- 提供单元测试覆盖核心匹配逻辑

## 兼容性与回滚
- 若学习模式导致严重问题，用户可通过设置或快速入口关闭该模式恢复原推荐行为
- 变更应以 Feature Flag 或渐进发布（客户端版本控制）方式上线以便回滚

## 安全与隐私
- 所有白名单数据仅保存在本地（默认不上传）。如未来需要同步，需另行设计权限与加密策略。

## 任务拆分（可直接用作 Issue 列表）
- [ ] 创建 LearningMode 数据模型与 Hive Adapter
- [ ] 实现 LearningModeService（包含订阅/通知）
- [ ] 编写匹配算法与单元测试
- [ ] 在推荐流处集成过滤逻辑（分页/异步）
- [ ] 在搜索结果处集成过滤逻辑
- [ ] 添加首页入口按钮组件
- [ ] 添加白名单管理页面（UP / Tag / Keyword tabs）
- [ ] 在视频卡片/UP 页面添加快速添加入口
- [ ] 性能优化（Isolate / 分页过滤）
- [ ] 添加 UI 小部件测试
- [ ] 文档、变更日志与 PR 模板引用该 RFC

---

如果你希望我把其中某一部分（例如 `LearningModeService` 的具体 Dart 接口实现草案、Hive Adapter 的示例代码、或首页按钮与管理页面的 UI 草图代码）直接生成为可运行的补丁，我可以继续把相应文件写入仓库。请告诉我想先实现哪个部分，我会把一个最小可行实现（含单元测试）放到仓库里并运行测试。
