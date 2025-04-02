import { SearchResult } from '../types/search';
import '../styles/SearchResults.css';

interface SearchResultsProps {
  results: SearchResult[];
  query: string;
}

function SearchResults({ results, query }: SearchResultsProps) {
  // Agrupar resultados por tabla
  const groupedResults: Record<string, SearchResult[]> = {};
  
  results.forEach(result => {
    if (!groupedResults[result.tabla]) {
      groupedResults[result.tabla] = [];
    }
    groupedResults[result.tabla].push(result);
  });

  // Función para resaltar todas las ocurrencias de la consulta en el texto
  const highlightText = (text: string) => {
    if (!query || query.trim() === '') return text;
    
    // Escapar caracteres especiales en la consulta para usar en regex
    const escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(`(${escapedQuery})`, 'gi');
    
    // Dividir el texto por la consulta y resaltarla
    const parts = text.split(regex);
    
    return parts.map((part, index) => 
      regex.test(part) ? <mark key={index}>{part}</mark> : part
    );
  };

  return (
    <div className="search-results">
      <h2>Resultados de búsqueda para: "{query}"</h2>
      <p className="results-count">Se encontraron {results.length} resultados</p>
      
      {Object.keys(groupedResults).map(tableName => (
        <div key={tableName} className="result-group">
          <h3>{tableName === 'documento' ? 'Documentos' : `Tabla: ${tableName}`}</h3>
          
          <div className="results-list">
            {groupedResults[tableName].map((result, index) => (
              <div key={index} className="result-item">
                <div className="result-header">
                  {tableName === 'documento' ? (
                    <span className="result-title">
                      {result.columna === 'nombre_archivo' ? 'Documento' : 'Contenido'}
                    </span>
                  ) : (
                    <span className="result-title">
                      Columna: {result.columna}
                    </span>
                  )}
                </div>
                
                <div className="result-content">
                  {highlightText(result.resultado)}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

export default SearchResults;
