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
