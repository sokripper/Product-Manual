# 开发任务清单 — 服务商索赔管理模块

> 项目类型：web｜生成：2026-07-14
> 冻结版本：v1.0｜冻结 commit：88ed0f850780e2f012229395c4fa6d109c2d04b7
> 来源：docs/PRD.md、docs/Plan.md、docs/api-contracts/接口文档-服务商索赔单.md（S2.8/S2.9）、docs/detail-design/详细设计-服务商索赔单.md（第九节）、docs/db-schema/表结构文档.md + ddl/supplier-claim-mgmt.sql、docs/test-cases/测试用例.xlsx（TC018/TC019）、docs/conventions.md、docs/feature-signoff.md
>
> **本轮范围声明（最小场景验证）**：本轮 Orchestrator 明确只对 **F-CLAIM-05 查看**（服务商索赔单详情 + 分页列表）生成实现任务。其余功能点本轮不开发，登记在本文件末尾「本轮不开发（pass）」一节，保留可溯性，不排任何实现任务。

## 外部服务

| 服务 | 必需 | 配置字段 | Tester 联调权限 | 允许降级 | 状态 |
|------|------|---------|----------------|---------|------|
| 无 | — | — | — | — | 本轮任务均为只读查看（详情 + 分页列表），不触发任何外部服务/Mock 适配层调用（工单库等取数字段已随 seed 数据直接落库，不经过实时 Mock 适配层）。完整外部服务清单见 `docs/Plan.md` 二点五节（EXT-01~06），供后续功能开发使用。 |

## 任务总览

| 编号 | 类型 | 标题 | 功能编码 | 优先级 | 用户门禁 | 状态 | 依赖 |
|------|------|------|---------|--------|---------|------|------|
| T-001 | frontend | 服务商索赔单列表 + 详情 Mock（P01/P02 查看视图） | F-CLAIM-05 | 1 | 是 | awaiting_user | - |
| T-002 | backend | Java 多模块骨架（acme-parent+common+starter+claim 域） | - | 2 | 否 | accepted | T-001 |
| T-003 | backend | 统一响应与全局异常（Result/PageResult/BizException/i18n） | - | 3 | 否 | accepted | T-002 |
| T-004 | backend | 数据库连接（不建表）+ MyBatis-Plus 插件注册 | - | 4 | 否 | accepted | T-003 |
| T-005 | backend | 鉴权骨架（JWT + 拦截器 + 测试 token 签发） | - | 5 | 否 | accepted | T-004 |
| T-006 | backend | 健康检查与启动验证 | - | 6 | 否 | accepted | T-005 |
| T-007 | backend | claim 只读数据模型（entity/mapper） | F-CLAIM-05 | 7 | 否 | accepted | T-006 |
| T-008 | backend | seed 数据（DML，样例索赔单） | F-CLAIM-05 | 8 | 否 | accepted | T-007 |
| T-009 | integration | F-CLAIM-05 查看功能闭环（详情+分页真实 API + 前端联调） | F-CLAIM-05 | 9 | 是 | awaiting_user | T-001、T-008 |

---

## T-001 · 服务商索赔单列表 + 详情 Mock（P01/P02 查看视图）

- **类型**：frontend ｜ **优先级**：1 ｜ **用户门禁(user_gate)**：是
- **功能编码(source_feature)**：F-CLAIM-05 ｜ **依赖**：无
- **状态**：awaiting_user ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：项目 greenfield，先从零搭建前端工程（React + TypeScript + Vite + Ant Design，桌面 Web 后台）。实现两个只读页面：
  1. 服务商索赔单列表（对应原型 P01，只取「查看」相关的表格展示部分，不做搜索栏/批量勾选/新建按钮——这些属于本轮不开发的 F-CLAIM-09/F-CLAIM-10/F-CLAIM-01）；
  2. 服务商索赔单详情（对应原型 P02，只取「查看」相关的只读展示部分，不做编辑/提交/作废/审核/判责表单与按钮——这些属于本轮不开发的 F-CLAIM-02/03/04/06/07/08）。
  列表行点击索赔单号或「查看」进入详情（抽屉或独立页面均可）。Mock 数据放 `frontend/src/mocks/`，字段名/类型/JSON 结构须与 `docs/api-contracts/接口文档-服务商索赔单.md` S2.8（详情）与 S2.9（分页列表）逐字一致，包括 `Result<T>`/`PageResult<T>` 信封、`laborFees`/`partFees`/`otherFees`/`auditRecords`/`attachmentsByType`/`deductOrder` 各分组结构。
  同时完成 `vite.config.ts` 的 `/api` 代理预配置与 `.env`（`VITE_API_BASE_URL=/api`、`VITE_USE_MOCK=true`），避免闭环任务时才补基础设施。
