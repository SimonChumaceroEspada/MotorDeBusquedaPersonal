document.addEventListener('DOMContentLoaded', () => {
    // Elementos del DOM
    const searchInput = document.getElementById('searchInput');
    const searchButton = document.getElementById('searchButton');
    const resultsContainer = document.getElementById('resultsContainer');
    const resultsDiv = document.getElementById('results');
    const loadingDiv = document.getElementById('loading');
    const noResultsDiv = document.getElementById('noResults');
    const resultsStats = document.getElementById('resultsStats');
    const filterButtons = document.querySelectorAll('.filter-btn');
    const resultItemTemplate = document.getElementById('resultItemTemplate');

    // Estado de la aplicación
    let currentResults = [];
    let currentFilter = 'all';

    // Event listeners
    searchButton.addEventListener('click', performSearch);
    searchInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            performSearch();
        }
    });

    filterButtons.forEach(button => {
        button.addEventListener('click', () => {
            currentFilter = button.dataset.filter;
            filterButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            renderResults();
        });
    });

    // Función para realizar la búsqueda
    async function performSearch() {
        const query = searchInput.value.trim();
        if (!query) return;

        // Mostrar indicador de carga
        showLoading();

        try {
            const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
            
            if (!response.ok) {
                throw new Error('Error en la búsqueda');
            }

            const data = await response.json();
            currentResults = data.resultados || [];
            
            renderResults();
            updateStats(data);
        } catch (error) {
            console.error('Error:', error);
            showNoResults();
        }
    }

    // Función para renderizar resultados
    function renderResults() {
        if (currentResults.length === 0) {
            showNoResults();
            return;
        }

        resultsDiv.innerHTML = '';
        let filteredResults = currentResults;

        // Aplicar filtro
        if (currentFilter === 'database') {
            filteredResults = currentResults.filter(item => item.tabla !== 'documento');
        } else if (currentFilter === 'document') {
            filteredResults = currentResults.filter(item => item.tabla === 'documento');
        }

        // Mostrar mensaje si no hay resultados después de filtrar
        if (filteredResults.length === 0) {
            showNoResults();
            return;
        }

        // Mostrar resultados
        filteredResults.forEach(item => {
            const resultItem = resultItemTemplate.content.cloneNode(true);
            
            // Configurar icono
            const isDocument = item.tabla === 'documento';
            resultItem.querySelector('.database-icon').style.display = isDocument ? 'none' : 'inline';
            resultItem.querySelector('.document-icon').style.display = isDocument ? 'inline' : 'none';
            
            // Configurar tipo
            const typeSpan = resultItem.querySelector('.result-type');
            typeSpan.textContent = isDocument ? 'Documento' : 'Base de datos';
            if (isDocument) typeSpan.classList.add('documento');
            
            // Configurar columna y contenido
            resultItem.querySelector('.result-column').textContent = isDocument ? 
                item.columna === 'nombre_archivo' ? 'Nombre de archivo' : 'Contenido' : 
                `${item.tabla}.${item.columna}`;
            
            resultItem.querySelector('.result-body').textContent = item.resultado;
            
            resultsDiv.appendChild(resultItem);
        });

        // Mostrar resultados
        loadingDiv.style.display = 'none';
        noResultsDiv.style.display = 'none';
        resultsDiv.style.display = 'grid';
    }

    // Función para actualizar estadísticas
    function updateStats(data) {
        const dbCount = data.resultados.filter(item => item.tabla !== 'documento').length;
        const docCount = data.resultados.filter(item => item.tabla === 'documento').length;
        
        resultsStats.textContent = `Se encontraron ${data.total} resultados para "${data.query}" (${dbCount} en base de datos, ${docCount} en documentos)`;
    }

    // Función para mostrar indicador de carga
    function showLoading() {
        resultsDiv.style.display = 'none';
        noResultsDiv.style.display = 'none';
        loadingDiv.style.display = 'block';
    }

    // Función para mostrar mensaje de no resultados
    function showNoResults() {
        resultsDiv.style.display = 'none';
        loadingDiv.style.display = 'none';
        noResultsDiv.style.display = 'block';
    }

    // Comprobar si hay una búsqueda en la URL
    const urlParams = new URLSearchParams(window.location.search);
    const queryParam = urlParams.get('q');
    if (queryParam) {
        searchInput.value = queryParam;
        performSearch();
    }
});
