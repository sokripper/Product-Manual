-- 单据流水序列表 doc_no_sequence 建表 SQL（D-编码-B1 交付物）
-- ★ 待研发组长审定，勿执行 ★：本表为单据编码并发取号方案（D-编码-D1）新增序列表，
--   审定并人工建表前不得执行；子智能体（Planner/Developer/Tester）一律不建表。
--
-- 生成说明：
--   1. 权威来源：docs/conventions.md S7（单据编号规则）、docs/db-schema/表结构文档.md「单据编码」段；
--      本文件严格按序列表字段定义翻译，不增不减列。
--   2. 库/字符集：MySQL 8.0，utf8mb4，utf8mb4_unicode_ci，InnoDB；主键统一 id VARCHAR(32)，雪花算法生成
--      （不用 AUTO_INCREMENT）。每表统一审计列（create_by / created_at / update_by / updated_at / deleted_at / version）。
--   3. 唯一键 uk_prefix_date(prefix, seq_date) 保证每前缀每日仅一行序列；取号走
--      INSERT ... ON DUPLICATE KEY UPDATE current_seq=current_seq+1，InnoDB 对命中的唯一键行加行锁，
--      将同「前缀+日期」的并发取号串行化，不同前缀/不同日期落不同行、不互锁（见 docs/conventions.md S7 取号流程）。

-- ===== doc_no_sequence 单据流水序列表 =====
CREATE TABLE `doc_no_sequence` (
  `id` VARCHAR(32) NOT NULL COMMENT '主键，雪花算法',
  `prefix` VARCHAR(8) NOT NULL COMMENT '单据前缀：SPCO/DKD',
  `seq_date` CHAR(8) NOT NULL COMMENT '日期段 yyyyMMdd（生成时点服务器当日，本期单时区仅 CNY）',
  `current_seq` INT NOT NULL DEFAULT 0 COMMENT '当日该前缀已发出的最大流水（首次当日建行即发出 1，之后原子自增）',
  `create_by` VARCHAR(64) NULL COMMENT '创建人',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` VARCHAR(64) NULL COMMENT '修改人',
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '软删除时间戳（NULL=未删）',
  `version` INT NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_prefix_date` (`prefix`, `seq_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='单据流水序列表（每前缀每日一行，并发取号序列源，D-编码-D1）';