- **验收标准（用户可感知）**：
  1. 用户打开"服务商索赔单列表"页面，看到分页表格，列包含：索赔单号、工单编号、服务商名称、所属区域、索赔类型、主责件归属、申请总金额、单据状态、创建时间，布局与原型 P01 一致
  2. 用户点击列表中任意一行的索赔单号，页面展示该单详情：基本信息（服务商/区域/索赔类型/主责件归属/系数快照/币种/状态等）、工时费/备件/其它费用三张明细表格、按时间先后排列的审核记录与操作时间线、附件按分组展示（维修凭证类/判责类）、责任判定信息（若示例数据有）、关联抵扣单信息（若示例数据有）
  3. 列表页与详情页均不出现"新建/编辑/提交/作废/审核/批量操作/判责录入"等按钮或入口
- **技术检查(technicalChecks)**：
  - `npm run type-check` 通过
  - `npm run lint` 通过
  - `npm run build` 通过
  - Mock 数据格式（字段名/类型/JSON 结构，含 `Result<T>`/`PageResult<T>` 信封）与 `docs/api-contracts/接口文档-服务商索赔单.md` S2.8/S2.9 完全一致
  - `frontend/vite.config.ts` 已配置 `server.proxy['/api']` 指向后端端口（默认 8099，用户门禁验收时可用 `VITE_BACKEND_PROXY_TARGET` 切到 8003）
  - `frontend/.env` 的 `VITE_API_BASE_URL=/api`（相对路径，禁止写完整 URL）、`VITE_USE_MOCK=true`
  - 响应式布局在 1440px / 1920px 桌面分辨率下正常展示
- **前端联调(frontendIntegration)**：required=false
  - pages：- ｜ services：- ｜ realApiEndpoints：- ｜ mockExitCriteria：-
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/frontend.md`
- **备注(notes)**：`[PASS] T-001 - 待用户门禁验收；第 2 次验收 PASS（第 1 次 FAIL 的 auditRecords 未登记枚举值问题已由 Developer 删除伪造条目修复，Tester 真实浏览器复验 008/009/010 三张详情+全量枚举扫描+type-check/lint/build 复跑+回归抽查均确认无误）；详见 .sdd/test-reports/test-T-001.md`

---

## T-002 · Java 多模块骨架（acme-parent+common+starter+claim 域）

- **类型**：backend ｜ **优先级**：2 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：- ｜ **依赖**：T-001
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：在 `<active_project_path>/backend/` 下按 `dev-standards/java/研发工程模块与SDK-Service拆分指南.md` 第 7 节现场搭建：`acme-parent`（父 POM/dependencyManagement）+ `common`（JDK-only）+ `starter`（框架自动配置）+ 首个业务域 `claim/claim-sdk`（api/dto/event/enums/constant/code）+ `claim/claim-service`（扁平分包 `controller/service/mapper/entity/assembler/config/advise/util`；本域本轮只读、无跨域调用/MQ/定时任务，`feign/job/mq` 包可不建，不得因此偏离整体模块拓扑）。启用 ArchUnit / Spotless（或 Checkstyle）/ JaCoCo 插件与门禁，随 `$MVN -q verify` 生效。**禁止**拆子模块、建 `app/domain/infra/provider` 分层包、另起响应包装/异常体系（R-SPLIT-001/002）。
  数据库不新起：直接对接用户已提供的本地 docker 容器 `sdd-mysql`（localhost:3306，database=`supplier_claim`），无需额外 `docker-compose.dev.yml` 起库；如需该文件承载其它本地中间件（本轮无），留空占位说明"MySQL 复用宿主已运行的 sdd-mysql 容器"。
- **验收标准（技术视角，user_gate=否）**：
  1. `backend/` 为 `acme-parent` + `common` + `starter` + `claim/claim-sdk` + `claim/claim-service` 多模块拓扑，符合拆分指南 §7
  2. ArchUnit/Spotless（或 Checkstyle）/JaCoCo 插件已接入，随 `$MVN -q verify` 生效
  3. `mvn -v`/`java -version` 已确认运行时命令（本项目非默认 PATH，须先 `source /Users/koma/.sdd-runtime/env.sh` 才有 java17/mvn）
- **技术检查(technicalChecks)**：
  - `source /Users/koma/.sdd-runtime/env.sh` 后 `$MVN -q verify` 通过（此阶段无业务代码，验空骨架编译 + 门禁插件生效）
  - MyBatis-Plus 分页插件需显式加 `mybatis-plus-jsqlparser` 依赖（3.5.9+ 起从 starter 拆出为独立工件，官方 starter 不再传递依赖，否则注册分页插件时 `NoClassDefFound`）
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/backend-java.md`、`dev-standards/java/Java项目工程规范.md`、`dev-standards/java/研发工程模块与SDK-Service拆分指南.md`、`dev-standards/java/研发自测规范指南.md`
- **备注(notes)**：

