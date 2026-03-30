from sqlalchemy import text
from app.database import engine

def migrate():
    print("Creating forum tables in 'lexhub' database...")
    
    with engine.connect() as conn:
        # Create forum_posts table
        try:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS forum_posts (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT,
                    title VARCHAR(255) NOT NULL,
                    content TEXT NOT NULL,
                    category VARCHAR(100) NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """))
            print("Successfully created 'forum_posts' table.")
        except Exception as e:
            print(f"Error creating 'forum_posts': {e}")

        # Create forum_replies table
        try:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS forum_replies (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    post_id INT,
                    user_id INT,
                    content TEXT NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """))
            print("Successfully created 'forum_replies' table.")
        except Exception as e:
            print(f"Error creating 'forum_replies': {e}")

        # Create forum_likes table
        try:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS forum_likes (
                    post_id INT,
                    user_id INT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (post_id, user_id),
                    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """))
            print("Successfully created 'forum_likes' table.")
        except Exception as e:
            print(f"Error creating 'forum_likes': {e}")

        conn.commit()
    print("Migration completed successfully!")

if __name__ == "__main__":
    migrate()
