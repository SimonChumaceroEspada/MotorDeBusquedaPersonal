import { Pool } from "pg";
import fs from "fs-extra";
import path from "path";
import pdf from "pdf-parse";
import docx4js from "docx4js";
import dotenv from "dotenv";
import mammoth from "mammoth"; // Añadimos mammoth para mejor soporte de docx
import { execSync } from "child_process"; // Para ejecutar los scripts de Python

dotenv.config();

// Usar pool de database.ts si está disponible
const pool = new Pool({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_NAME || "dbpostgrado3",
  password: process.env.DB_PASSWORD || "postgres",
  port: Number(process.env.DB_PORT) || 5432,
});

// 📂 Usar una ruta absoluta más predecible para los documentos
const DOCUMENTS_DIR = process.env.DOCUMENTS_DIR || path.join(__dirname, "..", "..", "documents");
// Ruta al script de Python para extraer contenido de Excel y PowerPoint
const PYTHON_EXTRACT_SCRIPT = path.join(__dirname, "..", "..", "python", "extract_office.py");
// Comando Python (puede configurarse en .env)
const PYTHON_CMD = process.env.PYTHON_CMD || "python";

// Asegurar que la carpeta de documentos exista
try {
  if (!fs.existsSync(DOCUMENTS_DIR)) {
    fs.mkdirSync(DOCUMENTS_DIR, { recursive: true });
    console.log(`Carpeta de documentos creada en: ${DOCUMENTS_DIR}`);
  }
} catch (error) {
  console.error("Error al verificar/crear la carpeta de documentos:", error);
}

// Función para extraer contenido de archivos Excel y PowerPoint usando Python
async function extractOfficeContent(filePath: string, ext: string, query?: string): Promise<string | { content: string, matches: any[] }> {
  try {
    console.log(`Extrayendo contenido de ${path.basename(filePath)} usando Python...`);
    
    // Preparar el comando Python con argumentos
    let cmd = `${PYTHON_CMD} "${PYTHON_EXTRACT_SCRIPT}" "${filePath}" "${ext}"`;
    if (query) {
      cmd += ` "${query}"`;
    }
    
    // Ejecutar el script de Python y obtener la salida
    const output = execSync(cmd, { encoding: 'utf8' });
    
    if (!output || output.trim().length === 0) {
      console.log(`No se pudo extraer contenido de: ${filePath}`);
      return "";
    }
    
    console.log(`Contenido extraído de ${path.basename(filePath)} (${output.length} caracteres)`);
    
    // Si se proporcionó una consulta, intentamos parsear el JSON de resultados
    if (query) {
      try {
        return JSON.parse(output);
      } catch (parseError) {
        console.error(`Error al parsear resultado JSON de Python:`, parseError);
        return output;
      }
    }
    
    return output;
  } catch (error) {
    console.error(`Error al extraer contenido de ${filePath}:`, error);
    return "";
  }
}

