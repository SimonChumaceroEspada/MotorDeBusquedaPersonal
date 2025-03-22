import fs from "fs-extra";
import path from "path";
import pdfParse from "pdf-parse";
import mammoth from "mammoth";
import textract from "textract";

const FILES_PATH = process.env.FILES_PATH || "./data/documents";

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

  return { text, metadata: { name: path.basename(filePath), path: filePath } };
}
