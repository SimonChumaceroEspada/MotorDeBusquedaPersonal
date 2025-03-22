import { query } from "./database";

async function getTableData(tableName: string) {
  try {
    const res = await query(`SELECT * FROM ${tableName} LIMIT 10`);
    console.log(`Datos de la tabla ${tableName}:`, res.rows);
  } catch (error) {
    console.error(`Error obteniendo datos de ${tableName}:`, error);
  }
}

// Cambia el nombre de la tabla para probar
getTableData("nombre_de_tu_tabla");
