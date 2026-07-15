# Stitch 提示词 — 剩余页面（保内维修索赔域）

> 用法：**每个页面**都把下面的「SHARED DESIGN HEADER」贴在最前，再接对应「PAGE PROMPT」，一起粘到 stitch.withgoogle.com 生成。生成后 Download zip → 解压到 `docs/prototypes/NN-页面名/`。
> 关键：所有 UI 文案/字段/状态/示例数据一律**简体中文**，域为「保内维修索赔」（工时费/备件管理费/维修工单/责任判定），不是物流理赔。

---

## SHARED DESIGN HEADER（每个提示词前都要贴）

```
You are designing a screen for an enterprise back-office "服务商保内维修索赔管理系统" (warranty repair claim management). Desktop web, viewport 1440×900.

DESIGN SYSTEM (must follow exactly, keep consistent across screens):
- Layout: fixed left sidebar nav (208px) with items 理赔管理 / 结算管理 / 支付管理 / 系统配置; top bar with breadcrumb + notification + help + user avatar. Content area on background #F0F2F5 with white cards (#FFFFFF, 1px #D9D9D9 border, 8px radius, subtle shadow), 24px page margins.
- Colors: Primary #1677FF (primary actions, active nav, "processing" statuses); Success #52C41A (已结算/审批通过/已付款); Warning #FAAD14 (已驳回/需关注); Error #FF4D4F (已拒绝/已作废/驳回); text #000000E0 / secondary #00000073; border #D9D9D9. Color is functional only, never decorative.
- Typography: system sans-serif (Inter / PingFang SC / Microsoft YaHei). Money & 单号 use monospace for column alignment. Table header 13px weight 600 on #FAFAFA.
- Density: HIGH. Tables use compact rows (8px vertical padding), right-side fixed "操作" action column, and a sticky bottom "合计" row for financial tables.
- Status Tags: pill shape. Draft/终态灰=gray outline; processing=blue tinted bg + solid border; success=solid green; error=solid red.
- No gradients, no emoji icons, no decorative illustrations. Shadows only for functional depth.
- ALL text in Simplified Chinese. Sample data must be warranty-repair domain (服务商/维修工单/工时费/备件/责任判定), NOT logistics.

CLAIM STATUS ENUM (服务商索赔单, 9 states): 草稿 / 待区域初审 / 待总部审核 / 待责任判定 / 待结算 / 已驳回 / 已拒绝 / 已结算 / 已作废.
SETTLE STATUS ENUM (结算单): 待确认 / 待对账 / 待开票 / 待核验 / 已核验 / 待强制结算 / 已结算 / 已作废.
PAYMENT STATUS ENUM (付款申请单): 待提交 / 审批中 / 审批通过 / 审批驳回 / 已付款 / 已作废.
```

---

## PAGE 05 · 服务商索赔单 详情页（P02）→ `05-服务商索赔单详情`

