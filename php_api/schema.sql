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
