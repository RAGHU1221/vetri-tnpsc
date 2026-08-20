-- Phase 6: streaks
CREATE TABLE IF NOT EXISTS user_streaks (
  user_id INT PRIMARY KEY,
  current_streak INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_active_date DATE NULL
);
