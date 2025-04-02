# Buscador de Documentos y Base de Datos

Un sistema de búsqueda integrado que permite buscar tanto en una base de datos PostgreSQL como en documentos de varios formatos.

## Características

- Búsqueda en base de datos PostgreSQL a través de todas las tablas y columnas
- Búsqueda en documentos de múltiples formatos:
  - TXT - Archivos de texto plano
  - PDF - Documentos PDF
  - DOCX - Documentos de Microsoft Word
  - XLSX - Hojas de cálculo de Microsoft Excel
  - PPTX - Presentaciones de Microsoft PowerPoint

## Requisitos previos

- Node.js (v16 o superior)
- Python (v3.7 o superior)
- PostgreSQL (configurado según las variables de entorno)

### Dependencias de Python

Para procesar archivos de Excel y PowerPoint, necesitas instalar algunas bibliotecas de Python:

```bash
# Para soporte de Excel
npm run setup-excel
# O pip install openpyxl

# Para soporte de PowerPoint
npm run setup-powerpoint
# O pip install python-pptx

# Para instalar todas las dependencias
npm run setup-python-deps
# O pip install openpyxl python-pptx PyPDF2 python-docx
```

## Configuración

1. Copia el archivo `.env.example` a `.env` y configura las variables según tu entorno:

```
# Database connection
DB_HOST=localhost
DB_PORT=5432
DB_NAME=tu_base_de_datos
DB_USER=tu_usuario
DB_PASSWORD=tu_contraseña

# Paths
DOCUMENTS_DIR=./buscador-lucene/documents
INDEX_DIR=./buscador-lucene/index

# Python settings
PYTHON_CMD=python
AUTO_INDEX=true
WATCH_DOCUMENTS=true
```

2. Coloca los documentos para búsqueda en la carpeta configurada en `DOCUMENTS_DIR`

## Uso

### Iniciar el servidor backend

```bash
npm start
```

### Iniciar el frontend

```bash
npm run frontend
```

El frontend estará disponible en: http://localhost:5173/

## Formatos de archivo soportados

| Formato | Extensiones | Descripción | Requerimientos |
|---------|-------------|-------------|----------------|
| Texto plano | .txt | Archivos de texto simple | - |
| PDF | .pdf | Documentos Adobe PDF | PyPDF2 |
| Microsoft Word | .docx, .doc | Documentos de texto enriquecido | python-docx |
| Microsoft Excel | .xlsx, .xls | Hojas de cálculo | openpyxl |
| Microsoft PowerPoint | .pptx, .ppt | Presentaciones | python-pptx |

## Solución de problemas

### Errores con Excel o PowerPoint

Si encuentras errores al procesar archivos Excel o PowerPoint:

1. Verifica que Python esté instalado y disponible en tu PATH
2. Instala las dependencias de Python necesarias:
   ```bash
   pip install openpyxl python-pptx
   ```
3. Si usas un comando personalizado para Python (como `python3`), configúralo en el archivo `.env`:
   ```
   PYTHON_CMD=python3
   ```

### Archivos no indexados

- Asegúrate de que los archivos estén en la carpeta correcta (definida en `DOCUMENTS_DIR`)
- Verifica que los archivos no estén dañados o protegidos con contraseña
- Para archivos Excel o PowerPoint complejos, puede haber limitaciones en la extracción de contenido

