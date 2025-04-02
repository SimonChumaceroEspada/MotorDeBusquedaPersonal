import fs from "fs-extra";
import path from "path";
import pdfParse from "pdf-parse";
import mammoth from "mammoth";
import textract from "textract";
import { execSync } from "child_process";
import dotenv from "dotenv";

dotenv.config();

const DOCUMENTS_DIR = process.env.DOCUMENTS_DIR || "./documents";
const PYTHON_EXTRACT_SCRIPT = path.join(__dirname, "..", "..", "python", "extract_office.py");
const PYTHON_CMD = process.env.PYTHON_CMD || "python";

export async function processFile(filePath: string): Promise<{ text: string; metadata: any }> {
  const ext = path.extname(filePath).toLowerCase();
  let text = "";

  try {
    if (ext === ".txt") {
      text = await fs.readFile(filePath, "utf8");
    } else if (ext === ".pdf") {
      const data = await pdfParse(await fs.readFile(filePath));
      text = data.text;
    } else if (ext === ".docx") {
      const data = await mammoth.extractRawText({ path: filePath });
      text = data.value;
    } else if (ext === ".xlsx" || ext === ".xls" || ext === ".pptx" || ext === ".ppt") {
      // Usar Python para extraer contenido de archivos Excel y PowerPoint
      text = await extractOfficeContent(filePath, ext);
    } else {
      text = await new Promise<string>((resolve, reject) => {
        textract.fromFileWithPath(filePath, (error, text) => {
          if (error) reject(error);
          else resolve(text);
        });
      });
    }
  } catch (error) {
    console.error(`Error procesando ${filePath}:`, error);
  }

  return { text, metadata: { name: path.basename(filePath), path: filePath, type: getFileType(ext) } };
}

function getFileType(extension: string): string {
  switch (extension) {
    case '.xlsx':
    case '.xls':
      return 'excel';
    case '.pptx':
    case '.ppt':
      return 'powerpoint';
    case '.docx':
    case '.doc':
      return 'word';
    case '.pdf':
      return 'pdf';
    case '.txt':
      return 'text';
    default:
      return 'other';
  }
}

async function extractOfficeContent(filePath: string, ext: string): Promise<string> {
  try {
    console.log(`Extrayendo contenido de ${path.basename(filePath)} usando Python...`);
    
    // Ejecutar el script de Python para extraer el contenido
    const cmd = `${PYTHON_CMD} "${PYTHON_EXTRACT_SCRIPT}" "${filePath}" "${ext}"`;
    const output = execSync(cmd, { encoding: 'utf8' });
    
    if (!output || output.trim().length === 0) {
      console.warn(`No se pudo extraer contenido de: ${filePath}`);
      return "";
    }
    
    console.log(`Contenido extraído exitosamente de ${path.basename(filePath)}: ${output.length} caracteres`);
    return output || "";
  } catch (error) {
    console.error(`Error extrayendo contenido de ${filePath}:`, error);
    return "";
  }
}
