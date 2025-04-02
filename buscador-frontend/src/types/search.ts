export interface SearchResult {
  tabla: string;
  columna: string;
  resultado: string;
}

export interface SearchResponse {
  query: string;
  total: number;
  resultados: SearchResult[];
}