---

## T-003 · 统一响应与全局异常（Result/PageResult/BizException/i18n）

- **类型**：backend ｜ **优先级**：3 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：- ｜ **依赖**：T-002
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：`common` 模块实现 `Result<T>`（`success`/`code`/`message`/`data`/`traceId`）、`PageResult<T>`（`list`/`total`/`pageNo`/`pageSize`）、`ErrorCode` 接口、`BizException`；`starter` 模块实现 `@RestControllerAdvice` 全局异常处理器 + i18n 文案解析。**starter 的自动配置类必须注册进 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`**（starter 包名与消费方 `@SpringBootApplication` 扫描基础包天然不同子树，组件扫描覆盖不到，是常见坑）。
- **验收标准（技术视角）**：
  1. `Result<T>`/`PageResult<T>` 字段与 `docs/conventions.md` S4/S4.1 逐字一致
  2. 全局异常处理器真实生效（有 `@SpringBootTest` 验证真实装配链路，不能只靠单测里手动 `new` advice——那样绕开了装配）
  3. 业务码通用错误码（400/401/403/404/409/500）与 `docs/conventions.md` S6 一致
- **技术检查(technicalChecks)**：
  - `$MVN -q verify` 通过
  - 有 `@SpringBootTest` 真实触发一次 advice 路径（非手工 new）
  - 不硬编码密钥
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/backend-java.md`、`dev-standards/java/Java项目工程规范.md`、`dev-standards/java/研发工程模块与SDK-Service拆分指南.md`、`dev-standards/java/研发自测规范指南.md`、`dev-standards/java/接口设计与文档规范指南.md`
- **备注(notes)**：`claim-sdk`/`claim-service` 尚未绑定 JaCoCo 85% 覆盖率门禁（当前均无真实业务类，绑定无意义）；T-007/T-009 落地首个真实业务类后，Tester 须核实这两模块是否已补上 JaCoCo `check` 门禁，详见 .sdd/test-reports/test-T-003.md「关注点复核」

---

## T-004 · 数据库连接（不建表）+ MyBatis-Plus 插件注册

- **类型**：backend ｜ **优先级**：4 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：- ｜ **依赖**：T-003
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：`claim-service` 配置 `application-dev.yml` 连接 docker 容器 `sdd-mysql`（localhost:3306，database=`supplier_claim`，账号 root，真实口令写入 `backend/.env`，不进 yml 明文/不进任何 `docs/**`/`.sdd/**`）；`application-test.yml` 指向独立测试库（库名须与 dev 不同，如 `supplier_claim_test`）。注册 MyBatis-Plus 分页插件（`PaginationInnerInterceptor`）、雪花 ID（`ASSIGN_ID`）、乐观锁插件（`OptimisticLockerInnerInterceptor`，对应 `version` 列）。**不建表**：本项目 20 张表（含本轮涉及的 `claim_order`/`claim_fee_labor`/`claim_fee_part`/`claim_fee_other`/`claim_audit_record`/`claim_deduct_order`/`attachment`）已由 Orchestrator/人执行 `docs/db-schema/ddl/supplier-claim-mgmt.sql` 建好；本任务只验证连接与表存在，缺表则停下报告"需人先执行建表 SQL"，不自建、不写 DDL 补齐。
- **验收标准（技术视角）**：
  1. 能连上 `supplier_claim` 库；上述 7 张目标表已存在（真实 `SHOW TABLES`/`DESC` 验证，非只看实体定义）；如缺表停下报告，不自造表
  2. MyBatis-Plus 分页/乐观锁插件已注册，分页响应映射为 `PageResult<T>` 统一结构