```
PAGE: 服务商索赔单详情页. Breadcrumb 理赔管理 / 服务商索赔单详情. A read/edit detail page composed of stacked cards, with a fixed bottom action bar.

TOP: 单据头 card showing 索赔单编号 "SPCO-20260712-0007" (monospace) + 状态 pill "待责任判定" (blue processing), right side 申请总金额 "¥3,860.00" large + 币种 人民币.

CARD 1 基础信息: two-column read-only fields — 关联工单 "WO-20260710-3391"（下拉选择器样式，标注：仅本服务商【已完工】保内维修工单）, 索赔类型 "保内维修"（只读，工单带出）, 工单类型 "乘用车-三电维修-电池包", 服务商名称 "华东-苏州星辉服务中心"（只读）, 所属区域 "华东区/江苏"（只读）, 创建人 "李售后", 创建时间 "2026-07-12 10:20".

CARD 2 费用明细: three sub-tables with 合计 row.
- 工时费明细: columns 项目名称/工时数/工时单价/金额. rows: 电池包更换 2.0 / ¥180 / ¥360; 高压检测 1.5 / ¥160 / ¥240. 
- 备件明细: columns 备件名称/备件索赔金额(显示¥0.00)/备件管理费. rows: 动力电池包 ¥0.00 / ¥3,000.00; 高压连接器 ¥0.00 / ¥120.00.
- 其它费用明细: columns 费用类型/金额/备注, editable(物流费可改). row: 物流费 ¥140.00 / 旧件回运顺丰. 
- Card footer 合计: 工时费合计 ¥600.00 + 备件管理费 ¥3,120.00 + 其它费用合计 ¥140.00 = 申请总金额 ¥3,860.00 (auto, read-only).

CARD 3 附件资料: three upload groups (维修凭证附件 required, 旧件资料附件, 其他说明附件), show 2 image thumbnails + 1 PDF chip each with 预览/删除, note "仅支持图片、PDF".

CARD 4 审核记录: timeline/list, columns 审核阶段/审核人/审核时间/审核结果/驳回原因, newest first. rows: 区域初审 / 王区域 / 2026-07-12 11:05 / 通过 / —; (下方) 索赔对象=欣旺达件 项目编码 XW-PJ-0091.

CARD 5 责任判定: fields 责任判定结果(pill, options 供应商责任/服务商责任/内部责任), 责任判定说明, 责任方承担比例, 判定人, 判定时间, 已发起供应商索赔(供应商责任显示), 已发起服务商抵扣(服务商责任显示). Show a primary button 【判责结果录入】(质量人员可见, 审核通过后显示).

BOTTOM FIXED BAR: buttons rendered by 状态×角色 — 【保存】【提交】(草稿/已驳回), 【作废】(草稿), 【审核】(待审批, 区域/索赔员), 【判责结果录入】(待责任判定, 质量部), 【返回】.

Also render an OPEN MODAL overlay 【判责结果录入】: 责任判定结果 单选下拉(必填,三项), 责任判定说明 多行文本(必填,≤200字), 责任方承担比例 输入(%), 附件上传(图片/PDF,≤5), buttons 确认/取消.
```

---

## PAGE 06 · 向欣旺达索赔单 列表页（P03）→ `06-向欣旺达索赔单列表`

```
PAGE: 闪欣动力向欣旺达索赔单列表. Breadcrumb 理赔管理 / 向欣旺达索赔单. Standard list: 筛选 card + 表格 card + 分页.

筛选 card: 索赔单编号(输入), 索赔单状态(下拉多选), 创建时间范围(日期区间). Buttons 查询/重置/导出/新增.

表格 card title 向欣旺达索赔单. columns: 索赔单编号(monospace, e.g. SXCO-20260712-0003) / 关联服务商索赔单号 / 创建时间 / 申请总金额(money) / 索赔单状态(pill) / 操作. 5 sample rows spanning statuses 草稿/待审核/待结算/已驳回/已结算. 操作 buttons per status: 查看(all), 编辑(草稿), 提交(草稿), 审核(待审核, 欣旺达角色). Bottom 合计 row. Pagination: 共 86 条, 20 条/页.
```

---

## PAGE 07 · 闪欣索赔单 详情/编辑页（P04）→ `07-闪欣索赔单详情`

