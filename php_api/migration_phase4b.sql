-- Phase 4b: speed up cron dedup lookups + allow longer source_url
ALTER TABLE current_affairs MODIFY source_url VARCHAR(500);
ALTER TABLE current_affairs ADD INDEX idx_source_url (source_url(191));
