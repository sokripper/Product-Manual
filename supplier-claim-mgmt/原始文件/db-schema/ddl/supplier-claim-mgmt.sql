-- 服务商索赔管理模块 建表 SQL（D0 交付物，只评审不自动执行；须研发组长审定后人工建表）
--
-- 生成说明：
--   1. 权威来源：docs/db-schema/表结构文档.md（唯一权威登记，本文件严格按其 S4 新表登记逐表翻译，不增不减表/列）。
--   2. 建表约定来源：harness-core/protocols/development-rules.md「建表 / 改表约定」——本文件只产出交付物，不执行、不建库；
--      子智能体（Planner/Developer/Tester）一律不建表，全部由人工评审后手动执行（_dev / _test / 正式环境均人工执行）。
--   3. 库/字符集：MySQL 8.0，utf8mb4，utf8mb4_unicode_ci，InnoDB；主键统一 `id VARCHAR(32) NOT NULL`，
--      PRIMARY KEY，雪花算法生成（不用 AUTO_INCREMENT / BIGINT）；原 BIGINT 外键关联列（claim_id/biz_id/
--      attachment 相关 id 等）一律改 VARCHAR(32)。每表统一
--      审计列（create_by / created_at / update_by / updated_at / deleted_at / version），语义见各表 create_by
--      等列注释，不逐列重复展开。
--   4. 状态/枚举列注释内列出登记文档 S2「枚举字典」的全部码值语义；金额 DECIMAL(18,2)，可正可负的列不加 UNSIGNED；
--      VARCHAR(32) 主键不加 UNSIGNED。
--   5. 本模块不建物理外键（FK）：表间引用关系（如 claim_id、biz_id、work_order_id 等）仅作为普通列，关联对象在列注释中以
--      「逻辑关联 xxx.id」标注，不建 FOREIGN KEY 约束，符合登记文档「本表工单库相关字段只是普通列，不引用外部表」的要求。
--   6. 少数登记为「条件唯一」的业务约束（如 claim_order 同工单仅 1 张非拒绝/作废的索赔单），因涉及按状态排除已作废/已驳回
--      记录，无法用 MySQL 普通 UNIQUE 索引正确表达（否则会把历史作废记录也一并纳入唯一性冲突），本文件按登记原样保留为
--      Service 层强制约束并在表尾以 SQL 注释注明，不建物理唯一索引，避免建出语义错误的约束；其余登记的 uk_*/idx_* 均按登记
--      原样建出物理索引。
--   7. 既有维修工单库（PRD/登记文档 S6，本期 Mock、待挂载）不在本文件范围内，本模块表中涉及工单库的列（work_order_id/no 等）
--      均为待挂载的业务字段列，不建对应物理表。
--
-- ★★★ 列变更待研发组长审定后由人执行，子智能体不建表 ★★★
--   本轮 D-索赔-B9/B10/B11 已决新增列：claim_order 补 repair_type/sub_repair_type/serial_no/vin/province_city 五列；
--   claim_fee_part 补 sale_price；claim_audit_record.audit_stage 注释补 LIABILITY=责任判定。以上列变更须研发组长审定后由人工执行
--   （ALTER 或重建），子智能体只产出 SQL 文本、不执行、不建表/改表。相关表处已就近标注「★ 列变更待审定待人执行」。

-- ===== claim_order 服务商索赔单 =====
-- ★ 列变更待研发组长审定后由人执行，子智能体不建表：本表 repair_type/sub_repair_type/serial_no/vin/province_city 五列为 D-索赔-B9 已决新增。
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
  `repair_type` VARCHAR(20) NULL COMMENT '维修类型（待挂载-维修工单库；乘用车/商用车/储能/汽车电子/其他）；A-10 带出/A-14 汽车电子把关/A-39 场景触发（裁决 D-索赔-B9，与 xw_claim_order 同名列对齐）',
  `sub_repair_type` VARCHAR(20) NULL COMMENT '二级维修类型（待挂载-维修工单库，随维修类型级联，裁决 D-索赔-B9）',
  `serial_no` VARCHAR(64) NULL COMMENT '序列号（待挂载-维修工单库，裁决 D-索赔-B9）',
  `vin` VARCHAR(17) NULL COMMENT '车辆VIN（待挂载-维修工单库，整车场景条件必填，内部场景豁免，裁决 D-索赔-B9）',
  `province_city` VARCHAR(64) NULL COMMENT '所属省市（待挂载-维修工单库，裁决 D-索赔-B9）',
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
-- ★ 列变更待研发组长审定后由人执行，子智能体不建表：本表 sale_price 列为 D-索赔-B11 已决新增。
CREATE TABLE `claim_fee_part` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `claim_id` VARCHAR(32) NOT NULL COMMENT '关联服务商索赔单ID（逻辑关联 claim_order.id，不建物理外键）',
  `part_name` VARCHAR(128) NOT NULL COMMENT '备件名称',
  `part_attr` VARCHAR(64) NULL COMMENT '备件属性（如需回运/SN属性等标记）',
  `claim_amount` DECIMAL(18,2) NOT NULL DEFAULT 0.00 COMMENT '备件索赔金额（本期恒为0）',
  `sale_price` DECIMAL(18,2) NULL COMMENT '备件销售价（待挂载-维修工单库带出）；mgmt_fee=sale_price×系数，落库保金额可追溯（裁决 D-索赔-B11）',
  `mgmt_fee` DECIMAL(18,2) NOT NULL COMMENT '备件管理费（=sale_price×coefficient_snapshot）',
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
  `audit_stage` VARCHAR(32) NOT NULL COMMENT '阶段：区域初审/业务审核/OPERATION/QMS_MOCK/LIABILITY=责任判定（裁决 D-索赔-B10）',
  `auditor` VARCHAR(64) NOT NULL COMMENT '审核人',
  `audit_time` DATETIME NOT NULL COMMENT '审核时间',
  `audit_result` VARCHAR(16) NOT NULL COMMENT '审核：通过/驳回/拒绝；操作：CREATE/EDIT/SUBMIT/RESUBMIT/VOID；QMS Mock：SUPPLIER/PROVIDER/INTERNAL',
  `approved_amount` DECIMAL(18,2) NULL COMMENT '核准金额',
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

-- ===== claim_type_mapping 工单业务类型→索赔类型映射字典 =====
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
  `biz_type` VARCHAR(32) NOT NULL COMMENT '业务类型：CLAIM/DEDUCT/LIABILITY 等',
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
