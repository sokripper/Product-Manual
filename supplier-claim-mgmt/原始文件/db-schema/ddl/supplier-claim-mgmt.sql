-- 服务商索赔管理模块 建表 SQL（D0 交付物，只评审不自动执行；须研发组长审定后人工建表）
--
-- 生成说明：
--   1. 权威来源：docs/db-schema/表结构文档.md（唯一权威登记，本文件严格按其 S4 新表登记逐表翻译，不增不减表/列）。
--   2. 建表约定来源：harness-core/protocols/development-rules.md「建表 / 改表约定」——本文件只产出交付物，不执行、不建库；
--      子智能体（Planner/Developer/Tester）一律不建表，全部由人工评审后手动执行（_dev / _test / 正式环境均人工执行）。
--   3. 库/字符集：MySQL 8.0，utf8mb4，utf8mb4_unicode_ci，InnoDB；主键统一 `id VARCHAR(32) NOT NULL`，
--      PRIMARY KEY，雪花算法生成（不用 AUTO_INCREMENT / BIGINT）；原 BIGINT 外键关联列（claim_id/settle_id/
--      xw_claim_id/account_id/payment_id/invoice_info_id/attachment 相关 id 等）一律改 VARCHAR(32)。每表统一
--      审计列（create_by / created_at / update_by / updated_at / deleted_at / version），语义见各表 create_by
--      等列注释，不逐列重复展开。
--   4. 状态/枚举列注释内列出登记文档 S2「枚举字典」的全部码值语义；金额 DECIMAL(18,2)，可正可负的列不加 UNSIGNED；
--      VARCHAR(32) 主键不加 UNSIGNED。
--   5. 本模块不建物理外键（FK）：表间引用关系（如 claim_id、settle_id、work_order_id 等）仅作为普通列，关联对象在列注释中以
--      「逻辑关联 xxx.id」标注，不建 FOREIGN KEY 约束，符合登记文档「本表工单库相关字段只是普通列，不引用外部表」的要求。
--   6. 少数登记为「条件唯一」的业务约束（如 claim_order 同工单仅 1 张非拒绝/作废的索赔单、claim_settle_order 同周期同主体仅
--      1 张有效结算单、payment_apply 同结算单仅 1 张有效付款申请），因涉及按状态排除已作废/已驳回记录，无法用 MySQL 普通
--      UNIQUE 索引正确表达（否则会把历史作废记录也一并纳入唯一性冲突），本文件按登记原样保留为 Service 层强制约束并在表尾以
--      SQL 注释注明，不建物理唯一索引，避免建出语义错误的约束；其余登记的 uk_*/idx_* 均按登记原样建出物理索引。
--   7. 既有维修工单库（PRD/登记文档 S6，本期 Mock、待挂载）不在本文件范围内，本模块表中涉及工单库的列（work_order_id/no 等）
--      均为待挂载的业务字段列，不建对应物理表。

