# 开发计划 · 服务商索赔单（聚焦单模块）

> 设计阶段与开发阶段的衔接文件。所有开发进度以本文件为准。
> **范围**：本项目经减法聚焦到**服务商索赔单**一条链（F-CLAIM-01~10）；向欣旺达/结算/付款/编码/配置本轮不设计（其他模块仍在 PRD，但无 LLD/契约）。
> 上游：`docs/PRD.md`（F-CLAIM）、`docs/prototypes/pages/01,02`、`docs/detail-design/详细设计-服务商索赔单.md`、`docs/api-contracts/接口文档-服务商索赔单.md`、`docs/conventions.md`、`docs/db-schema/`。

## 一、功能清单总览

| 序号 | 功能名称 | 一句话描述 | 对应页面 | 优先级 | 状态 |
|------|---------|-----------|---------|--------|------|
| F-CLAIM-01 | 新建索赔 | 关联已完工+保内+**技术审核已过**工单，带出费用/分类列，暂存草稿 | P02 | MVP | 待开发 |
| F-CLAIM-02 | 提交索赔 | 维修凭证必填、A-39 条件必填硬校验、回运校验，进区域初审 | P02 | MVP | 待开发 |
| F-CLAIM-03 | 编辑 | 仅草稿/驳回可编辑，仅其它费用明细可改 | P02 | MVP | 待开发 |
| F-CLAIM-04 | 作废 | 仅草稿可作废 | P02 | MVP | 待开发 |
| F-CLAIM-05 | 查看 | 全状态可查，含审核记录/附件/日志/判责 | P02 | MVP | 待开发 |
| F-CLAIM-06 | 区域初审 | 录索赔对象+SN 预判，通过→待总部审核 | P02/审核弹窗 | MVP | 待开发 |
| F-CLAIM-07 | 业务审核 | 主责件归属决定流向（欣旺达件触发下游生成/外采件进判责） | P02/审核弹窗 | MVP | 待开发 |
| F-CLAIM-08 | 责任判定 | 外采件三项判责，服务商责任自动生成抵扣单，判责留痕 LIABILITY | P02/判责弹窗 | MVP | 待开发 |
| F-CLAIM-09 | 搜索/导出 | 多维筛选、按筛选导出（通用列表导出规格待 E-通用-B2） | P01 | MVP | 待开发 |
| F-CLAIM-10 | 批量审核 | 勾选批量审核（通用批量规格待 E-通用-B1） | P01 | MVP | 待开发 |

> F-CLAIM-07「欣旺达件触发生成向欣旺达单」为**下游触发点**，向欣旺达单本身本轮不在范围（其模块已删）。

## 二、数据契约摘要

> 完整数据契约见 `docs/PRD.md S10` 与 `docs/db-schema/表结构文档.md`（索赔单 9 表：claim_order / claim_fee_labor/part/other / claim_audit_record / claim_deduct_order / claim_coefficient / claim_type_mapping / attachment，四段式，雪花 id + 审计列）；统一响应/接口见 `docs/conventions.md` + `docs/api-contracts/接口文档-服务商索赔单.md`。编号规则见 conventions S7（SPCO/DKD 用 doc_no_sequence）。乐观锁 version 后端维护、不入接口体。
> **建表由人执行**：`ddl/supplier-claim-mgmt.sql`（含 B9/B10/B11 加列，★列变更待审定）、`ddl/doc_no_sequence.sql`（待审定）——均标待研发组长审定后由人执行，子智能体零 DDL。

## 二点五、外部服务与测试权限清单

> 本清单是 PRD A5-3 落定版。本期无需真实外部 Key（全 Mock/待挂载）。状态无「待确认」。

| 服务 | 用途 | 配置项 | MVP 必需 | 缺失策略 | 状态 |
|------|------|--------|----------|----------|------|
| QMS 判责系统（EXT-01） | SN 预判 / 责任判定回传 | 无（人工/Mock，落 claim_audit_record.remark） | 否 | 人工/Mock 适配层 | Mock（已决） |
| 维修工单管理模块（EXT-06） | 带出工单状态/保内/技术审核/维修项目/工时/备件/主责件/分类列(repair_type等)/系数 | 无（Mock 数据集/固定夹具） | 是（取数依赖） | Mock 取数适配层 | Mock/待挂载（已决） |

> 附件：本地磁盘，DB 存相对路径（`ATTACHMENT_ROOT_PATH`）。

## 三、前端开发清单

### 前端技术选型
React + TypeScript + Vite + Ant Design + react-router + Zustand + Axios（`Result<T>` 解包）；ESLint/Prettier/type-check/build 自动验收。

| 序号 | 页面 | 涉及功能 | Mock 数据来源 | 状态 |
|------|------|---------|--------------|------|
| P01 | 服务商索赔单列表 | F-CLAIM-05/09/10 | 接口文档-服务商索赔单 分页/导出 | 待开发 |
| P02 | 服务商索赔单 新建/编辑/详情 | F-CLAIM-01~08 | 接口文档-服务商索赔单 各接口 | 待开发 |
| 弹窗 | 审核/判责录入 | F-CLAIM-06/07/08 | 对应接口 | 待开发 |

### 前端自动验收
- [ ] 页面 UI 与原型 01/02 一致；Mock 数据格式与 api-contracts 一致（`Result<T>`/`PageResult<T>`）；Agent/Tester 自动验收通过。

## 四、后端开发清单

| 序号 | 功能 | 依赖 | 对应接口 | 状态 |
|------|------|------|---------|------|
| B00 | 基础设施（多模块骨架 + Result/异常 + 鉴权拦截器 + DB 连接） | 无 | GET /actuator/health | 待开发 |
| B01 | 单据编码组件（doc_no_sequence 取号 SPCO/DKD，序列表+行锁） | B00 + doc_no_sequence 表已建 | conventions S7（无独立 REST） | 待开发 |
| B02 | 服务商索赔单链（F-CLAIM-01~10） | B00/B01 | 接口文档-服务商索赔单（9 接口） | 待开发 |

### 后端验收规则
- 基础设施按企业多模块拓扑（parent+common+starter+域 sdk/service，见 dev-standards）；禁自建 pom/响应包装/异常体系。
- **建表由人执行、子智能体零 DDL**：claim_order 的 B9 加列、claim_fee_part 的 sale_price、audit_stage 的 LIABILITY 码、doc_no_sequence 建表——均待研发组长审定并由人执行后开发。
- 业务任务须真实联调验收（后端真实 API + 前端 `VITE_USE_MOCK=false`、页面核心操作可用、不展示 `[Mock]`）。
- QMS/工单本期走 Mock 适配层，标 Mock 验收，不得宣称真实外部联调。

## 五、功能详情

> 开发时逐个展开，权威规格见 `docs/detail-design/详细设计-服务商索赔单.md` 与 `docs/api-contracts/接口文档-服务商索赔单.md`。

## 六、开发顺序建议

**阶段1 前端 MVP（Mock）**：P01/P02 用 Mock 完成 → 用户验收 UI/UX。
**阶段2 后端基础设施（自动连续）**：多模块骨架 + Result/异常 + DB 连接（不建表）+ 鉴权；B01 编码组件（依赖 doc_no_sequence 已建）→ `$MVN -q verify` + /actuator/health UP。
**阶段3 逐功能闭环**：F-CLAIM-01 新建 → 02 提交 → 06 区域初审 → 07 业务审核 → 08 判责 →（03 编辑/04 作废/05 查看/09 搜索/10 批量）；每功能=后端真实 API + 前端切真实 + 联调验收。
**阶段4 E2E 回归**：新建→初审→业务审核→判责 全流程走通。
