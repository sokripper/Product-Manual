# 功能点确认书（feature-signoff）

> 服务商索赔管理模块 · 产品设计冻结合同。开发侧只读消费本合同实现，变更走第四节「变更登记」。
> 依据 templates/feature-signoff.md 与 SKILL.md「产品设计冻结与交接」构建。

## 一、功能点逐条确认

| 功能编号 | 功能名称 | PRD | 原型 | 接口契约 | 详细设计(LLD) | 测试用例数 | 确认状态 |
|---|---|---|---|---|---|---|---|
| F-CLAIM-01 | 新建索赔 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 6 | 已确认 |
| F-CLAIM-02 | 提交索赔 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 5 | 已确认 |
| F-CLAIM-03 | 编辑 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 4 | 已确认 |
| F-CLAIM-04 | 作废 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 2 | 已确认 |
| F-CLAIM-05 | 查看 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 2 | 已确认 |
| F-CLAIM-06 | 区域初审 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 6 | 已确认 |
| F-CLAIM-07 | 业务审核 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 6 | 已确认 |
| F-CLAIM-08 | 责任判定 | PRD.md S4.1 | P02 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 5 | 已确认 |
| F-CLAIM-09 | 搜索/导出 | PRD.md S4.1 | P01 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 3 | 已确认 |
| F-CLAIM-10 | 批量审核 | PRD.md S4.1 | P01 | api-contracts/接口文档-服务商索赔单.md | detail-design/详细设计-服务商索赔单.md | 2 | 已确认 |
| F-XW-01 | 向欣单生成 | PRD.md S4.2 | P04 | api-contracts/接口文档-向欣旺达索赔单.md | detail-design/详细设计-向欣旺达索赔单.md | 11 | 已确认 |
| F-XW-02 | 提交/审批 | PRD.md S4.2 | P04 | api-contracts/接口文档-向欣旺达索赔单.md | detail-design/详细设计-向欣旺达索赔单.md | 22 | 已确认 |
| F-XW-03 | 查看/导出 | PRD.md S4.2 | P03 | api-contracts/接口文档-向欣旺达索赔单.md | detail-design/详细设计-向欣旺达索赔单.md | 5 | 已确认 |
| F-SET-01 | 自动生成结算单 | PRD.md S4.3 | P05 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 9 | 已确认 |
| F-SET-02 | 结算确认/对账 | PRD.md S4.3 | P06 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 14 | 已确认 |
| F-SET-03 | 正数结算-开票 | PRD.md S4.3 | P06 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 8 | 已确认 |
| F-SET-04 | 发票核验/申请付款 | PRD.md S4.3 | P06 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 7 | 已确认 |
| F-SET-05 | 负数强制结算 | PRD.md S4.3 | P06 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 8 | 已确认 |
| F-SET-06 | 闪欣结算 | PRD.md S4.3 | P08 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 11 | 已确认 |
| F-SET-07 | 查询/导出 | PRD.md S4.3 | P05/P07 | api-contracts/接口文档-结算.md | detail-design/详细设计-结算.md | 6 | 已确认 |
| F-PAY-01 | 付款申请生成 | PRD.md S4.4 | P11 | api-contracts/接口文档-付款申请.md | detail-design/详细设计-付款申请.md | 8 | 已确认 |
| F-PAY-02 | 提交/分级审批 | PRD.md S4.4 | P10 | api-contracts/接口文档-付款申请.md | detail-design/详细设计-付款申请.md | 8 | 已确认 |
| F-PAY-03 | 审批/驳回 | PRD.md S4.4 | P10 | api-contracts/接口文档-付款申请.md | detail-design/详细设计-付款申请.md | 6 | 已确认 |
| F-PAY-04 | 付款/作废 | PRD.md S4.4 | P10 | api-contracts/接口文档-付款申请.md | detail-design/详细设计-付款申请.md | 5 | 已确认 |
| F-PAY-05 | 查询/导出/批量审核 | PRD.md S4.4 | P09 | api-contracts/接口文档-付款申请.md | detail-design/详细设计-付款申请.md | 4 | 已确认 |
| F-CFG-01 | 结算周期配置 | PRD.md S4.5 | P12 | 结算配置接口 | detail-design/详细设计-结算基础配置.md | 8 | 已确认 |
| F-CFG-02 | 开票权限白名单配置 | PRD.md S4.5 | P12 | 结算配置接口 | detail-design/详细设计-结算基础配置.md | 0 | ⚠ 待补测试 |
| F-CFG-03 | 付款审批流配置 | PRD.md S4.5 | P12 | 结算配置接口 | detail-design/详细设计-结算基础配置.md | 0 | ⚠ 待补测试 |
| F-CFG-04 | 服务商索赔系数配置 | PRD.md S4.5 | P12 | 结算配置接口 | detail-design/详细设计-结算基础配置.md | 0 | ⚠ 待补测试 |
| F-CODE-01 | 单据编码（跨单据） | PRD.md S10 | — | conventions S7 | detail-design/详细设计-单据编码.md | 7 | 已确认 |

