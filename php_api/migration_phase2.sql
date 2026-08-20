-- Phase 2: admin role
ALTER TABLE users ADD COLUMN is_admin TINYINT(1) DEFAULT 0;
-- Ungala admin aakka: UPDATE users SET is_admin = 1 WHERE mobile = 'YOUR_MOBILE';
