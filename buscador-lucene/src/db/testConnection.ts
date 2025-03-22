import { query } from "./database";

async function testConnection() {
  try {
    const res = await query("SELECT NOW()");
    console.log("Conexión exitosa:", res.rows[0]);
  } catch (error) {
    console.error("Error al conectar con PostgreSQL:", error);
  }
}

testConnection();