-- ===== claim_order 服务商索赔单 =====
CREATE TABLE `claim_order` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `claim_no` VARCHAR(32) NOT NULL COMMENT '服务商索赔单编号，规则 SPCO-yyyyMMdd-4位流水，全局唯一',
  `work_order_id` VARCHAR(64) NOT NULL COMMENT '关联工单ID（待挂载-维修工单库，本期 Mock）',
  `work_order_no` VARCHAR(64) NOT NULL COMMENT '关联工单编号（待挂载-维修工单库，本期 Mock）',
  `work_order_biz_type` VARCHAR(32) NULL COMMENT '工单业务类型（待挂载-维修工单库），用于映射生成 claim_type',
  `provider_id` VARCHAR(64) NOT NULL COMMENT '服务商ID（待挂载-服务商模块）',
  `provider_code` VARCHAR(64) NOT NULL COMMENT '服务商编码',
  `provider_name` VARCHAR(128) NOT NULL COMMENT '服务商名称',
  `region` VARCHAR(64) NOT NULL COMMENT '所属区域',
  `claim_type` VARCHAR(20) NOT NULL COMMENT '索赔类型 CLAIM_TYPE：WARRANTY=保内维修/SERVICE_ACTIVITY=服务活动/INTERNAL=内部服务/SPECIAL=特殊工单；由工单业务类型带出只读(A-9)',
  `claim_target` VARCHAR(10) NULL COMMENT '索赔对象（主责件归属）CLAIM_TARGET：XW=欣旺达件/SELF=自采件；区域初审录入(A-6)',
  `project_code` VARCHAR(64) NULL COMMENT '项目编码；claim_target=XW 时必填',
  `main_part_id` VARCHAR(64) NULL COMMENT '主责件ID（待挂载-维修工单库）',
  `main_part_name` VARCHAR(128) NULL COMMENT '主责件名称',
  `coefficient_snapshot` DECIMAL(8,4) NULL COMMENT '服务商索赔系数快照（索赔发起时点，A-2）',
  `labor_fee_total` DECIMAL(18,2) NOT NULL COMMENT '工时费合计(>0)，由工单带入',
  `part_mgmt_fee` DECIMAL(18,2) NOT NULL COMMENT '备件管理费=Σ(销售价×系数)',
  `other_fee_total` DECIMAL(18,2) NOT NULL COMMENT '其它费用合计(≥0)，可编辑物流费等(A-1/A-7)',
  `apply_total_amount` DECIMAL(18,2) NOT NULL COMMENT '申请总金额=工时费合计+备件管理费+其它费用合计(系统自动计算)',
  `currency` VARCHAR(8) NOT NULL DEFAULT 'CNY' COMMENT '币种 CURRENCY：CNY=人民币/USD=美元(本期禁用,A-29)',
  `status` VARCHAR(24) NOT NULL COMMENT '索赔单状态 CLAIM_STATUS：DRAFT=草稿/PENDING_REGION=待区域初审/PENDING_HQ=待总部审核/PENDING_LIABILITY=待责任判定/PENDING_SETTLE=待结算/REJECTED=已驳回/DECLINED=已拒绝/SETTLED=已结算/VOIDED=已作废',
  `liability_result` VARCHAR(16) NULL COMMENT '责任判定结果 LIABILITY_RESULT：SUPPLIER=供应商责任/PROVIDER=服务商责任/INTERNAL=内部责任（外采件判责,A-27）',
  `liability_desc` VARCHAR(200) NULL COMMENT '责任判定说明',
  `liability_ratio` DECIMAL(5,2) NULL COMMENT '责任方承担比例(%)',
  `liability_by` VARCHAR(64) NULL COMMENT '责任判定人',
  `liability_time` DATETIME NULL COMMENT '责任判定时间',
  `supplier_claim_started` TINYINT(1) NULL COMMENT '是否已发起供应商索赔',
  `provider_deduct_started` TINYINT(1) NULL COMMENT '是否已发起服务商抵扣',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_claim_no` (`claim_no`),
  KEY `idx_provider` (`provider_id`),
  KEY `idx_status` (`status`),
  KEY `idx_work_order_no` (`work_order_no`)
  -- uk_work_order_active：登记要求「同一工单仅允许 1 张非已拒绝/已作废的索赔单」，其中“已拒绝”=DECLINED；REJECTED 为可重提态仍占用，故仅排除 DECLINED/VOIDED
  -- 状态的历史记录，无法用 MySQL 普通 UNIQUE 索引正确表达，按登记原样交由 Service 层保证（见 LLD），不建物理唯一索引。
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务商索赔单';

-- ===== claim_fee_labor 工时费明细 =====
CREATE TABLE `claim_fee_labor` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `project_name` VARCHAR(128) NOT NULL COMMENT '维修项目名称',
  `labor_hours` DECIMAL(8,2) NOT NULL COMMENT '工时数',
  `labor_price` DECIMAL(18,2) NOT NULL COMMENT '工时单价',
  `amount` DECIMAL(18,2) NOT NULL COMMENT '工时费金额',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_claim` (`claim_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务商索赔单-工时费明细';

-- ===== claim_fee_part 备件明细 =====
CREATE TABLE `claim_fee_part` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `part_name` VARCHAR(128) NOT NULL COMMENT '备件名称',
  `part_attr` VARCHAR(64) NULL COMMENT '备件属性（如需回运/SN属性等标记）',
  `claim_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00 COMMENT '备件索赔金额（本期恒为0）',
  `mgmt_fee` DECIMAL(18,2) NOT NULL COMMENT '备件管理费',
  `battery_sn` VARCHAR(24) NULL COMMENT '电池包SN',
  `old_part_code` VARCHAR(64) NULL COMMENT '旧件条码',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_claim` (`claim_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务商索赔单-备件明细';

-- ===== claim_fee_other 其它费用明细 =====
CREATE TABLE `claim_fee_other` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `fee_type` VARCHAR(64) NOT NULL COMMENT '费用类型',
  `amount` DECIMAL(18,2) NOT NULL COMMENT '费用金额',
  `remark` VARCHAR(500) NULL COMMENT '备注',
  `editable` TINYINT(1) NOT NULL COMMENT '是否可编辑（仅物流费等可编辑=1）',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_claim` (`claim_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务商索赔单-其它费用明细';

-- ===== claim_audit_record 审核记录（索赔单/闪欣单共用） =====
CREATE TABLE `claim_audit_record` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `biz_type` VARCHAR(16) NOT NULL COMMENT '业务类型：CLAIM=服务商索赔单/XW=闪欣向欣旺达索赔单',
  `biz_id` VARCHAR(32) NOT NULL COMMENT '业务单据ID（逻辑关联 claim_order.id 或 xw_claim_order.id，不建物理外键）',
  `audit_stage` VARCHAR(32) NOT NULL COMMENT '阶段：区域初审/业务审核/欣旺达审核/OPERATION/QMS_MOCK',
  `auditor` VARCHAR(64) NOT NULL COMMENT '审核人',
  `audit_time` DATETIME NOT NULL COMMENT '审核时间',
  `audit_result` VARCHAR(16) NOT NULL COMMENT '审核：通过/驳回/拒绝/部分通过；操作：CREATE/EDIT/SUBMIT/RESUBMIT/VOID；QMS Mock：SUPPLIER/PROVIDER/INTERNAL',
  `approved_amount` DECIMAL(18,2) NULL COMMENT '核准金额（审核结果为部分通过 PARTIAL 时填写）',
  `remark` VARCHAR(500) NULL COMMENT '审核意见/操作摘要',
  `attachment_ids` VARCHAR(512) NULL COMMENT '附件ID列表（逗号分隔，逻辑关联 attachment.id，不建物理外键）',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='审核记录（服务商索赔单/闪欣索赔单共用）';

-- ===== xw_claim_order 闪欣向欣旺达索赔单 =====
CREATE TABLE `xw_claim_order` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `claim_no` VARCHAR(32) NOT NULL COMMENT '闪欣向欣旺达索赔单编号，规则 SXCO-yyyyMMdd-4位流水，全局唯一',
  `provider_claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `provider_claim_no` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单编号',
  `work_order_no` VARCHAR(64) NULL COMMENT '工单编号（待挂载-维修工单库）',
  `repair_type` VARCHAR(20) NULL COMMENT '维修类型：乘用车/商用车/储能/汽车电子/其他(A-38)',
  `sub_repair_type` VARCHAR(20) NULL COMMENT '二级维修类型（随维修类型级联）',
  `battery_sn` VARCHAR(24) NULL COMMENT '电池包SN（电池包维修场景必填）',
  `serial_no` VARCHAR(64) NULL COMMENT '序列号（电机电控场景必填）',
  `vin` VARCHAR(17) NULL COMMENT '车辆VIN（整车场景条件必填，内部场景豁免，A-39）',
  `provider_code` VARCHAR(64) NOT NULL COMMENT '服务商编码',
  `provider_name` VARCHAR(128) NOT NULL COMMENT '服务商名称',
  `region` VARCHAR(64) NULL COMMENT '所属区域',
  `province_city` VARCHAR(64) NULL COMMENT '省市（工单/Mock 未提供时可空）',
  `labor_fee_total` DECIMAL(18,2) NOT NULL COMMENT '工时费合计（=服务商索赔单对应金额，不乘系数，A-37）',
  `other_fee_total` DECIMAL(18,2) NOT NULL COMMENT '其它费用合计（=服务商索赔单对应金额，不乘系数，A-37）',
  `part_mgmt_fee` DECIMAL(18,2) NOT NULL COMMENT '备件管理费（=服务商索赔单对应金额，不乘系数，A-37）',
  `apply_total_amount` DECIMAL(18,2) NOT NULL COMMENT '申请总金额',
  `approved_amount` DECIMAL(18,2) NULL COMMENT '核准金额（部分通过场景，A-40）',
  `currency` VARCHAR(8) NOT NULL DEFAULT 'CNY' COMMENT '币种 CURRENCY：CNY=人民币/USD=美元(本期禁用,A-29)',
  `status` VARCHAR(24) NOT NULL COMMENT '闪欣索赔单状态 XW_CLAIM_STATUS：DRAFT=草稿/PENDING_AUDIT=待审核/PENDING_SETTLE=待结算/REJECTED=已驳回/DECLINED=已拒绝/SETTLED=已结算/VOIDED=已作废',
  `audit_result` VARCHAR(16) NULL COMMENT '欣旺达审核结果 XW_AUDIT_RESULT：PASS=通过/REJECT=驳回/DECLINE=拒绝/PARTIAL=部分通过',
  `liability_result` VARCHAR(16) NULL COMMENT '责任判定结果 LIABILITY_RESULT：SUPPLIER=供应商责任/PROVIDER=服务商责任/INTERNAL=内部责任（QMS回显，本期人工录入）',
  `internal_dept` VARCHAR(128) NULL COMMENT '内部责任部门',
  `liability_ratio` DECIMAL(5,2) NULL COMMENT '责任方承担比例(%)',
  `fee_transfer_started` TINYINT(1) NULL COMMENT '是否已发起费用转嫁',
  `provider_deduct_started` TINYINT(1) NULL COMMENT '是否已发起服务商抵扣',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_claim_no` (`claim_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='闪欣向欣旺达索赔单';

-- ===== xw_claim_detail 闪欣索赔单明细（勾选的服务商明细） =====
CREATE TABLE `xw_claim_detail` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `xw_claim_id` VARCHAR(32) NOT NULL COMMENT '关联闪欣索赔单ID（逻辑关联 xw_claim_order.id，不建物理外键）',
  `provider_claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `provider_claim_no` VARCHAR(32) NOT NULL COMMENT '服务商索赔单编号',
  `work_order_no` VARCHAR(64) NULL COMMENT '工单编号（待挂载-维修工单库）',
  `labor_fee_total` DECIMAL(18,2) NOT NULL COMMENT '工时费合计',
  `other_fee_total` DECIMAL(18,2) NOT NULL COMMENT '其它费用合计',
  `subtotal` DECIMAL(18,2) NOT NULL COMMENT '小计金额',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_xw_claim` (`xw_claim_id`),
  UNIQUE KEY `uk_provider_claim` (`provider_claim_id`) COMMENT '一张服务商索赔单明细仅可纳入一张闪欣索赔单'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='闪欣索赔单明细（勾选的服务商索赔单明细）';

-- ===== claim_settle_order 结算单（服务商/闪欣共用，settle_type 区分） =====
CREATE TABLE `claim_settle_order` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `settle_no` VARCHAR(32) NOT NULL COMMENT '结算单编号，规则 SPJS/SXJS-yyyyMMdd-4位流水，全局唯一',
  `settle_type` VARCHAR(12) NOT NULL COMMENT '结算类型 SETTLE_TYPE：PROVIDER=服务商结算/SHANXIN=闪欣动力结算',
  `payee_name` VARCHAR(128) NOT NULL COMMENT '收款方名称（服务商名/闪欣动力）',
  `counterpart_name` VARCHAR(128) NULL COMMENT '对方主体名称（闪欣结算场景=欣旺达）',
  `provider_id` VARCHAR(64) NULL COMMENT '服务商ID（服务商结算维度）',
  `region` VARCHAR(64) NULL COMMENT '所属区域',
  `settle_period_start` DATE NOT NULL COMMENT '结算周期起始日',
  `settle_period_end` DATE NOT NULL COMMENT '结算周期结束日',
  `payable_amount` DECIMAL(18,2) NOT NULL COMMENT '应付总金额（可正可负）',
  `currency` VARCHAR(8) NOT NULL DEFAULT 'CNY' COMMENT '币种 CURRENCY：CNY=人民币/USD=美元(本期禁用,A-29)',
  `claim_count` INT NOT NULL COMMENT '纳入本次结算的索赔单总数',
  `status` VARCHAR(20) NOT NULL COMMENT '结算单状态 SETTLE_STATUS：PENDING_CONFIRM=待确认/PENDING_RECON=待对账/PENDING_INVOICE=待开票/PENDING_VERIFY=待核验/VERIFIED=已核验/PENDING_FORCE=待强制结算/SETTLED=已结算/VOIDED=已作废',
  `invoice_permission_flag` TINYINT(1) NULL COMMENT '开票权限标识（白名单+应付为正数方可开票；应付为负数关闭开票）',
  `force_settle_flag` TINYINT(1) NULL COMMENT '强制结算标识（应付为负数场景）',
  `recon_confirm_time` DATETIME NULL COMMENT '对账确认时间',
  `invoice_code` VARCHAR(64) NULL COMMENT '发票代码',
  `invoice_no` VARCHAR(64) NULL COMMENT '发票号码',
  `invoice_date` DATE NULL COMMENT '开票日期',
  `invoice_amount` DECIMAL(18,2) NULL COMMENT '开票金额',
  `invoice_attachment_id` VARCHAR(32) NULL COMMENT '发票附件ID（逻辑关联 attachment.id，不建物理外键）',
  `settle_time` DATETIME NULL COMMENT '结算完成时间',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_settle_no` (`settle_no`)
  -- uk_period_subject：登记要求「同周期×同主体×settle_type 仅一张有效结算单（A-34 零金额不生成）」，因需排除已作废
  -- VOIDED 状态的历史记录、且服务商/闪欣两种主体判定列不同（provider_id / counterpart_name），无法用 MySQL 普通 UNIQUE
  -- 索引正确表达，按登记原样交由 Service 层保证，不建物理唯一索引。
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='结算单（服务商结算/闪欣结算共用，settle_type 区分）';

-- ===== claim_settle_detail 结算明细 =====
CREATE TABLE `claim_settle_detail` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `settle_id` VARCHAR(32) NOT NULL COMMENT '关联结算单ID（逻辑关联 claim_settle_order.id，不建物理外键）',
  `claim_no` VARCHAR(32) NULL COMMENT '服务商索赔单/抵扣单编号（闪欣结算行为空）',
  `xw_claim_no` VARCHAR(32) NULL COMMENT '闪欣索赔单编号（闪欣结算场景适用）',
  `work_order_no` VARCHAR(64) NULL COMMENT '工单编号（待挂载-维修工单库）',
  `claim_type` VARCHAR(20) NULL COMMENT '索赔类型 CLAIM_TYPE（抵扣行可空）',
  `provider_id` VARCHAR(64) NULL COMMENT '服务商ID',
  `provider_code` VARCHAR(64) NULL COMMENT '服务商编码',
  `provider_name` VARCHAR(128) NULL COMMENT '服务商名称',
  `region` VARCHAR(64) NULL COMMENT '所属区域',
  `claim_total` DECIMAL(18,2) NOT NULL COMMENT '索赔总金额',
  `labor_fee_total` DECIMAL(18,2) NOT NULL COMMENT '工时费合计',
  `part_mgmt_fee` DECIMAL(18,2) NOT NULL COMMENT '备件管理费',
  `other_fee_total` DECIMAL(18,2) NOT NULL COMMENT '其它费用合计',
  `deduct_amount` DECIMAL(18,2) NOT NULL COMMENT '抵扣金额',
  `fee_owner` VARCHAR(16) NULL COMMENT '费用归属 FEE_OWNER（闪欣结算使用；服务商/抵扣行可空）',
  `currency` VARCHAR(8) NOT NULL DEFAULT 'CNY' COMMENT '币种 CURRENCY：CNY=人民币/USD=美元(本期禁用,A-29)',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_settle` (`settle_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='结算明细';

-- ===== claim_deduct_order 索赔抵扣单 =====
CREATE TABLE `claim_deduct_order` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `deduct_no` VARCHAR(32) NOT NULL COMMENT '索赔抵扣单编号，规则 DKD-yyyyMMdd-4位流水，全局唯一',
  `claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `claim_no` VARCHAR(32) NOT NULL COMMENT '服务商索赔单编号',
  `provider_id` VARCHAR(64) NOT NULL COMMENT '服务商ID',
  `work_order_no` VARCHAR(64) NULL COMMENT '工单编号（待挂载-维修工单库）',
  `liability_result` VARCHAR(16) NOT NULL COMMENT '责任判定结果 LIABILITY_RESULT（本表恒为 PROVIDER=服务商责任）',
  `liability_ratio` DECIMAL(5,2) NOT NULL COMMENT '责任方承担比例(%)',
  `claim_liable_amount` DECIMAL(18,2) NOT NULL COMMENT '责任对应索赔金额',
  `deduct_amount` DECIMAL(18,2) NOT NULL COMMENT '抵扣金额（=责任对应索赔金额×责任比例，A-30）',
  `settle_period_belong` DATE NOT NULL COMMENT '结算周期归属日期（按闪欣审批通过时间归属）',
  `status` VARCHAR(12) NOT NULL COMMENT '抵扣单状态 DEDUCT_STATUS：UNSETTLED=未结算/SETTLED=已纳入结算',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_deduct_no` (`deduct_no`),
  KEY `idx_provider` (`provider_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='索赔抵扣单';

-- ===== warranty_deposit_account 质保金账户（A-31 新增主数据） =====
CREATE TABLE `warranty_deposit_account` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `provider_id` VARCHAR(64) NOT NULL COMMENT '服务商ID，唯一',
  `provider_name` VARCHAR(128) NOT NULL COMMENT '服务商名称',
  `balance` DECIMAL(18,2) NOT NULL COMMENT '质保金账户余额',
  `frozen_amount` DECIMAL(18,2) NOT NULL COMMENT '冻结金额',
  `status` VARCHAR(12) NOT NULL COMMENT '账户状态：NORMAL=正常/FROZEN=冻结',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider` (`provider_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='质保金账户';

-- ===== warranty_deposit_txn 质保金流水 =====
CREATE TABLE `warranty_deposit_txn` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `account_id` VARCHAR(32) NOT NULL COMMENT '关联质保金账户ID（逻辑关联 warranty_deposit_account.id，不建物理外键）',
  `provider_id` VARCHAR(64) NOT NULL COMMENT '服务商ID',
  `biz_type` VARCHAR(16) NOT NULL COMMENT '业务类型：DEDUCT=扣减/RECHARGE=充值/INIT=初始',
  `biz_no` VARCHAR(32) NULL COMMENT '业务单号（结算单号）',
  `amount` DECIMAL(18,2) NOT NULL COMMENT '变动金额（可正可负）',
  `balance_after` DECIMAL(18,2) NOT NULL COMMENT '变动后余额',
  `shortfall_carryover` DECIMAL(18,2) NOT NULL DEFAULT 0.00 COMMENT '余额不足差额挂账结转金额(A-31)',
  `voucher_attachment_id` VARCHAR(32) NULL COMMENT '凭证附件ID（逻辑关联 attachment.id，不建物理外键）',
  `remark` VARCHAR(500) NULL COMMENT '备注',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_account` (`account_id`),
  KEY `idx_biz_no` (`biz_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='质保金流水';

-- ===== payment_apply 付款申请单 =====
CREATE TABLE `payment_apply` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `apply_no` VARCHAR(32) NOT NULL COMMENT '付款申请单编号，规则 JSFK-yyyyMMdd-4位流水，全局唯一',
  `settle_id` VARCHAR(32) NOT NULL COMMENT '关联结算单ID（逻辑关联 claim_settle_order.id，不建物理外键）',
  `settle_no` VARCHAR(32) NOT NULL COMMENT '关联结算单编号',
  `payee_name` VARCHAR(128) NOT NULL COMMENT '收款方名称',
  `fee_owner` VARCHAR(16) NOT NULL COMMENT '费用归属 FEE_OWNER：XW=欣旺达/SHANXIN=闪欣动力/INTERNAL_DEPT=内部部门',
  `apply_amount` DECIMAL(18,2) NOT NULL COMMENT '申请付款金额（=结算单应付金额）',
  `currency` VARCHAR(8) NOT NULL DEFAULT 'CNY' COMMENT '币种 CURRENCY：CNY=人民币/USD=美元(本期禁用,A-29)',
  `payee_bank` VARCHAR(100) NULL COMMENT '收款方开户银行全称',
  `payee_account` VARCHAR(64) NULL COMMENT '收款方银行账号（仅数字）',
  `payee_account_name` VARCHAR(128) NULL COMMENT '收款方账户名称（须与收款方一致）',
  `pay_content` VARCHAR(300) NULL COMMENT '付款内容',
  `invoice_info_id` VARCHAR(32) NULL COMMENT '发票信息ID（本期无独立发票实体，Mock 阶段置NULL；正式文档到位后回填）',
  `has_invoice` TINYINT(1) NOT NULL COMMENT '是否提供发票',
  `grade_level` VARCHAR(4) NULL COMMENT '付款金额档 PAY_GRADE：L1=<5万/L2=5万~20万/L3=≥20万（按申请金额自动匹配，A-24）',
  `current_node` VARCHAR(64) NULL COMMENT '当前审批节点',
  `applicant` VARCHAR(64) NULL COMMENT '申请人',
  `apply_dept` VARCHAR(128) NULL COMMENT '申请部门',
  `apply_time` DATETIME NULL COMMENT '申请时间',
  `status` VARCHAR(16) NOT NULL COMMENT '付款申请单状态 PAYMENT_STATUS：PENDING_SUBMIT=待提交/APPROVING=审批中/APPROVED=审批通过/REJECTED=兼容码(本期不驻留，驳回回待提交)/PAID=已付款/VOIDED=已作废(A-25/D-付款-D1)',
  `pay_finish_time` DATETIME NULL COMMENT '付款完成时间',
  `voucher_attachment_id` VARCHAR(32) NULL COMMENT '付款凭证附件ID（逻辑关联 attachment.id，不建物理外键）',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_apply_no` (`apply_no`)
  -- uk_settle_active：登记要求「一张结算单仅一张有效付款申请」，因需排除 VOIDED 已作废的历史申请，无法用 MySQL 普通
  -- UNIQUE 索引正确表达，按登记原样交由 Service 层保证，不建物理唯一索引。
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='付款申请单';

-- ===== payment_approval_node 付款审批节点流水 =====
CREATE TABLE `payment_approval_node` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `payment_id` VARCHAR(32) NOT NULL COMMENT '关联付款申请单ID（逻辑关联 payment_apply.id，不建物理外键）',
  `node_seq` INT NOT NULL COMMENT '节点顺序号',
  `node_name` VARCHAR(64) NOT NULL COMMENT '节点名称',
  `approver_role` VARCHAR(64) NULL COMMENT '审批角色',
  `approver` VARCHAR(64) NULL COMMENT '审批人',
  `approve_time` DATETIME NULL COMMENT '审批时间',
  `approve_result` VARCHAR(12) NULL COMMENT '审批结果：PASS=通过/REJECT=驳回/PENDING=待审批',
  `opinion` VARCHAR(500) NULL COMMENT '审批意见',
  `attachment_ids` VARCHAR(512) NULL COMMENT '附件ID列表（逗号分隔，逻辑关联 attachment.id，不建物理外键）',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_payment` (`payment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='付款审批节点流水';

-- ===== settle_period_config 结算周期配置 =====
CREATE TABLE `settle_period_config` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `frequency` VARCHAR(16) NOT NULL COMMENT '结算周期频率（本期固定 MONTHLY=按月）',
  `gen_day` INT NOT NULL COMMENT '自动生成日（每周期第几天自动生成结算单）',
  `period_start_day` INT NOT NULL COMMENT '结算周期起始日',
  `period_end_day` INT NOT NULL COMMENT '结算周期结束日',
  `belong_basis` VARCHAR(32) NOT NULL COMMENT '归属基准（默认=闪欣审批通过时间）',
  `manual_advance` TINYINT(1) NOT NULL COMMENT '是否支持人工提前生成',
  `zero_amount_rule` VARCHAR(32) NOT NULL COMMENT '零金额结算规则：NOT_GENERATE=不生成',
  `effective_from` DATE NULL COMMENT '生效日期',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='结算周期配置';

-- ===== invoice_whitelist 开票权限白名单 =====
CREATE TABLE `invoice_whitelist` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `provider_id` VARCHAR(64) NOT NULL COMMENT '服务商ID',
  `provider_name` VARCHAR(128) NOT NULL COMMENT '服务商名称',
  `region` VARCHAR(64) NULL COMMENT '所属区域',
  `enabled` TINYINT(1) NOT NULL COMMENT '是否启用开票权限',
  `effective_from` DATE NULL COMMENT '生效日期',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_provider` (`provider_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='开票权限白名单';

-- ===== claim_coefficient 服务商索赔系数 =====
CREATE TABLE `claim_coefficient` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `provider_id` VARCHAR(64) NULL COMMENT '服务商ID，NULL 表示全局默认系数',
  `coefficient` DECIMAL(8,4) NOT NULL COMMENT '服务商索赔系数',
  `effective_from` DATE NULL COMMENT '生效日期',
  `enabled` TINYINT(1) NOT NULL COMMENT '是否启用',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_provider` (`provider_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务商索赔系数';

-- ===== payment_approval_flow_config 付款审批流配置 =====
CREATE TABLE `payment_approval_flow_config` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `grade_level` VARCHAR(4) NOT NULL COMMENT '付款金额档 PAY_GRADE：L1=<5万/L2=5万~20万/L3=≥20万',
  `amount_min` DECIMAL(18,2) NOT NULL COMMENT '金额区间下限',
  `amount_max` DECIMAL(18,2) NULL COMMENT '金额区间上限（最高档为空表示无上限）',
  `node_chain` TEXT NOT NULL COMMENT '有序审批节点角色链（JSON数组）',
  `enabled` TINYINT(1) NOT NULL COMMENT '是否启用',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='付款审批流配置';

-- ===== claim_type_mapping 工单业务类型→索赔类型映射字典（A-9） =====
CREATE TABLE `claim_type_mapping` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `work_order_biz_type` VARCHAR(64) NOT NULL COMMENT '工单业务类型（待挂载-维修工单库）',
  `claim_type` VARCHAR(20) NOT NULL COMMENT '索赔类型 CLAIM_TYPE：WARRANTY=保内维修/SERVICE_ACTIVITY=服务活动/INTERNAL=内部服务/SPECIAL=特殊工单',
  `enabled` TINYINT(1) NOT NULL COMMENT '是否启用',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wo_biz_type` (`work_order_biz_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单业务类型→索赔类型映射字典';

-- ===== attachment 附件（本地存储） =====
CREATE TABLE `attachment` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `biz_type` VARCHAR(32) NOT NULL COMMENT '业务类型：CLAIM/XW/SETTLE/PAYMENT/DEDUCT/LIABILITY 等',
  `biz_id` VARCHAR(32) NOT NULL COMMENT '业务单据ID（逻辑关联对应业务表 id，不建物理外键）',
  `file_name` VARCHAR(255) NOT NULL COMMENT '文件名',
  `file_path` VARCHAR(512) NOT NULL COMMENT '文件存储路径（服务器相对路径）',
  `file_type` VARCHAR(16) NULL COMMENT '文件类型：IMAGE=图片/PDF=文档',
  `file_size` BIGINT NULL COMMENT '文件大小（字节）',
  `upload_by` VARCHAR(64) NULL COMMENT '上传人',
  `upload_time` DATETIME NULL COMMENT '上传时间',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  KEY `idx_biz` (`biz_type`, `biz_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='附件（本地磁盘存储）';
