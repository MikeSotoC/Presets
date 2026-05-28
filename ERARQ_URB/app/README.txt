ERArq-Urb v1
============

Sistema base AutoLISP + DCL para urbanismo y parcelación.

ARCHIVOS
--------
- erarq_main.lsp       -> cargador principal
- erarq_config.lsp     -> configuración global
- erarq_utils.lsp      -> utilidades geométricas y de dibujo
- erarq_tables.lsp     -> tablas técnicas y tablas de áreas
- erarq_core.lsp       -> comandos base de parcela
- erarq_labels.lsp     -> etiquetado de vértices y numeración de lotes
- erarq_export.lsp     -> exportación CSV
- erarq_division.lsp   -> base del módulo de división exacta
- erarq_ui.lsp         -> interfaz y despacho
- erarq_main.dcl       -> diálogo principal

FUNCIONES INCLUIDAS
-------------------
1. Datos técnicos de parcela
2. Tabla de coordenadas
3. Etiquetado de vértices
4. Numeración de lotes
5. Tabla de áreas de lotes
6. Exportación CSV de coordenadas
7. Exportación CSV de áreas
8. Entrada profesional para división exacta futura

REQUISITOS
----------
- Entidades base: LWPOLYLINE cerradas
- Todos los archivos deben estar en una carpeta incluida en Support File Search Path

INSTALACIÓN
-----------
1. Colocar todos los archivos en una carpeta.
2. Agregar la carpeta a Support File Search Path.
3. Cargar erarq_main.lsp con APPLOAD.
4. Ejecutar el comando ERARQ.

COMANDOS DIRECTOS
-----------------
ERARQ
ERARQ_DATOS
ERARQ_COORDS
ERARQ_VERTICES
ERARQ_LOTES
ERARQ_AREAS
ERARQ_EXPORT_COORDS
ERARQ_EXPORT_AREAS
ERARQ_DIVIDIR