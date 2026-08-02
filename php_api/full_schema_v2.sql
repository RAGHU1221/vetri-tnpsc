-- வெற்றி TNPSC — Phase 1 schema
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  mobile VARCHAR(15) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  target_group VARCHAR(10) DEFAULT 'G4',
  lang ENUM('ta','en') DEFAULT 'ta',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS questions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  group_exam VARCHAR(10) NOT NULL DEFAULT 'G4',
  subject VARCHAR(30) NOT NULL,
  unit VARCHAR(120),
  question_ta TEXT NOT NULL,
  question_en TEXT,
  options_ta JSON NOT NULL,
  options_en JSON,
  correct_option TINYINT NOT NULL,
  book_name_ta VARCHAR(150),
  book_name_en VARCHAR(150),
  page_no SMALLINT NULL,
  explanation_ta TEXT,
  explanation_en TEXT,
  years_asked JSON,
  repeat_count TINYINT DEFAULT 0,
  difficulty ENUM('easy','med','hard') DEFAULT 'med',
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_question (question_ta(255)),
  KEY idx_filter (group_exam, subject, repeat_count)
);

CREATE TABLE IF NOT EXISTS import_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT,
  filename VARCHAR(200),
  total_rows INT, inserted_rows INT, updated_rows INT, skipped_rows INT,
  error_report JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Phase 2: admin role
ALTER TABLE users ADD COLUMN is_admin TINYINT(1) DEFAULT 0;
-- Ungala admin aakka: UPDATE users SET is_admin = 1 WHERE mobile = 'YOUR_MOBILE';
-- Phase 3: mock test results
CREATE TABLE IF NOT EXISTS test_results (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  test_type ENUM('mini','full','daily') DEFAULT 'mini',
  subject VARCHAR(30) NULL,           -- NULL = full mock (all subjects)
  total_questions SMALLINT NOT NULL,
  correct SMALLINT NOT NULL,
  wrong SMALLINT NOT NULL,
  skipped SMALLINT NOT NULL,
  score DECIMAL(6,2) NOT NULL,        -- 1.5 marks per question (G4 pattern)
  time_taken_sec INT NOT NULL,
  weak_subjects JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_user (user_id, created_at)
);
-- Phase 4: current affairs
CREATE TABLE IF NOT EXISTS current_affairs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ca_date DATE NOT NULL,
  category VARCHAR(40) DEFAULT 'general',   -- tn, national, international, science, sports, awards, schemes
  title_ta VARCHAR(300) NOT NULL,
  title_en VARCHAR(300),
  content_ta TEXT,
  content_en TEXT,
  is_tn TINYINT(1) DEFAULT 0,               -- Tamil Nadu specific priority
  source_url VARCHAR(400),
  is_active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_date (ca_date, is_tn)
);
-- Phase 4b: speed up cron dedup lookups + allow longer source_url
ALTER TABLE current_affairs MODIFY source_url VARCHAR(500);
ALTER TABLE current_affairs ADD INDEX idx_source_url (source_url(191));
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
-- வழிகாட்டி (Guide) — exam directory: TNPSC, NMMS, Police, Bank, School exams etc.
CREATE TABLE IF NOT EXISTS exam_guides (
  id INT AUTO_INCREMENT PRIMARY KEY,
  exam_key VARCHAR(30) NOT NULL UNIQUE,      -- e.g. 'tnpsc_g4', 'nmms', 'tn_police_constable'
  category ENUM('govt_job','competitive','school') NOT NULL,
  icon VARCHAR(10) DEFAULT '📋',
  color_hex VARCHAR(7) DEFAULT '#2E7D4F',
  name_ta VARCHAR(150) NOT NULL,
  name_en VARCHAR(150) NOT NULL,
  conducting_body_ta VARCHAR(150),
  conducting_body_en VARCHAR(150),
  eligibility_ta TEXT,
  eligibility_en TEXT,
  age_limit_ta VARCHAR(300),
  age_limit_en VARCHAR(300),
  exam_pattern_ta TEXT,
  exam_pattern_en TEXT,
  syllabus_ta TEXT,                          -- newline-separated topic list
  syllabus_en TEXT,
  selection_process_ta VARCHAR(400),
  selection_process_en VARCHAR(400),
  salary_ta VARCHAR(200),
  salary_en VARCHAR(200),
  official_website VARCHAR(200),
  prep_tips_ta TEXT,
  prep_tips_en TEXT,
  display_order INT DEFAULT 0,
  is_active TINYINT(1) DEFAULT 1,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
