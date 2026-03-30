import mysql.connector
from datetime import datetime

# Database config
config = {
    'user': 'root',
    'password': 'root',
    'host': '127.0.0.1',
    'database': 'lexhub'
}

def seed():
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()

        # 1. Create a dummy document if none exists
        cursor.execute("SELECT id FROM statute_documents WHERE title LIKE '%Intellectual Property Act%' LIMIT 1")
        doc = cursor.fetchone()
        
        if not doc:
            print("Creating parent document...")
            cursor.execute("""
                INSERT INTO statute_documents (user_id, title, category, description, file_url, file_name, file_size, created_at)
                VALUES (1, 'Intellectual Property Act, No. 36 of 2003', 'statutes', 
                'The main legal framework for intellectual property in Sri Lanka.', 
                '/static/statutes/ip_act_2003.pdf', 'IP_Act_2003.pdf', '1.2 MB', %s)
            """, (datetime.now(),))
            doc_id = cursor.lastrowid
        else:
            doc_id = doc[0]

        # 2. Add sections
        sections = [
            (
                doc_id, "Section 9", "Duration of Copyright", 
                "Subject to the provisions of this section, copyright in a work shall be protected during the life of the author and for seventy years after his death.",
                "ප්‍රකාශන හිමිකම කතෘගේ ජීවිත කාලය පුරාම සහ ඔහුගේ මරණයෙන් පසු වසර 70ක් දක්වා ආරක්ෂා වේ."
            ),
            (
                doc_id, "Section 11", "Fair Use of Works", 
                "The fair use of a protected work, including such use by reproduction in copies or by any other means specified by that section, for purposes such as criticism, comment, news reporting, teaching, scholarship, or research, shall not be an infringement of copyright.",
                "විවේචනය, පුවත් වාර්තාකරණය, ඉගැන්වීම් හෝ පර්යේෂණ වැනි කටයුතු සඳහා ප්‍රකාශන හිමිකම ඇති කෘතියක් සාධාරණ ලෙස භාවිතා කිරීම වරදක් නොවේ."
            ),
            (
                doc_id, "Section 101", "Definition of a Mark", 
                "A 'mark' means any visible sign serving to distinguish the goods or services of one enterprise from those of other enterprises.",
                "වෙළඳ ලකුණක් යනු එක් ආයතනයක භාණ්ඩ හෝ සේවාවන් තවත් ආයතනයක භාණ්ඩ හෝ සේවාවන්ගෙන් වෙන්කර හඳුනා ගැනීමට භාවිතා කරන දෘශ්‍ය සංකේතයකි."
            ),
            (
                doc_id, "Section 103", "Signs that cannot be registered as marks", 
                "A mark shall not be registered if it is likely to mislead the public or trade circles, in particular as regards the geographical origin of the goods or services concerned or their nature or characteristics.",
                "මහජනයා නොමඟ යවන සුළු හෝ භාණ්ඩවල නිජබිම පිළිබඳ වැරදි වැටහීමක් ඇති කරන ලකුණු වෙළඳ ලකුණු ලෙස ලියාපදිංචි කළ නොහැක."
            ),
            (
                doc_id, "Section 121", "Duration of Registration of a Mark", 
                "The registration of a mark shall expire ten years after the date of registration. A registration may be renewed for consecutive periods of ten years.",
                "වෙළඳ ලකුණක් ලියාපදිංචි කළ දින සිට වසර දහයක් දක්වා වලංගු වේ. එය සෑම වසර දහයකට වරක්ම අලුත් කළ යුතුය."
            )
        ]

        print(f"Seeding {len(sections)} sections...")
        for s in sections:
            cursor.execute("""
                INSERT INTO statute_sections (document_id, section_number, title, content, summary, created_at)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (*s, datetime.now()))

        conn.commit()
        print("Seeding complete!")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == "__main__":
    seed()