- **技术检查(technicalChecks)**：
  - `$MVN -q verify` 通过
  - 真实连接 `supplier_claim` 库验证目标表存在
  - `application.yml` 无真实口令，敏感配置走 `backend/.env`
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/backend-java.md`、`dev-standards/java/多数据库研发规范-实体与SQL编写指南.md`、`dev-standards/java/研发工程模块与SDK-Service拆分指南.md`、`dev-standards/java/研发自测规范指南.md`
- **备注(notes)**：

---

## T-005 · 鉴权骨架（JWT + 拦截器 + 测试 token 签发）

- **类型**：backend ｜ **优先级**：5 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：- ｜ **依赖**：T-004
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：实现 JWT 工具类（签发/校验）+ `HandlerInterceptor` 路由级拦截（校验 `Authorization: Bearer <token>`，无凭证/无效凭证 401）+ `@RequireRole` 注解权限控制（无权限 403）+ CORS 配置（放行 `localhost`/`127.0.0.1` 的 `5199` 与 `5175`，见 `protocols/development-rules.md` 端口约定）。`JWT_SECRET` 等真实密钥写入 `backend/.env`。
  **本轮无正式登录功能**（`docs/Plan.md` 功能清单未列登录相关功能点，本轮只做 F-CLAIM-05 查看）。为支撑 F-CLAIM-05 详情/列表接口按角色数据范围（`provider_id`/`region`）过滤，以及测试用例 TC019（越权数据范围过滤）的可验证性，额外提供一个**仅 `dev`/`test` profile 开放**的测试 token 签发端点（如 `POST /dev/test-token`，入参 `role`/`providerId`/`region`，出参 JWT），生产 profile 下不注册该端点。这是技术验证脚手架，不是设计正式登录功能，未来正式登录功能设计留待产品后续补齐（记入 notes，非业务 schema 臆造）。
- **验收标准（技术视角）**：
  1. 无 `Authorization` 或 token 无效访问受保护接口返回 401（`Result.success=false`）
  2. 携带有效 token 但角色权限不足返回 403
  3. `/actuator/health` 与 `/dev/test-token`（仅 dev/test profile）在 `excludePathPatterns` 声明，无需 token
  4. CORS 允许 `localhost`/`127.0.0.1` 的 `5199` 与 `5175`
- **技术检查(technicalChecks)**：
  - `$MVN -q verify` 通过
  - `HandlerInterceptor` 对真实业务路由（非未暴露的 actuator 端点）验证 401/403
  - `preHandle` 校验全部通过后才写 `ThreadLocal`，`afterCompletion` 无条件 `clear`（防止校验中途抛异常导致上一请求身份残留到下一请求，线程复用坑）
  - `/dev/test-token` 仅当 `spring.profiles.active` 含 `dev`/`test` 时注册，生产 profile 下路由不存在
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/backend-java.md`、`dev-standards/java/Java项目工程规范.md`、`dev-standards/java/接口设计与文档规范指南.md`、`dev-standards/java/研发自测规范指南.md`
- **备注(notes)**：`claim-sdk`/`claim-service` 仍未绑定 JaCoCo 85% 覆盖率门禁（两模块除测试探针外仍无真实业务类）；T-007 落地首个真实业务类（entity/mapper）后须补 `claim-service` 的 `service` 分支覆盖率门禁，详见 .sdd/test-reports/test-T-005.md「JaCoCo 覆盖率」。`/dev/test-token` 用于 Tester 换取不同 `provider_id`/`region` 的测试 token，验证 T-009 的 TC018（本服务商范围可查）/TC019（越权被过滤）；不是产品需求功能点，不写入 `docs/api-contracts.md`。

---

## T-006 · 健康检查与启动验证

