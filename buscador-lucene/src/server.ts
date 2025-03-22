import express from "express";
import { searchDatabaseAndDocuments } from "./search/databaseSearch";
import cors from "cors";
import path from "path";

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

// Endpoint de búsqueda
app.get("/api/search", async (req, res) => {
  try {
    const query = req.query.q as string;

    if (!query) {
      return res.status(400).json({ 
        error: "Query parameter 'q' is required",
        usage: "/api/search?q=término" 
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

// Ruta principal redirige al index.html
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
