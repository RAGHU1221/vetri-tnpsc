-- Notifications: job/exam application windows, vacancies, links
CREATE TABLE IF NOT EXISTS job_notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  exam_key VARCHAR(30) NOT NULL,             -- links to exam_guides.exam_key (e.g. 'tnpsc_g4')
  title_ta VARCHAR(250) NOT NULL,
  title_en VARCHAR(250) NOT NULL,
  vacancies INT NULL,                        -- NULL = not yet announced
  application_start DATE NULL,
  application_end DATE NULL,
  exam_date DATE NULL,
  application_link VARCHAR(400),
  official_notification_link VARCHAR(400),
  status ENUM('upcoming','open','closed') DEFAULT 'upcoming',
  is_verified TINYINT(1) DEFAULT 0,          -- 1 = admin-confirmed accurate; 0 = draft/unconfirmed
  source VARCHAR(50) DEFAULT 'admin',        -- 'admin' or 'auto_fetch'
  notes_ta TEXT,
  notes_en TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_status (status, is_verified)
);