- **类型**：backend ｜ **优先级**：6 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：- ｜ **依赖**：T-005
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：引入 `spring-boot-starter-actuator`，暴露 `/actuator/health`；完成短时启动验证。启动前须 `source backend/.env`（或等价方式）注入 `JWT_SECRET` 等，因为 `spring-boot:run` 不自动读 `.env`，强制占位缺失会导致 Bean 装配抛异常启动失败。
- **验收标准（技术视角）**：
  1. `/actuator/health` 返回 UP
  2. `claim-service` 可用 `$MVN -q -pl claim/claim-service spring-boot:run -Dspring-boot.run.arguments=--server.port=8099` 短时启动成功（Agent/Tester 自动验证端口 8099；用户门禁验收环境端口 8003）
- **技术检查(technicalChecks)**：
  - `$MVN -q verify` 通过
  - 短时启动 + `curl http://localhost:8099/actuator/health` 返回 `{"status":"UP"}`
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/backend-java.md`、`dev-standards/java/研发自测规范指南.md`
- **备注(notes)**：`claim-sdk`/`claim-service` 仍未绑定 JaCoCo 85% 覆盖率门禁（连续 T-002~T-006 五个任务保留此跟踪，两模块除测试探针外仍无真实业务类）；T-007 落地首个真实业务类（entity/mapper）后必须补 `claim-service` 的 `service` 分支覆盖率门禁，不得遗忘，详见 .sdd/test-reports/test-T-006.md

---

## T-007 · claim 只读数据模型（entity/mapper）

- **类型**：backend ｜ **优先级**：7 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：F-CLAIM-05 ｜ **依赖**：T-006
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：在 `claim-service` 的 `entity`/`mapper` 包下，为已建好的 7 张表编写 MyBatis-Plus PO 实体 + Mapper 接口（继承 `BaseMapper`）：`claim_order`、`claim_fee_labor`、`claim_fee_part`、`claim_fee_other`、`claim_audit_record`、`claim_deduct_order`、`attachment`。字段名/类型/长度/审计列**严格对齐** `docs/db-schema/表结构文档.md` 与 `docs/db-schema/ddl/supplier-claim-mgmt.sql` 的实际列名（`create_by`/`created_at`/`update_by`/`updated_at`/`deleted_at`/`version`——**注意不是** `dev-standards/backend-java.md` §5 示例里的 `CREATION_BY`/`CREATION_DATE` 等占位命名，那是通用规约的示例写法，非本项目实际约定，以本项目 db-schema 文档/DDL 为准）。本任务只建只读数据模型，不写 Service 业务查询组装逻辑（组装逻辑放 T-009）。
- **验收标准（技术视角）**：
  1. 7 个 PO 实体与 Mapper 接口存在，字段/类型与已建好表结构逐列一致（真实 `DESC` 对照，非凭记忆/凭文档臆测）
  2. 主键、审计列（`create_by`/`created_at`/`update_by`/`updated_at`/`deleted_at`/`version`）映射正确，`version` 走 `@Version` 乐观锁注解
  3. 简单查询（如按 `id` 查 `claim_order`）可真实命中已建好表返回数据
- **技术检查(technicalChecks)**：
  - `$MVN -q verify` 通过
  - Mapper 与真实库字段核对一致，不出现未登记表列（出现即 FAIL）
  - 所有查询附 `deleted_at IS NULL` 条件（MyBatis-Plus 逻辑删除或显式 Wrapper 条件）
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/backend-java.md`、`dev-standards/java/多数据库研发规范-实体与SQL编写指南.md`、`dev-standards/java/研发工程模块与SDK-Service拆分指南.md`、`dev-standards/java/研发自测规范指南.md`
- **备注(notes)**：权威表结构 `docs/db-schema/表结构文档.md`（S65~S144 区段：`claim_order`/`claim_fee_labor`/`claim_fee_part`/`claim_fee_other`/`claim_audit_record`）+ S238（`claim_deduct_order`）+ S370（`attachment`）。**文档漂移待产品侧登记**（不影响本任务判定，PO 已按真实库/DDL 正确实现）：①`表结构文档.md:129` `claim_fee_other.remark` 应从 255 更正为 500（与 DDL/真实库一致）；②`表结构文档.md:248` `claim_deduct_order.liability_ratio` 默认值应从"0.00"更正为"无默认"（与 DDL/真实库一致）。**强约束**：`claim-service` 的 `jacoco-check`（`pom.xml`）当前阈值占位 0.00（entity 排除+mapper 空体无可插桩代码，暂无 service/controller 业务逻辑，判定合理），**T-009 落地 service/controller 后必须调至研发自测规范指南 §8.3 分层阈值（service≥85%/controller≥70%）并真实通过，否则 T-009 不得 accepted**，详见 .sdd/test-reports/test-T-007.md「重点判断项 B」。

