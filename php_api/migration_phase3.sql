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
