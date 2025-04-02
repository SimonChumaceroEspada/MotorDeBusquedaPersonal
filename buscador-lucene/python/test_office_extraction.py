#!/usr/bin/env python
"""
Script para probar la extracción de contenido de archivos Excel y PowerPoint
Uso: python test_office_extraction.py <ruta_archivo>
"""

import sys
import os
from extract_office import extract_excel_content, extract_ppt_content

def main():
    if len(sys.argv) < 2:
        print("Error: Se requiere la ruta de un archivo")
        print("Uso: python test_office_extraction.py <ruta_archivo>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    if not os.path.exists(file_path):
        print(f"Error: No se encontró el archivo {file_path}")
        sys.exit(1)
    
    # Determinar el tipo de archivo por su extensión
    _, ext = os.path.splitext(file_path)
    ext = ext.lower()
    
    try:
        if ext in ['.xlsx', '.xls']:
            print(f"Procesando archivo Excel: {file_path}")
            content = extract_excel_content(file_path)
            print("\n--- CONTENIDO EXTRAÍDO DE EXCEL ---")
            print(content)
            print(f"\nLongitud del contenido: {len(content)} caracteres")
        elif ext in ['.pptx', '.ppt']:
            print(f"Procesando archivo PowerPoint: {file_path}")
            content = extract_ppt_content(file_path)
            print("\n--- CONTENIDO EXTRAÍDO DE POWERPOINT ---")
            print(content)
            print(f"\nLongitud del contenido: {len(content)} caracteres")
        else:
            print(f"Formato no soportado: {ext}")
            print("Este script solo procesa archivos Excel (.xlsx, .xls) y PowerPoint (.pptx, .ppt)")
            sys.exit(1)
        
        print("\nExtracción completada con éxito")
    except Exception as e:
        print(f"Error al procesar el archivo: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