---

## T-008 · seed 数据（DML，样例索赔单）

- **类型**：backend ｜ **优先级**：8 ｜ **用户门禁(user_gate)**：否
- **功能编码(source_feature)**：F-CLAIM-05 ｜ **依赖**：T-007
- **状态**：accepted ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：通过 **DML INSERT**（非 DDL，子智能体禁止执行任何建表/改表语句）向 `supplier_claim` 库插入两张样例索赔单及其关联数据，供 T-009 联调与 TC018/TC019 验收使用：
  - **索赔单 A**：`provider_id`=`PV0001`（服务商名"深圳某服务商有限公司"）、`region`=`华东区/江苏`、`claim_target`=`SELF`、`status`=`PENDING_SETTLE`、`liability_result`=`PROVIDER`（含完整判责字段：`liability_desc`/`liability_ratio`/`liability_by`/`liability_time`，及对应 `claim_deduct_order` 一行）；`claim_fee_labor`/`claim_fee_part`/`claim_fee_other` 各至少 1 行且金额恒等式成立（`apply_total_amount = labor_fee_total + part_mgmt_fee + other_fee_total`）；`claim_audit_record` 覆盖 `CREATE`/`SUBMIT`/区域初审「通过」/业务审核「通过」/判责相关 `OPERATION` 事件（`audit_time` 递增，构成完整时间线）；`attachment` 覆盖 `CLAIM` 与 `LIABILITY` 两个 `biz_type` 分组各至少 1 条（`file_path` 可为占位相对路径，无需真实物理文件，本轮不测下载）。
  - **索赔单 B**：`provider_id`=`PV0002`（与 A 不同的服务商，用于 TC019 越权过滤验证）、`region`=`华南区/广东`、`claim_target`=NULL（尚未区域初审）、`status`=`DRAFT`、无判责字段、无抵扣单；`claim_audit_record` 仅 1 条 `CREATE` 事件；用于验证详情页"最小字段/无判责/无抵扣单"分支。
  - 两单的 `claim_no` 按 `docs/conventions.md` S7 编号规则手工构造示例值（`SPCO-yyyyMMdd-4位流水`），不经取号器（seed 数据非业务流程产生）。
- **验收标准（技术视角）**：
  1. 索赔单 A、B 及其关联明细/审核记录/附件/抵扣单真实存在于 `supplier_claim` 库（真实 `SELECT` 验证，非凭声明）
  2. 覆盖「有判责+有抵扣单+多条审核记录」与「无判责+无抵扣单+单条审核记录」两种展示分支
  3. A、B 分属不同 `provider_id`，满足 TC019 越权测试前置条件
- **技术检查(technicalChecks)**：
  - 真实查询 `supplier_claim` 库验证行数与关键字段值（`apply_total_amount` 恒等式、`audit_time` 升序、`liability_ratio` 范围等）
  - 子智能体仅执行 DML INSERT，不执行任何 DDL/ALTER/DROP/TRUNCATE
