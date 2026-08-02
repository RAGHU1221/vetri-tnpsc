-- Phase 5: AI usage tracking (free credits protect panna)
CREATE TABLE IF NOT EXISTS ai_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  kind ENUM('chat','explain') DEFAULT 'chat',
  chars_in INT DEFAULT 0,
  chars_out INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_user_day (user_id, created_at)
);