export async function searchDatabaseAndDocuments(query: string) {
  try {
    console.log(`Iniciando búsqueda para: "${query}"`);
    console.log(`Carpeta de documentos: ${DOCUMENTS_DIR}`);
    
    let results: any[] = [];

    // 🔍 1️⃣ BUSCAR EN LA BASE DE DATOS
    console.log("Buscando en base de datos...");
    const tablesAndColumns = await pool.query(`
      SELECT table_name, column_name, data_type
      FROM information_schema.columns
      WHERE table_schema = 'public'
    `);

    let searchQuery = "";

    tablesAndColumns.rows.forEach((row, index) => {
      let columnCast = `${row.column_name}::text`;

      if (row.data_type === "jsonb" || row.data_type === "json") {
        columnCast = `${row.column_name}::jsonb #>> '{}'`;
      } else if (row.data_type.startsWith("int") || row.data_type.startsWith("numeric")) {
        columnCast = `CAST(${row.column_name} AS TEXT)`;
      }

      searchQuery += `SELECT '${row.table_name}' AS tabla, '${row.column_name}' AS columna, ${columnCast} AS resultado 
      FROM ${row.table_name} WHERE ${columnCast} ILIKE '%${query}%'`;

      if (index < tablesAndColumns.rows.length - 1) {
        searchQuery += " UNION ALL ";
      }
    });

    if (searchQuery !== "") {
      const searchResults = await pool.query(searchQuery);
      results = results.concat(searchResults.rows);
      console.log(`Encontrados ${searchResults.rowCount} resultados en la base de datos`);
    }

    // 🔍 2️⃣ BUSCAR EN DOCUMENTOS
    if (fs.existsSync(DOCUMENTS_DIR)) {
      console.log("Buscando en documentos...");
      const files = await fs.readdir(DOCUMENTS_DIR);
      console.log(`Documentos encontrados: ${files.length}`);

      for (const file of files) {
        const filePath = path.join(DOCUMENTS_DIR, file);
        const stats = await fs.stat(filePath);
        
        // Omitir carpetas
        if (!stats.isFile()) continue;
        
        const ext = path.extname(file).toLowerCase();
        const fileName = path.basename(file).toLowerCase();

        console.log(`Procesando archivo: ${file} (${ext})`);

        // Comprobar si el nombre del archivo contiene la consulta
        const nameMatch = fileName.includes(query.toLowerCase());
        if (nameMatch) {
          results.push({ 
            tabla: "documento", 
            columna: "nombre_archivo", 
            resultado: `Archivo: ${file}` 
          });
          console.log(`Coincidencia en nombre: ${file}`);
        }

        // Luego buscar en el contenido
        try {
          if (ext === ".txt") {
            const content = await fs.readFile(filePath, "utf-8");
            console.log(`Contenido TXT leído: ${content.length} caracteres`);
            if (content && content.toLowerCase().includes(query.toLowerCase())) {
              addTextContentResults(content, query, file, results);
            }
          } else if (ext === ".pdf") {
            const pdfData = await pdf(await fs.readFile(filePath));
            const content = pdfData.text;
            console.log(`Contenido PDF extraído: ${content.length} caracteres`);
            if (content && content.toLowerCase().includes(query.toLowerCase())) {
              addTextContentResults(content, query, file, results);
            }
          } else if (ext === ".docx" || ext === ".doc") {
            try {
              const result = await mammoth.extractRawText({ path: filePath });
              const content = result.value;
              console.log(`Contenido DOCX extraído con mammoth: ${content.length} caracteres`);
              if (content && content.toLowerCase().includes(query.toLowerCase())) {
                addTextContentResults(content, query, file, results);
              }
            } catch (mammothError) {
              console.log(`Error en mammoth, intentando con docx4js: ${mammothError}`);
              try {
                const doc = await docx4js.load(filePath);
                const content = doc.getFullText();
                console.log(`Contenido DOCX extraído con docx4js: ${content.length} caracteres`);
                if (content && content.toLowerCase().includes(query.toLowerCase())) {
                  addTextContentResults(content, query, file, results);
                }
              } catch (docx4jsError) {
                console.error(`Error procesando DOCX con docx4js: ${docx4jsError}`);
                throw new Error(`No se pudo procesar el archivo DOCX: ${file}`);
              }
            }
          } else if (ext === ".xlsx" || ext === ".xls") {
            const extracted = await extractOfficeContent(filePath, ext, query);
            if (typeof extracted === 'object' && extracted.matches) {
              console.log(`Encontradas ${extracted.matches.length} coincidencias en Excel: ${file}`);
              extracted.matches.forEach((match: any) => {
                results.push({
                  tabla: "documento",
                  columna: "contenido",
                  resultado: `Archivo Excel: ${file} (${match.location}) - ${match.excerpt}`
                });
              });
            } else if (typeof extracted === 'string') {
              const content = extracted;
              if (content && content.toLowerCase().includes(query.toLowerCase())) {
                addTextContentResults(content, query, file, results);
              }
            }
          } else if (ext === ".pptx" || ext === ".ppt") {
            const extracted = await extractOfficeContent(filePath, ext, query);
            if (typeof extracted === 'object' && extracted.matches) {
              console.log(`Encontradas ${extracted.matches.length} coincidencias en PowerPoint: ${file}`);
              extracted.matches.forEach((match: any) => {
                results.push({
                  tabla: "documento",
                  columna: "contenido",
                  resultado: `Archivo PowerPoint: ${file} (${match.location}) - ${match.excerpt}`
                });
              });
            } else if (typeof extracted === 'string') {
              const content = extracted;
              if (content && content.toLowerCase().includes(query.toLowerCase())) {
                addTextContentResults(content, query, file, results);
              }
            }
          } else {
            console.log(`Tipo de archivo no soportado: ${ext}`);
            continue;
          }
        } catch (error) {
          console.error(`Error procesando archivo ${file}:`, error);
        }
      }
    } else {
      console.log(`La carpeta de documentos no existe: ${DOCUMENTS_DIR}`);
    }

    console.log(`Total de resultados encontrados: ${results.length}`);
    return results;
  } catch (error) {
    console.error("Error searching database/documents:", error);
    throw error;
  }
}

// Función auxiliar para agregar resultados de búsqueda de contenido de texto
function addTextContentResults(content: string, query: string, file: string, results: any[]) {
  const contentLower = content.toLowerCase();
  const queryLower = query.toLowerCase();
  let startPos = 0;
  let foundPos;
  let occurrences = 0;
  
  while ((foundPos = contentLower.indexOf(queryLower, startPos)) !== -1) {
    occurrences++;
    const startExtract = Math.max(0, foundPos - 50);
    const endExtract = Math.min(content.length, foundPos + queryLower.length + 50);
    const excerpt = content.substring(startExtract, endExtract);

    results.push({ 
      tabla: "documento", 
      columna: "contenido", 
      resultado: `Archivo: ${file} - ${excerpt}` 
    });
    
    startPos = foundPos + queryLower.length;
  }
  
  console.log(`Encontradas ${occurrences} coincidencias en: ${file}`);
}
