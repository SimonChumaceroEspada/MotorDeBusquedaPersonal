import { Pool } from "pg";
import fs from "fs-extra";
import path from "path";
import pdf from "pdf-parse";
import docx4js from "docx4js";
import dotenv from "dotenv";

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

// Asegurar que la carpeta de documentos exista
try {
  if (!fs.existsSync(DOCUMENTS_DIR)) {
    fs.mkdirSync(DOCUMENTS_DIR, { recursive: true });
    console.log(`Carpeta de documentos creada en: ${DOCUMENTS_DIR}`);
  }
} catch (error) {
  console.error("Error al verificar/crear la carpeta de documentos:", error);
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
        let content = "";

        try {
          if (ext === ".txt") {
            content = await fs.readFile(filePath, "utf-8");
          } else if (ext === ".pdf") {
            const pdfData = await pdf(await fs.readFile(filePath));
            content = pdfData.text;
          } else if (ext === ".docx") {
            const doc = await docx4js.load(filePath);
            content = doc.getFullText();
          } else {
            // Log de tipos de archivo no soportados
            console.log(`Tipo de archivo no soportado: ${ext}`);
            continue;
          }

          if (content.toLowerCase().includes(query.toLowerCase()) && !nameMatch) {
            results.push({ 
              tabla: "documento", 
              columna: "contenido", 
              resultado: `Archivo: ${file} - ${content.substring(0, 200)}...` 
            });
            console.log(`Coincidencia en contenido: ${file}`);
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
