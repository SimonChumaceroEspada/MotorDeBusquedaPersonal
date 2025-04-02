import { useState } from 'react';
import SearchBar from './SearchBar';
import SearchResults from './SearchResults';
import { SearchResult } from '../types/search';
import '../styles/SearchPage.css';

function SearchPage() {
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState('');

  const handleSearch = async (searchQuery: string) => {
    if (!searchQuery.trim()) return;
    
    setQuery(searchQuery);
    setIsLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`http://localhost:3000/search?q=${encodeURIComponent(searchQuery)}`);
      
      if (!response.ok) {
        throw new Error(`Error: ${response.status}`);
      }
      
      const data = await response.json();
      setSearchResults(data.resultados || []);
    } catch (err) {
      setError('Error al realizar la búsqueda. Por favor, inténtelo de nuevo más tarde.');
      console.error('Search error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="search-page">
      <header className="search-header">
        <h1>Buscador de Documentos y Base de Datos</h1>
        <p>Busca información en documentos y en la base de datos</p>
      </header>
      
      <SearchBar onSearch={handleSearch} />
      
      {isLoading && (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Buscando...</p>
        </div>
      )}
      
      {error && (
        <div className="error-message">
          <p>{error}</p>
        </div>
      )}
      
      {!isLoading && !error && searchResults.length > 0 && (
        <SearchResults results={searchResults} query={query} />
      )}
      
      {!isLoading && !error && query && searchResults.length === 0 && (
        <div className="no-results">
          <p>No se encontraron resultados para "<strong>{query}</strong>"</p>
        </div>
      )}
    </div>
  );
}

export default SearchPage;
