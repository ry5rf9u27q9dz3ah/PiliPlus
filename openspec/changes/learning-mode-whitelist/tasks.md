# Tasks for RFC: 学习模式 — 白名单过滤

本文件把 `proposal.md` 中的高层任务拆成可执行的开发项，包含要新增/修改的文件、简要实现建议、优先级与验收要点。

## 总原则
- 优先实现最小可行功能（MVP）：本地白名单、匹配逻辑、首页入口与管理页、在推荐与搜索结果上做客户端过滤。
- 保持改动小而可回滚：新增服务与页面，尽量不改动后端调用逻辑，仅在接收结果后做过滤。

---

## Task list

1. 创建服务层与本地模型（高优先）
   - 新增文件：`lib/services/learning_mode_service.dart`
     - 内容：`LearningModeService` 单例，包含 `LearningModeSettings` 模型（enabled、upWhitelist、tagWhitelist、keywordWhitelist）、Hive 持久化、`matches(Item)` 方法、Stream/Observable 通知。
     - 验收：有简单单元测试验证读写 settings 与 `matches` 行为。
   - 新增测试：`test/services/learning_mode_service_test.dart`

2. 在推荐/视频数据接收点应用过滤（高优先）
   - 主要文件候选（按发现频率排序）：
     - `lib/http/video.dart` — 推荐列表（recommendListApp / recommendListWeb / related）
       - 建议：在解析或返回结果处调用 `LearningModeService.instance.matches(item)` 进行过滤（若 learning mode enabled）。
     - `lib/http/search.dart` — 搜索推荐（searchRecommend）与 `searchAll` 等
       - 建议：在返回 `SearchRcmdData` / `SearchAllData` 结果后执行过滤。
     - `lib/pages/search/controller.dart` — 前端 controller 使用 `SearchHttp.searchRecommend()` 后，过滤 `recommendData`（或在 HTTP 层统一过滤）
     - `lib/pages/music/video/controller.dart`、`lib/pages/music/video/view.dart` 等：对特定推荐 API 返回结果做同样处理（按需要）
   - 验收：在开启学习模式时，推荐/搜索页面的列表只显示通过 `matches` 的项；关闭时行为不变。

3. 在 UI 层添加入口与管理界面（中优先）
   - 新增组件：`lib/pages/home/learning_mode_button.dart`
     - 建议：在首页 `AppBar` 或工具区放置切换/进入按钮，按钮从 `LearningModeService` 订阅状态实时更新。
   - 新增页面：`lib/pages/settings/learning_mode_page.dart`
     - 功能：管理 UP 白名单、Tag 白名单、关键字白名单；搜索/添加/删除操作；批量导入/导出（可选）。
   - 在路由文件 `lib/router/app_pages.dart` 注册新页面（若使用路由注册）
   - 在视频卡片/弹出菜单添加“加入白名单”快捷动作：`lib/common/widgets/video_popup_menu.dart`（或各卡片文件）
   - 验收：用户可通过首页按钮进入管理页，能添加/删除白名单项，首页流即时反映更改。

4. 设定偏好持久化与默认值（中优先）
   - 修改：`lib/utils/storage_key.dart` / `lib/utils/storage_pref.dart`（或通过 Hive 单独存储）
   - 建议：把学习模式的启用状态与简要统计以 key 存储或使用 Hive Adapter

5. 性能与分页处理（低优先）
   - 初版：在 UI 线程对每页（通常几十条）进行同步过滤；若性能问题再引入 isolate（使用 `compute` 或 `Isolate.spawn`）
   - 在长列表场景添加单元/基准测试（`test/benchmark/`）

6. 测试与文档（高优先）
   - 单元测试：`matches` 逻辑覆盖（包含边界：空白名单、大小写、空字符串、tag 与 up 同时存在）
   - 小部件测试：管理页的添加/删除 UI 流程
   - 手动冒烟：开启学习模式后在首页、搜索页、推荐页验证过滤行为

7. 迭代与扩展（可选）
   - 支持黑名单/hybrid 模式
   - 多设备/云同步（需后端支持/另设计）
   - 在播放器界面增加“临时学习模式”：基于当前 UP / Tag 动态临时白名单

---

## 需要修改/新增的候选代码位置（简短说明）

- 新增：`lib/services/learning_mode_service.dart` — 主实现文件
- 新增：`lib/pages/home/learning_mode_button.dart` — 首页入口组件
- 新增：`lib/pages/settings/learning_mode_page.dart` — 白名单管理 UI
- 修改：`lib/http/video.dart` — 在解析/返回推荐列表时过滤
- 修改：`lib/http/search.dart` — 在返回搜索/推荐结果时过滤
- 修改：`lib/pages/search/controller.dart` — 使用过滤后的 `recommendData`（或在 HTTP 层统一过滤）
- 修改：`lib/common/widgets/video_popup_menu.dart` — 添加“加入学习白名单”操作
- 修改：`lib/router/app_pages.dart` — 注册新页面路由
- 可选：`lib/utils/storage_pref.dart` 或专用 Hive box，持久化设置

每个修改点应尽量保持单一责任：新增服务 + 在列表渲染前统一调用过滤函数，而不是在多个地方复制匹配逻辑。

---

## 优先级建议
- 优先级 P0（必须）：服务与匹配逻辑、在 `lib/http/video.dart` 与 `lib/http/search.dart` 的过滤集成、单元测试
- 优先级 P1：首页入口与白名单管理 UI、视频卡片的快速添加入口、路由注册
- 优先级 P2：性能优化、导入/导出、UI 小部件测试与基准

---

## 估时（粗略）
- MVP（服务 + 集成到推荐与搜索 + 单元测试）：1–2 天
- UI（管理页 + 首页按钮 + 快速添加）：1 天
- 优化与测试：0.5–1 天

---

## 下一步（建议）
选择一个子任务让我实现：
- A: 立即生成 `LearningModeService` 的最小实现 + 单元测试（优先推荐）
- B: 先在代码中把所有需要改动的文件打成 issue 列表（我可以自动创建 `lib/...` 修改草案）

请回复你要先做 A 还是 B，或提供其它优先选择。