> 合计 **30 功能点**（原 27 + 返工补出 F-CFG-02/03/04）。测试用例 188 条覆盖**原 27 项**；**F-CFG-02/03/04 及本轮返工新增/改动内容（质保金建账 OP0、技术审核前置、操作留痕、A-39 校验等）测试用例尚未重生成**——见第四节，属本次同步的已知欠账。

## 二、冻结元数据

| 项 | 值 |
|---|---|
| 冻结版本 | **v1.1（返工修订）** —— v1.0 已被内容返工取代，见第四节 |
| 冻结时间 | 2026-07-14 |
| 确认人 | 产品经理 + 研发组长（本会话）。**注：本轮 8 条裁决为 mock 默认值（D-索赔-B9/B10/B11、D-向欣-B5、D-结算-B7/B8、D-付款-B6/B7），真实业务待产品正式复核** |
| 冻结 commit | `d7f07555cb73c1634292077d4c2e0dfbdf5e37cd`（v1.1）；v1.0=`88ed0f850780` |
| 状态 | **跑流程态，非生产就绪**：机械门禁 PASS(0 HIGH)，但 3 条 HIGH 裁决为 mock、返工新增内容测试未重生成——正式冻结需真实决策 + 补测试后重签 |

## 三、冻结声明

- 本合同一经冻结，开发侧（Planner/Developer/Tester）**只读消费** PRD / 原型 / api-contracts / detail-design / db-schema / test-cases，不回头改需求或重设计。
- 决策清零：A0 40 + D/E 33 共 73 项全部处置（60 已确认 / 21 已确认(D/E) 更正见决策表 / 10 待文档 / 2 待契约，无 PENDING）。待文档/待契约项为显式挂起，登记如下。

### 显式挂起项（待文档/待契约，开发按已确认 Mock/待挂载边界执行）
- 待文档(10)：含批量审核语义细化(E-通用-B1)、配置字段级校验(D-配置-B1)、导出通用规格(E-通用-B2)、原型旧态同步(D-付款-B5)等，开发对应功能前回看定稿。
- 待契约(2)：回运单实体归属(D-索赔-B3)、内部责任 OA 转嫁(D-索赔-B6)，外部契约到位后补。
- 外部系统 QMS/财务共享/OA/工单本期 Mock/内建/待挂载（待料清单 EXT-01~06）。

## 四、变更登记

> 冻结后任何设计变更在此登记（变更项 / 影响功能点 / 新版本 / 确认人 / 时间），并重新冻结受影响功能点。

| 变更项 | 影响功能点 | 新版本 | 确认人 | 时间 |
|---|---|---|---|---|
| PRD↔LLD↔schema 完整性反查（5 模块），发现 ~30 内容缺口 | 全模块 | v1.1 | 研发组长 | 2026-07-14 |
| 补齐可派生缺口：技术审核前置回补、A-39 校验、操作留痕、质保金账户 OP0 建账、doc_no_sequence.sql、生效谓词、两处配置详设 | F-CLAIM/F-XW/F-SET/F-PAY/F-CFG | v1.1 | 研发组长 | 2026-07-14 |
| 补出遗漏功能点 F-CFG-02/03/04（原 Plan/LLD 缺），各成一节 | F-CFG-02/03/04 | v1.1 | 研发组长 | 2026-07-14 |
| 8 条需产品裁决项 **mock 默认确认**（跑流程用，真实业务待复核） | D-索赔-B9/B10/B11、D-向欣-B5、D-结算-B7/B8、D-付款-B6/B7 | v1.1 | mock（待产品） | 2026-07-14 |
| F-CLAIM-01「铁证」误判纠正：claim_order 实无 repair_type/vin 列，属 schema 缺列（D-索赔-B9），非 LLD 漏写 | F-CLAIM-01 | v1.1 | 研发组长 | 2026-07-14 |

**尚未闭合（正式重冻前必做）**：① 3 条 HIGH 裁决（D-向欣-B5 外采件金额纳入、D-结算-B7 质保金建账、D-索赔-B9 加列）产品正式定 + 落 schema/LLD/契约实现；② F-CFG-02/03/04 与返工新增内容补测试用例、重跑 G-audit；③ 冻结前重跑 `tools/design-gate` + D3.5 逐条反查。

