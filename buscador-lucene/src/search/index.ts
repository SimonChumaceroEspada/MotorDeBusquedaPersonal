import * as lucene from "lucene";
import { processFile } from "../files/fileProcessor";
import fs from "fs-extra";
import path from "path";

const FILES_PATH = process.env.FILES_PATH || "./data/documents";
let index: any[] = [];

async function indexFiles() {
  try {
    const files = await fs.readdir(FILES_PATH);

    for (const file of files) {
      const filePath = path.join(FILES_PATH, file);
      const { text, metadata } = await processFile(filePath);

      index.push({
        type: "file",
        name: metadata.name,
        path: metadata.path,
        content: text,
      });
    }

    console.log("Archivos indexados:", index.length);
  } catch (error) {
    console.error("Error indexando archivos:", error);
  }
}

export function searchFiles(query: string) {
  return index
    .filter((doc) => doc.content.toLowerCase().includes(query.toLowerCase()))
    .map((doc) => ({
      type: "file",
      name: doc.name,
      path: doc.path,
    }));
}


indexFiles();
