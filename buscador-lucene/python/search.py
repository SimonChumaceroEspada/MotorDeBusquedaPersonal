import os
import sys
import lucene
import json
from java.nio.file import Paths
from org.apache.lucene.analysis.standard import StandardAnalyzer
from org.apache.lucene.index import DirectoryReader
from org.apache.lucene.store import SimpleFSDirectory
from org.apache.lucene.search import IndexSearcher, BooleanQuery, BooleanClause, TermQuery, MatchAllDocsQuery
from org.apache.lucene.queryparser.classic import QueryParser
from org.apache.lucene.search.highlight import Highlighter, QueryScorer, SimpleHTMLFormatter, SimpleFragmenter
from dotenv import load_dotenv

# Initialize Lucene VM
lucene.initVM(vmargs=['-Djava.awt.headless=true'])

# Load environment variables
load_dotenv()

# Constants
INDEX_DIR = os.environ.get('INDEX_DIR', '../index')
MAX_RESULTS = 100
FRAGMENT_SIZE = 150  # Size for highlighted fragments

def search(query_str):
    """Search in Lucene index and return results"""
    
    # Check if index exists
    if not os.path.exists(INDEX_DIR):
        return {
            "error": "Index not found. Please run indexing first.",
            "query": query_str,
            "total": 0,
            "resultados": []
        }
    
    print(f"Searching for: {query_str}")
    
    try:
        # Set up Lucene searcher
        directory = SimpleFSDirectory(Paths.get(INDEX_DIR))
        reader = DirectoryReader.open(directory)
        searcher = IndexSearcher(reader)
        analyzer = StandardAnalyzer()
        
        # Prepare the query parser for content field
        parser = QueryParser("content", analyzer)
        parsed_query = parser.parse(query_str)
        
        # Setup highlighter for search results
        formatter = SimpleHTMLFormatter("<mark>", "</mark>")
        scorer = QueryScorer(parsed_query)
        highlighter = Highlighter(formatter, scorer)
        highlighter.setTextFragmenter(SimpleFragmenter(FRAGMENT_SIZE))
        
        # Execute search
        top_docs = searcher.search(parsed_query, MAX_RESULTS)
        print(f"Found {top_docs.totalHits.value} hits.")
        
        # Process results
        results = []
        for score_doc in top_docs.scoreDocs:
            doc = searcher.doc(score_doc.doc)
            doc_type = doc.get("type")
            
            # Highlight the content that matches the query
            content = doc.get("content")
            token_stream = analyzer.tokenStream("content", content)
            highlighted_text = highlighter.getBestFragments(token_stream, content, 3, "...")
            
            if not highlighted_text:
                # If no highlight, just take a snippet
                highlighted_text = content[:200] + "..." if len(content) > 200 else content
            
            if doc_type == "document":
                results.append({
                    "tabla": "documento",
                    "columna": "nombre_archivo" if query_str.lower() in doc.get("filename").lower() else "contenido",
                    "resultado": f"Archivo: {doc.get('filename')} - {highlighted_text}"
                })
            elif doc_type == "database":
                results.append({
                    "tabla": doc.get("table"),
                    "columna": doc.get("column"),
                    "resultado": highlighted_text
                })
        
        reader.close()
        
        # Return results in the format expected by the frontend
        return {
            "query": query_str,
            "total": len(results),
            "resultados": results
        }
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "error": str(e),
            "query": query_str,
            "total": 0,
            "resultados": []
        }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing query parameter"}))
    else:
        query_str = sys.argv[1]
        results = search(query_str)
        # Output as JSON for parsing by Node.js
        print(json.dumps(results))
