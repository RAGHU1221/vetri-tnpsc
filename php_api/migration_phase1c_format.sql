-- Real-paper-pattern support: match-the-following tables, assertion-reason, images
ALTER TABLE questions
  ADD COLUMN question_format ENUM('simple','match_table','assertion_reason') DEFAULT 'simple' AFTER question_en,
  ADD COLUMN table_data JSON NULL COMMENT 'match-the-following: {"list1":["a) X","b) Y"],"list2":["1) P","2) Q"]}' AFTER question_format,
  ADD COLUMN assertion_ta TEXT NULL AFTER table_data,
  ADD COLUMN assertion_en TEXT NULL AFTER assertion_ta,
  ADD COLUMN reason_ta TEXT NULL AFTER assertion_en,
  ADD COLUMN reason_en TEXT NULL AFTER reason_ta,
  ADD COLUMN image_url VARCHAR(500) NULL COMMENT 'question diagram/map/image if any' AFTER reason_en,
  ADD COLUMN source_verified TINYINT(1) DEFAULT 0 COMMENT '1 = confirmed from real fetched PYQ paper' AFTER years_asked;
