import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Get a connection to the PostgreSQL database"""
    return psycopg2.connect(
        host=os.environ.get('DB_HOST', 'localhost'),
        port=os.environ.get('DB_PORT', '5432'),
        database=os.environ.get('DB_NAME', 'dbpostgrado3'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', 'postgres')
    )

def get_db_data():
    """Get data from all tables in the PostgreSQL database for indexing"""
    data = []
    conn = get_db_connection()
    
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Get all tables in public schema
            cursor.execute("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
            """)
            tables = cursor.fetchall()
            
            # Process each table
            id_counter = 0
            for table_row in tables:
                table_name = table_row['table_name']
                
                # Get columns for this table
                cursor.execute("""
                    SELECT column_name, data_type
                    FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = %s
                """, (table_name,))
                
                columns = cursor.fetchall()
                text_columns = []
                
                # Filter for text-like columns
                for col in columns:
                    col_name = col['column_name']
                    data_type = col['data_type']
                    
                    if data_type in ('text', 'varchar', 'char', 'character varying', 'name'):
                        text_columns.append(col_name)
                    elif data_type in ('json', 'jsonb'):
                        text_columns.append(f"{col_name}::text")
                    elif data_type.startswith(('int', 'numeric', 'decimal')):
                        text_columns.append(f"CAST({col_name} AS TEXT)")
                
                # Skip tables with no text columns
                if not text_columns:
                    continue
                
                # For each text column, get data
                for col in text_columns:
                    # Handle cast columns
                    display_col = col.split('::')[0] if '::' in col else col
                    display_col = col.split(' AS ')[0] if ' AS ' in col else display_col
                    
                    try:
                        cursor.execute(f"""
                            SELECT {col} FROM {table_name}
                            WHERE {col} IS NOT NULL AND {col}::text != ''
                        """)
                        
                        for row in cursor.fetchall():
                            content = str(list(row.values())[0])
                            if content and len(content) > 0:
                                id_counter += 1
                                data.append({
                                    'id': str(id_counter),
                                    'table': table_name,
                                    'column': display_col,
                                    'content': content
                                })
                    except Exception as e:
                        print(f"Error processing {table_name}.{col}: {str(e)}")
                        
    except Exception as e:
        print(f"Database error: {str(e)}")
    finally:
        conn.close()
    
    return data

if __name__ == "__main__":
    # Test the connection and data retrieval
    data = get_db_data()
    print(f"Retrieved {len(data)} records from database")