```
PAGE: 闪欣动力向欣旺达索赔单详情/编辑. Breadcrumb 理赔管理 / 向欣旺达索赔单详情. Stacked cards + bottom bar.

单据头: 索赔单编号 "SXCO-20260712-0003" + 状态 pill "待审核", 右侧 申请总金额 "¥3,720.00".

CARD 1 基础信息: 索赔单号, 关联服务商索赔单号 "SPCO-20260712-0007", 创建人, 创建时间, 备注(可填).

CARD 2 费用明细(勾选服务商索赔单明细): a table with checkbox column, columns 服务商索赔单号/工单号/工时费合计/备件管理费/其它费用合计/小计. 3 rows, some checked; note "已纳入其他索赔单的明细不可勾选"(one row disabled/grayed). Buttons 新增明细/删除已勾选. 合计 row. NOTE per rule: 金额=服务商对应金额，不再乘系数.

CARD 3 审核记录: 审核人/审核时间/审核结果(含 部分通过)/驳回原因, newest first.

CARD 4 责任判定(QMS 回显, 本期人工录入): 责任判定结果(内部责任/服务商责任/供应商责任), 内部责任部门(内部责任显示), 责任比例, 判定时间, 已发起费用转嫁(内部责任显示), 已发起服务商抵扣(服务商责任显示).

Support 部分通过: if 审核结果=部分通过, show 核准金额 field and 核减明细 note.

BOTTOM BAR: 【保存】【提交】【取消】(编辑), 【审核】(详情, 欣旺达). Render an OPEN 审核弹窗 overlay: 单据编号+申请金额, 审核结果单选【通过/驳回/拒绝/部分通过】, 审批意见(驳回/拒绝必填), 部分通过时显示 核准金额 输入, 附件上传, 确认/取消.
```

---

## PAGE 08 · 服务商索赔结算单 详情页（P06）→ `08-服务商结算单详情`

```
PAGE: 服务商索赔结算单详情. Breadcrumb 结算管理 / 服务商结算单详情. Cards + bottom bar.

单据头: 结算单号 "SPJS-20260701-0012" + 结算类型 服务商结算 + 状态 pill "待对账", 右侧 应付总金额 "¥12,480.00"(if negative show red "-¥2,300.00").

CARD 1 基本信息(read-only): 结算单号/结算类型/结算周期(2026-06-01 至 2026-06-30)/应付总金额/结算状态/对账确认时间/创建人/创建时间.

CARD 2 索赔单明细: table columns 索赔单号/工单号/索赔类型/服务商编码/服务商名称/所属区域/索赔总金额/工时费合计/备件管理费/其它费用合计. 4 rows incl. one 索赔抵扣单(负数金额, 类型标"抵扣"). Sticky 合计 row.

CARD 3 发票信息: 发票代码/发票号码/开票日期/开票金额/发票附件; 待开票状态显示【上传发票】按钮.

BOTTOM BAR rendered by 状态×角色: 对账确认(待对账,服务商) / 开票(待开票,服务商) / 确认结算(待确认,闪欣) / 发票确认(待核验,闪欣) / 作废(待确认,闪欣) / 强制结算(负数-待强制结算,闪欣) / 申请付款(已核验,闪欣) / 返回. Each triggers 二次确认弹窗 (show one open 二次确认弹窗 for 确认结算).
```

---

## PAGE 09 · 闪欣索赔结算单 列表页（P07）→ `09-闪欣结算单列表`

```
PAGE: 闪欣动力索赔结算单列表(欣旺达↔闪欣). Breadcrumb 结算管理 / 闪欣结算单. 筛选 + 表格 + 分页. Status tabs 全部/待确认/待对账/待开票/已结算.

筛选: 结算单号/结算周期/结算单状态(多选)/创建时间. Buttons 查询/重置/导出.

表格 columns: 结算单号(SXJS-…)/对方主体名称/结算周期/结算总金额/结算单状态(pill)/对账确认时间/发票上传时间/结算时间/创建时间/操作. 4 rows. 操作 by 状态×角色: 对账确认(待对账,闪欣) / 开票(待开票,闪欣) / 确认结算(待确认,欣旺达) / 发票确认(待核验,欣旺达) / 作废(待确认,欣旺达) / 申请付款(已核验,欣旺达) / 查看(all). 合计 row. 待确认状态可编辑明细.
```

---

## PAGE 10 · 闪欣索赔结算单 详情页（P08）→ `10-闪欣结算单详情`

