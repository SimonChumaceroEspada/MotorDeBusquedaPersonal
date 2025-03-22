import * as lucene from "lucene";
import { query } from "../db/database";

let index: any[] = [];

async function indexDatabase() {
  try {
    const tablesRes = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public';
    `);

    for (const { table_name } of tablesRes.rows) {
      const dataRes = await query(`SELECT * FROM ${table_name}`);

      for (const row of dataRes.rows) {
        index.push({
          table: table_name,
          ...row,
        });
      }
    }

    console.log("Indexación completa:", index.length, "registros indexados.");
  } catch (error) {
    console.error("Error en la indexación:", error);
  }
}

indexDatabase();
