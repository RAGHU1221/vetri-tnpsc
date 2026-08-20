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
