-- Add 'after_12th' category for career/course guidance
ALTER TABLE exam_guides MODIFY category ENUM('govt_job','competitive','school','after_12th') NOT NULL;
