-- ============================================================
-- BLOG PLATFORM DATABASE SCHEMA
-- High-Quality Example with Best Practices
-- ============================================================
-- Features:
-- - Multi-user blogging platform
-- - Categories and tags
-- - Comments with threading
-- - User roles and permissions
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- USERS AND ROLES
-- ============================================================

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'reader' 
        CHECK(role IN ('admin', 'editor', 'author', 'reader')),
    is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- ============================================================
-- BLOG POSTS
-- ============================================================

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,  -- URL-friendly name
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    post_id INTEGER PRIMARY KEY AUTOINCREMENT,
    author_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,  -- URL-friendly title
    content TEXT NOT NULL,
    excerpt TEXT,  -- Short summary
    featured_image_url TEXT,
    category_id INTEGER,
    status TEXT NOT NULL DEFAULT 'draft' 
        CHECK(status IN ('draft', 'published', 'archived')),
    view_count INTEGER DEFAULT 0 CHECK(view_count >= 0),
    is_featured INTEGER DEFAULT 0 CHECK(is_featured IN (0, 1)),
    published_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_category ON posts(category_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_published ON posts(published_at);
CREATE INDEX idx_posts_slug ON posts(slug);

-- ============================================================
-- TAGS (Many-to-Many with Posts)
-- ============================================================

CREATE TABLE tags (
    tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_tags (
    post_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE
);

CREATE INDEX idx_post_tags_post ON post_tags(post_id);
CREATE INDEX idx_post_tags_tag ON post_tags(tag_id);

-- ============================================================
-- COMMENTS (with Threading Support)
-- ============================================================

CREATE TABLE comments (
    comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,  -- NULL for top-level comments
    content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK(status IN ('approved', 'pending', 'spam', 'deleted')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE
);

CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);
CREATE INDEX idx_comments_status ON comments(status);

-- ============================================================
-- LIKES/REACTIONS
-- ============================================================

CREATE TABLE post_likes (
    like_id INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(post_id, user_id)  -- One like per user per post
);

CREATE INDEX idx_post_likes_post ON post_likes(post_id);

-- ============================================================
-- MEDIA LIBRARY
-- ============================================================

CREATE TABLE media (
    media_id INTEGER PRIMARY KEY AUTOINCREMENT,
    uploader_id INTEGER NOT NULL,
    filename TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER NOT NULL,  -- in bytes
    mime_type TEXT NOT NULL,
    alt_text TEXT,  -- For accessibility
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (uploader_id) REFERENCES users(user_id)
);

CREATE INDEX idx_media_uploader ON media(uploader_id);

-- ============================================================
-- ACTIVITY LOG (Audit Trail)
-- ============================================================

CREATE TABLE activity_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    action TEXT NOT NULL,  -- 'create_post', 'update_post', 'delete_comment', etc.
    entity_type TEXT NOT NULL,  -- 'post', 'comment', 'user', etc.
    entity_id INTEGER NOT NULL,
    details TEXT,  -- JSON or text description
    ip_address TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_activity_user ON activity_log(user_id);
CREATE INDEX idx_activity_date ON activity_log(created_at);
CREATE INDEX idx_activity_entity ON activity_log(entity_type, entity_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update post timestamp on update
CREATE TRIGGER update_post_timestamp 
AFTER UPDATE ON posts
FOR EACH ROW
BEGIN
    UPDATE posts SET updated_at = CURRENT_TIMESTAMP 
    WHERE post_id = NEW.post_id;
END;

-- Update comment timestamp on update
CREATE TRIGGER update_comment_timestamp 
AFTER UPDATE ON comments
FOR EACH ROW
BEGIN
    UPDATE comments SET updated_at = CURRENT_TIMESTAMP 
    WHERE comment_id = NEW.comment_id;
END;

-- Increment post view count (for tracking)
-- Note: In production, you might want to do this differently to avoid locks
CREATE TRIGGER increment_post_views
AFTER INSERT ON activity_log
FOR EACH ROW
WHEN NEW.action = 'view_post'
BEGIN
    UPDATE posts SET view_count = view_count + 1 
    WHERE post_id = NEW.entity_id;
END;

-- ============================================================
-- VIEWS (Useful Queries)
-- ============================================================

-- Published posts with author and category info
CREATE VIEW published_posts AS
SELECT 
    p.post_id,
    p.title,
    p.slug,
    p.excerpt,
    p.featured_image_url,
    p.view_count,
    p.published_at,
    u.username as author_username,
    u.display_name as author_name,
    c.category_name,
    c.slug as category_slug,
    (SELECT COUNT(*) FROM comments WHERE post_id = p.post_id AND status = 'approved') as comment_count,
    (SELECT COUNT(*) FROM post_likes WHERE post_id = p.post_id) as like_count
FROM posts p
JOIN users u ON p.author_id = u.user_id
LEFT JOIN categories c ON p.category_id = c.category_id
WHERE p.status = 'published';

-- ============================================================
-- SAMPLE QUERIES
-- ============================================================

-- Get recent published posts with author
-- SELECT * FROM published_posts 
-- ORDER BY published_at DESC 
-- LIMIT 10;

-- Get posts by tag
-- SELECT p.* FROM posts p
-- JOIN post_tags pt ON p.post_id = pt.post_id
-- JOIN tags t ON pt.tag_id = t.tag_id
-- WHERE t.slug = 'technology' AND p.status = 'published'
-- ORDER BY p.published_at DESC;

-- Get comments for a post with user info
-- SELECT c.content, c.created_at, u.display_name, u.avatar_url
-- FROM comments c
-- JOIN users u ON c.user_id = u.user_id
-- WHERE c.post_id = ? AND c.status = 'approved'
-- ORDER BY c.created_at ASC;

-- Get popular posts
-- SELECT * FROM published_posts
-- ORDER BY view_count DESC
-- LIMIT 5;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
