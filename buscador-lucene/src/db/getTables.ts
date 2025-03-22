import { query } from "./database";

async function getTables() {
  try {
    const res = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public';
    `);
    console.log("Tablas en la base de datos:", res.rows);
  } catch (error) {
    console.error("Error obteniendo tablas:", error);
  }
}

getTables();
