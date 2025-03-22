import express from "express";
import { searchDatabaseAndDocuments } from "./search/databaseSearch";
import cors from "cors";
import path from "path";

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Punto de entrada principal
app.get("/", (req, res) => {
  res.send(`
    <h1>Buscador</h1>
    <p>API de búsqueda en base de datos y documentos</p>
    <p>Use /search?q=término para realizar búsquedas</p>
  `);
});

// Endpoint de búsqueda
app.get("/search", async (req, res) => {
  try {
    const query = req.query.q as string;

    if (!query) {
      return res.status(400).json({ 
        error: "Query parameter 'q' is required",
        usage: "/search?q=término" 
      });
    }

    console.log(`Nueva búsqueda: "${query}"`);
    
    // Realiza la búsqueda en la base de datos y en los documentos
    const results = await searchDatabaseAndDocuments(query);
    
    res.json({ 
      query,
      total: results.length,
      resultados: results 
    });
  } catch (error) {
    console.error("Error en la búsqueda:", error);
    res.status(500).json({ 
      error: "Error en la búsqueda",
      mensaje: error instanceof Error ? error.message : "Error desconocido"
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Try http://localhost:${PORT}/search?q=test`);
});
