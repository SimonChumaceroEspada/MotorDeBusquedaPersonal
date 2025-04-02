import os
import sys
import lucene
import traceback
import json
from datetime import datetime
from java.nio.file import Paths
from org.apache.lucene.analysis.standard import StandardAnalyzer
from org.apache.lucene.document import Document, Field, TextField, StringField, StoredField
from org.apache.lucene.index import IndexWriter, IndexWriterConfig, DirectoryReader, Term
from org.apache.lucene.store import SimpleFSDirectory
from org.apache.lucene.search import IndexSearcher, TermQuery
from dotenv import load_dotenv

# Import custom modules
from utils.db_connector import get_db_data
from utils.file_processor import process_documents

# Initialize Lucene VM
lucene.initVM(vmargs=['-Djava.awt.headless=true'])
print('PyLucene initialized')

# Load environment variables
load_dotenv()

# Paths for indexes
INDEX_DIR = os.environ.get('INDEX_DIR', '../index')
DOCUMENTS_DIR = os.environ.get('DOCUMENTS_DIR', '../documents')

def create_index():
    """Create or update the Lucene index with both database data and document content"""
    
    # Ensure index directory exists
    if not os.path.exists(INDEX_DIR):
        os.makedirs(INDEX_DIR)
    
    print(f"Creating index in {INDEX_DIR}")
    
    # Set up Lucene
    directory = SimpleFSDirectory(Paths.get(INDEX_DIR))
    analyzer = StandardAnalyzer()
    config = IndexWriterConfig(analyzer)
    config.setOpenMode(IndexWriterConfig.OpenMode.CREATE)  # This will overwrite existing index
    writer = IndexWriter(directory, config)
    
    try:
        # Process documents
        print(f"Processing documents from {DOCUMENTS_DIR}")
        if os.path.exists(DOCUMENTS_DIR):
            doc_count = index_documents(writer)
            print(f"Indexed {doc_count} documents")
        else:
            print(f"Documents directory {DOCUMENTS_DIR} does not exist")
            
        # Process database
        print("Processing database data")
        db_count = index_database(writer)
        print(f"Indexed {db_count} database records")
        
        # Optimize and close
        writer.commit()
        print(f"Indexing completed: {doc_count + db_count} total items indexed")
        return doc_count + db_count
        
    except Exception as e:
        writer.rollback()
        print(f"Error during indexing: {str(e)}")
        traceback.print_exc()
        return 0
    finally:
        writer.close()

def index_documents(writer):
    """Index document files from the documents directory"""
    doc_data = process_documents(DOCUMENTS_DIR)
    count = 0
    
    for item in doc_data:
        try:
            # Create Lucene document
            doc = Document()
            
            # Add fields
            doc.add(StringField("id", f"doc_{count}", Field.Store.YES))
            doc.add(StringField("type", "document", Field.Store.YES))
            doc.add(StringField("filename", item['filename'], Field.Store.YES))
            doc.add(TextField("content", item['content'], Field.Store.YES))
            doc.add(StringField("path", item['path'], Field.Store.YES))
            doc.add(StringField("extension", item['extension'], Field.Store.YES))
            
            # Add document to index
            writer.addDocument(doc)
            count += 1
        except Exception as e:
            print(f"Error indexing document {item['filename']}: {str(e)}")
    
    return count

def index_database(writer):
    """Index data from PostgreSQL database"""
    db_data = get_db_data()
    count = 0
    
    for record in db_data:
        try:
            # Create Lucene document
            doc = Document()
            
            # Add fields
            doc.add(StringField("id", f"db_{record['id']}", Field.Store.YES))
            doc.add(StringField("type", "database", Field.Store.YES))
            doc.add(StringField("table", record['table'], Field.Store.YES)) 
            doc.add(StringField("column", record['column'], Field.Store.YES))
            doc.add(TextField("content", record['content'], Field.Store.YES))
            
            # Add document to index
            writer.addDocument(doc)
            count += 1
        except Exception as e:
            print(f"Error indexing database record: {str(e)}")
    
    return count

if __name__ == "__main__":
    start_time = datetime.now()
    indexed_count = create_index()
    end_time = datetime.now()
    
    result = {
        "success": indexed_count > 0,
        "indexed_count": indexed_count,
        "time_taken": (end_time - start_time).total_seconds(),
        "timestamp": end_time.isoformat()
    }
    
    # Print as JSON for parsing by Node.js
    print(json.dumps(result))