```
PAGE: 闪欣动力索赔结算单详情. Breadcrumb 结算管理 / 闪欣结算单详情. Cards + bottom bar.

单据头: 结算单号 "SXJS-20260701-0005" + 状态 "待对账", 右侧 应付总金额 "¥28,600.00". Note 统一一张结算单不拆分开票, 内部分账交财务共享/OA(展示为提示条).

CARD 1 基本信息: 结算单号/结算类型 闪欣动力结算/结算周期/应付总金额/结算状态/对账确认时间/创建人/创建时间. 仅待确认状态可编辑(调周期/增删明细).

CARD 2 索赔单明细: columns 闪欣索赔单号/服务商索赔单号/关联工单号/索赔类型/服务商编码/服务商名称/所属区域/索赔总金额/工时费合计/备件管理费/其它费用合计. 3 rows. Sticky 合计 row.

CARD 3 发票信息: 发票代码/号码/开票日期/开票金额/附件.

BOTTOM BAR by 状态×角色: 对账确认(待对账,闪欣) / 开票(待开票,闪欣) / 确认结算(待确认,欣旺达) / 发票确认(待核验,欣旺达) / 作废(待确认,欣旺达) / 申请付款(已核验,欣旺达) / 返回.
```

---

## PAGE 11 · 付款申请单 列表页（P09）→ `11-付款申请单列表`

```
PAGE: 付款申请单列表. Breadcrumb 支付管理 / 付款申请单. 筛选 + 表格 + 分页.

筛选: 申请单号/关联结算单号/服务商名称(闪欣侧显示)/所属区域(闪欣侧显示)/申请单状态(多选)/申请时间范围. Buttons 新增/查询/重置/导出.

表格 columns: 申请单号(JSFK-…)/关联结算单号(SPJS-…)/服务商名称/所属区域/申请付款金额(money)/申请单状态(pill)/当前审批节点/申请人/申请部门/申请时间/付款完成时间/操作. 5 rows spanning 待提交/审批中/审批通过/审批驳回/已付款/已作废. 当前审批节点 e.g. "财务经理审批中". 操作 by 状态: 查看(all)/编辑(待提交)/提交(待提交)/作废(待提交)/审核(审批中,对应审批人). Pagination.
```

---

## PAGE 12 · 付款申请单 新建/编辑页（P10 表单）→ `12-付款申请单新建`

```
PAGE: 付款申请单新建/编辑. Breadcrumb 支付管理 / 付款申请单新建. Two cards + bottom bar.

CARD 1 基础信息(结算单自动带出, 全部只读): 关联结算单号 "SPJS-20260701-0012"/收款方全称 "华东-苏州星辉服务中心"/费用归属方 闪欣动力/结算周期/申请付款总金额 "¥12,480.00"/发票校验状态 已校验/申请人/申请部门/申请时间. Note: 进入时校验结算单已对账+发票已校验+无有效付款单，否则拦截.

CARD 2 付款信息(可编辑): 开户银行全称(必填,≤100字)/银行账号(必填,仅数字)/账户名称(必填,须与收款方全称一致,不一致弹风险提示)/付款内容(多行,必填,≤300字)/附件上传(图片/PDF). Show a subtle inline 风险提示 example under 账户名称.

BOTTOM BAR: 【保存】(存草稿,待提交,不触发审批)/【提交】(全量校验→二次确认→审批中)/【取消】.
```

---

## 弹窗补充（可并入对应页面，或单独出一屏）→ `13-弹窗组`

```
PAGE: 弹窗组 overview — render 4 modal dialogs on a dimmed background, arranged in a 2×2 grid, all Chinese, same design system:
1. 索赔单审核弹窗: 单据编号+申请金额, 审核结果【通过/驳回/拒绝】, 审批意见(驳回/拒绝必填), 附件上传, 确认/取消.
2. 判责结果录入弹窗: 责任判定结果(下拉:供应商责任/服务商责任/内部责任,必填), 责任判定说明(多行,必填≤200字), 责任方承担比例(%), 附件(≤5), 确认/取消.
3. 发票上传弹窗: 发票代码/发票号码/开票日期/开票金额/发票附件(上传), 保存/取消.
4. 导出弹窗: 导出范围(默认当前筛选条件全量数据) + 导出/取消.
```
