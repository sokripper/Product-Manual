# 接口契约 · 通用说明（conventions）

> 服务商索赔管理模块 —— 各模块契约 `docs/api-contracts/接口文档-<模块>.md` 引用本文件，不重复定义统一响应 / 鉴权 / 错误码 / 编号规则。
> 权威源：PRD S15 技术架构蓝图、`dev-standards/java/接口设计与文档规范指南.md S3`、`详细设计-单据编码.md`、`docs/db-schema/表结构文档.md`。

---

## 1. 技术栈与分层

- **后端**：JDK 17 + Spring Boot 3 + MyBatis-Plus + Maven；数据库 MySQL 8。
- **前端**：React + TypeScript + Vite + Ant Design（桌面 Web 后台）。
- **分层**：`Controller（REST，统一 Result/PageResult，接口鉴权 + 数据范围过滤）→ Service（业务编排、状态机流转、金额计算、事务）→ Mapper（MyBatis-Plus）→ MySQL`。
- 核心单据（索赔单 / 结算单 / 付款单）用乐观锁 `version` + 核心操作分布式锁；提交 / 审核 / 结算 / 付款等走数据库事务，异常回滚。

## 2. 认证与鉴权

- **认证**：Bearer Token（JWT），请求头 `Authorization: Bearer <token>`；除登录外所有接口需携带有效 Token。链路追踪头 `X-Trace-Id`，服务端回填 `traceId`。
- **鉴权（RBAC 三级：用户-角色-权限）**：前端按角色渲染菜单 / 按钮；后端接口鉴权（`401` 未登录 / Token 失效、`403` 无权限）+ 数据行级权限过滤（按角色 + 所属机构 / 区域）。
- 乐观锁 `version` 由后端维护，接口请求 / 响应体均不含。

## 3. 基础 URL

> 具体地址由运维在部署时确定，本期未定，占位登记（不猜不编）。

| 环境 | 地址 |
| :--- | :--- |
| 开发 | `<待运维配置>` |
| 测试 | `<待运维配置>` |
| 生产 | `<待运维配置>` |

## 4. 响应结构 `Result<T>`

所有 HTTP 接口统一 `Result<T>` 包装，禁止裸返回对象 / 裸抛异常（`dev-standards S3.1`）：

| 字段 | 类型 | 说明 |
| :--- | :--- | :--- |
| `success` | Boolean | 业务是否成功；前端以此判分支 |
| `code` | String | 业务码：成功 `"0"`；失败 = 错误码（见 S6 / 各模块业务错误码） |
| `message` | String | 提示信息（失败时为可读原因） |
| `data` | T | 业务数据（无返回体时 `null`） |
| `traceId` | String | 链路追踪 ID |

### 4.1 分页 `PageResult<T>`

列表分页统一 `Result<PageResult<T>>`，`data` 为：

| 字段 | 类型 | 说明 |
| :--- | :--- | :--- |
| `list` | T[] | 当前页数据 |
| `total` | Long | 总条数 |
| `pageNo` | Long | 当前页码（从 1 起） |
| `pageSize` | Long | 每页条数 |

## 5. 审计列（所有业务表统一，接口层约定）

落库写操作统一维护：`create_by` / `created_at`（新增时写登录人 + 当前时间）、`update_by` / `updated_at`（更新时写）、`deleted_at`（软删，NULL=未删）、`version`（乐观锁，后端维护）。主键为雪花 ID `VARCHAR(32)`。这些列不在接口请求体出现（`create_by` 等由登录态带入，非前端传参）。

## 6. 通用错误码

`success=false` 时 `code` 取错误码、`message` 给可读原因。通用码如下；各模块**业务专属**错误码在对应契约「错误码」节列出。

| 错误码 | 说明 |
| :--- | :--- |
| `400` | 请求参数错误 / 业务校验不通过 |
| `401` | 未授权，Token 无效或过期 |
| `403` | 禁止访问，权限不足 |
| `404` | 资源不存在 |
| `409` | 状态冲突（乐观锁版本不一致 / 单据状态不允许该操作） |
| `500` | 服务器内部错误 |

## 7. 单据编号规则（跨单据共享，写操作「业务处理逻辑」引用本节）

> 权威源 `详细设计-单据编码.md`。号在各单据「首次落库 INSERT」的同一数据库事务内生成，不预分配、不预留。

**统一格式**：`<前缀>-yyyyMMdd-<4 位日内流水>`，全局唯一。`yyyyMMdd` 取生成时点服务器当日（本期单时区、仅 CNY）；4 位流水按「前缀 + 日期」二维在日内从 `0001` 递增、零填充；跨天由日期段天然区隔、流水重置从 `0001` 起。

| 单据 | 前缀 | 落库列 | 生成时机 |
| :--- | :--- | :--- | :--- |
| 服务商索赔单 | `SPCO` | `claim_order.claim_no` | 新建索赔草稿保存时 |
| 闪欣向欣旺达索赔单 | `SXCO` | `xw_claim_order.claim_no` | 业务审核通过（欣旺达件）逐单自动生成时 |
| 服务商结算单 | `SPJS` | `claim_settle_order.settle_no` | 服务商结算单生成时（settle_type=PROVIDER） |
| 闪欣结算单 | `SXJS` | `claim_settle_order.settle_no` | 闪欣结算单生成时（settle_type=SHANXIN） |
| 付款申请单 | `JSFK` | `payment_apply.apply_no` | 点「申请付款」保存草稿时 |
| 索赔抵扣单 | `DKD` | `claim_deduct_order.deduct_no` | 责任判定=服务商责任自动生成抵扣单时 |

**并发唯一（序列表 + 同事务行锁，D-编码-D1）**：新增序列表 `doc_no_sequence(prefix, seq_date, current_seq)`，唯一键 `uk_prefix_date(prefix, seq_date)`。取号与业务单据 INSERT 同一事务：

1. `INSERT INTO doc_no_sequence(id,prefix,seq_date,current_seq) VALUES(?,?,?,1) ON DUPLICATE KEY UPDATE current_seq=current_seq+1`（InnoDB 行锁串行化同「前缀+日期」取号）。
2. `SELECT current_seq` 读回自增值。
3. 拼装 `编号 = 前缀 + '-' + seq_date + '-' + LPAD(current_seq,4,'0')`。
4. 同事务 INSERT 业务单据写入编号列；业务表唯一索引兜底。

**占号策略（提交成功才占号、回滚退号、无跳号，D-编码-D2）**：业务事务提交 → 占号成立；回滚 → 序列自增随事务回滚、号可复用、无空洞。

**边界（D-编码-B2）**：单前缀单日上限 9999 张；`current_seq>9999` 抛业务异常 + 告警日志、拒绝生成（本期业务量远不及）。扩 5 位须走变更登记。

> `doc_no_sequence` 建表 SQL（`docs/db-schema/ddl/doc_no_sequence.sql`）为待研发组长审定项（单据编码 B-1）；审定并执行前不得建表。