- **前端联调(frontendIntegration)**：required=false
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/java/多数据库研发规范-实体与SQL编写指南.md`
- **备注(notes)**：`work_order_id`/`work_order_no`/`main_part_id` 等"待挂载"字段本期无真实工单库，seed 时直接手工填固定示例值（如 `WO20260712000001`/`WO-20260712-001`），不经工单 Mock 适配层——这是 seed 数据的合理简化，不代表新建索赔单业务流程本身已挂载工单库（新建索赔单 F-CLAIM-01 本轮不开发）。判责动作不写 `claim_audit_record`（Tester 已核实 LLD 第八/九/十节三处一致确认，详见 .sdd/test-reports/test-T-008.md）；本任务描述中"判责相关 OPERATION 事件"一句与 LLD 实际不符，属 Planner 任务描述措辞层面的轻微出入，以 LLD 为准，不影响本任务判定，建议后续任务描述引用 LLD 时避免此类过度解读。

---

## T-009 · F-CLAIM-05 查看功能闭环（详情+分页真实 API + 前端联调）

- **类型**：integration ｜ **优先级**：9 ｜ **用户门禁(user_gate)**：是
- **功能编码(source_feature)**：F-CLAIM-05 ｜ **依赖**：T-001、T-008
- **状态**：awaiting_user ｜ **blocked**：false ｜ **retry_count**：0 ｜ **developer**：- ｜ **tester**：-
- **描述**：实现 `claim-service` 的两个真实 GET 端点（权威规格 `docs/detail-design/详细设计-服务商索赔单.md` 第九节 + `docs/api-contracts/接口文档-服务商索赔单.md` S2.8/S2.9）：
  1. `GET /claim/order/{id}`（详情）：装配主档 `claim_order` + 三张费用明细 + `claim_audit_record`（审核记录与 `audit_stage='OPERATION'` 的操作事件，按 `audit_time,id` 升序，构成完整操作时间线）+ `attachment`（按 `biz_type` 分组）+ 判责字段 + `claim_deduct_order`（如有），按角色数据范围（`provider_id`/`region`）过滤，任意状态可查，无状态变更/无副作用。
  2. `GET /claim/order/page`（分页列表）：按 `claimNo`/`workOrderNo`/`providerName`/`region`/`claimType`/`claimTarget`/`status`/`createdAtStart`/`createdAtEnd` 过滤（接口层完整实现，本轮前端 UI 不做搜索交互——筛选栏交互属 F-CLAIM-09，本轮不开发），按角色数据范围过滤，返回 `PageResult<索赔单列表行>`。
  前端列表页与详情页从 Mock 切换到真实 API 调用（`VITE_USE_MOCK=false`），关闭对应 Mock 分支。使用 T-005 提供的测试 token（不同 `provider_id`）完成真实浏览器点击验证 TC018（任意状态查看全量详情，P0）与 TC019（越权数据范围过滤，P2）。
- **验收标准（用户可感知，Tester 逐条验，含 TC018/TC019）**：
  1. 用户使用索赔单 A 所属服务商（`PV0001`）范围的测试 token 打开列表页，看到索赔单 A；点击索赔单号进入详情，页面展示完整信息：基本信息、三张费用明细表、按时间升序排列的审核/操作记录时间线、按分组展示的附件列表、责任判定信息（`PROVIDER`）、关联抵扣单信息；浏览器网络面板显示请求命中真实后端 `/claim/order/{id}` 与 `/claim/order/page`，非 `frontend/src/mocks/*`（对应 TC018）
  2. 用户切换为索赔单 B 所属服务商（`PV0002`）范围的测试 token，列表页只能看到索赔单 B，看不到索赔单 A（数据范围过滤生效，对应 TC019）
  3. 页面不展示 `[Mock]` 字样或任何 Mock 专属提示文案
  4. 刷新页面后详情/列表数据仍来自真实后端（非本地缓存的 Mock 数据）
- **技术检查(technicalChecks)**：
  - `$MVN -q verify` 通过，`service` 分支覆盖率 ≥ 85%
  - 前端 `npm run type-check`/`npm run lint`/`npm run build` 通过
  - `VITE_USE_MOCK=false` 时该功能不再走 Mock 分支（`frontend/src/mocks/*` 未被调用）
  - 真实浏览器（非纯代码论证）完成：用 A 范围 token → 列表 → 点击 → 详情 → 校验字段完整性；切 B 范围 token → 列表只见 B——纯前端交互（列表点击行→详情展示、跨角色数据过滤）必须真实浏览器点击验证，不接受纯代码层论证
  - TC018（P0）/TC019（P2）两条测试用例逐条 PASS，测试报告标注对应用例 ID（测试数据列执行时才填，来源 `docs/test-cases/测试用例.xlsx`「服务商索赔单」sheet）
  - `frontend/vite.config.ts` 的 `/api` 代理仍指向后端端口，若本任务改动过该配置须重启 Vite dev server 复核
  - 详情响应字段与 S2.8 响应参数表逐项核对（含 `laborFees`/`partFees`/`otherFees`/`auditRecords`/`attachmentsByType`/`deductOrder` 各分组字段名与类型）；列表响应字段与 S2.9 逐项核对
  - 金额恒等式 `apply_total_amount = labor_fee_total + part_mgmt_fee + other_fee_total` 在详情响应中成立
- **前端联调(frontendIntegration)**：required=true
  - pages：服务商索赔单列表页（P01 查看视图）、服务商索赔单详情页（P02 查看视图）
  - services：`frontend/src/services/claimOrder.ts`（或等价 service 文件）
  - realApiEndpoints：`GET /claim/order/{id}`、`GET /claim/order/page`
  - mockExitCriteria：`VITE_USE_MOCK=false` 时上述两个页面的数据获取均调用真实后端且返回数据结构与展示正确，无 Mock 残留
- **外部服务(externalServices)**：无
- **规则文件(rules_files)**：`dev-standards/frontend.md`、`dev-standards/backend-java.md`、`dev-standards/java/接口设计与文档规范指南.md`、`dev-standards/java/多数据库研发规范-实体与SQL编写指南.md`、`dev-standards/java/研发自测规范指南.md`
- **备注(notes)**：`[PASS] T-009 - 待用户门禁验收；TC018/TC019 真实浏览器全通过，S2.8/S2.9 字段逐项对齐，claim-service JaCoCo service/controller 均真实 100%（阈值 85%/70%），详见 .sdd/test-reports/test-T-009.md`。**登记待产品侧/后续轮次处理（不阻塞本轮）**：LLD 第二节（新建暂存草稿）要求 DRAFT 建单即写入 `coefficient_snapshot` 与三张费用明细，但 T-008 seed B 单留空——Tester 核实冲突真实存在，根因属 F-CLAIM-01（新建，本轮 pass/超范围）建单逻辑保证与 T-008 seed 真实度的取舍问题，非 F-CLAIM-05 查看端点缺陷（查看端点"任意状态可查"+前端防御渲染已验证对空字段容错正确）；后续排 F-CLAIM-01 任务时一并决策"调整 seed 贴近真实建单"或"LLD 第九节补容错说明"。权威规格 `docs/detail-design/详细设计-服务商索赔单.md` 第九节 +「查看」`docs/api-contracts/接口文档-服务商索赔单.md` S2.8/S2.9；验收基线 `docs/test-cases/测试用例.xlsx`「服务商索赔单」sheet TC018/TC019。F-CLAIM-09（搜索/导出）、F-CLAIM-10（批量审核）对应的前端交互（筛选栏、批量勾选按钮、导出按钮）本轮不开发；`GET /claim/order/page` 的查询参数虽完整实现，但本轮前端不提供筛选 UI，供后续功能复用同一接口。

---

## 本轮不开发（pass）

> 以下 9 个 F-CLAIM 功能点（减法后仅存索赔单模块）本轮不开发，但本轮 Orchestrator 明确只做 F-CLAIM-05 最小场景验证，其余功能点本轮 **不排任何实现任务**，登记状态 `pass / 超范围`，保留可溯性，待后续轮次按 Plan.md 开发顺序建议逐个排入。

| 功能编码 | 功能名称 | 权威设计来源 | 状态 |
|---|---|---|---|
| F-CLAIM-01 | 新建索赔 | detail-design 第二节 / api-contracts S2.1 | pass / 超范围 |
| F-CLAIM-02 | 提交索赔 | detail-design 第三节 / api-contracts S2.3 | pass / 超范围 |
| F-CLAIM-03 | 编辑 | detail-design 第四节 / api-contracts S2.2 | pass / 超范围 |
| F-CLAIM-04 | 作废 | detail-design 第五节 / api-contracts S2.4 | pass / 超范围 |
| F-CLAIM-06 | 区域初审 | detail-design 第六节 / api-contracts S2.5 | pass / 超范围 |
| F-CLAIM-07 | 业务审核 | detail-design 第七节 / api-contracts S2.6 | pass / 超范围 |
| F-CLAIM-08 | 责任判定 | detail-design 第八节 / api-contracts S2.7 | pass / 超范围 |
| F-CLAIM-09 | 搜索/导出 | api-contracts（列表筛选/导出） | pass / 超范围 |
| F-CLAIM-10 | 批量审核 | api-contracts（批量审核） | pass / 超范围 |
