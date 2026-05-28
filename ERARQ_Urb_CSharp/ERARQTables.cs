using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;

namespace ERARQ_Urb
{
    /// <summary>
    /// Generación de tablas técnicas y tablas de coordenadas para ERARQ-Urb
    /// Portado desde erarq_tables.lsp
    /// </summary>
    public static class ERARQTables
    {
        private static double _tableSmallH;
        private static double _tableTitleH;

        /// <summary>
        /// Obtiene la altura pequeña actual para tablas
        /// </summary>
        private static double GetTableSmallHeight()
        {
            return _tableSmallH > 0 ? _tableSmallH : ERARQConfig.SmallTextHeight;
        }

        /// <summary>
        /// Obtiene la altura de título actual para tablas
        /// </summary>
        private static double GetTableTitleHeight()
        {
            return _tableTitleH > 0 ? _tableTitleH : ERARQConfig.TitleTextHeight;
        }

        /// <summary>
        /// Factor de escala para tablas según número de filas
        /// </summary>
        private static double GetTableScaleFactor(int rowCount)
        {
            if (rowCount <= 12) return 1.00;
            if (rowCount <= 18) return 0.95;
            if (rowCount <= 25) return 0.90;
            if (rowCount <= 35) return 0.84;
            if (rowCount <= 50) return 0.76;
            return 0.68;
        }

        /// <summary>
        /// Aplica escala a las alturas de texto de tabla
        /// </summary>
        private static void ApplyTableScale(int rowCount)
        {
            double sf = GetTableScaleFactor(rowCount);
            double tf = 0.15 + sf * 0.85; // El título reduce menos

            _tableSmallH = ERARQConfig.SmallTextHeight * sf;
            _tableTitleH = ERARQConfig.TitleTextHeight * tf;
        }

        /// <summary>
        /// Cuenta líneas en un texto con saltos \P
        /// </summary>
        private static int CountTextLines(string text)
        {
            if (string.IsNullOrEmpty(text)) return 1;
            int count = 1;
            int start = 0;
            while ((start = text.IndexOf("\\P", start)) != -1)
            {
                count++;
                start += 2;
            }
            return count;
        }

        /// <summary>
        /// Dibuja una línea horizontal o vertical
        /// </summary>
        private static void DrawGridLine(Point3d p1, Point3d p2, string layerName)
        {
            ERARQUtils.DrawLine(p1, p2, layerName);
        }

        /// <summary>
        /// Especificación de columnas según tipo de tabla
        /// </summary>
        private class TableSpec
        {
            public List<string> Headers { get; set; }
            public List<double> Widths { get; set; }
        }

        /// <summary>
        /// Obtiene la especificación de tabla según configuración
        /// </summary>
        private static TableSpec GetTableTypeSpec()
        {
            double h = GetTableSmallHeight();
            var spec = new TableSpec();

            if (ERARQConfig.TableType == "Simple")
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    spec.Headers = new List<string> { "VERTICE", "ESTE", "NORTE" };
                    spec.Widths = new List<double> { h * 6.3, h * 13.0, h * 13.0 };
                }
                else
                {
                    spec.Headers = new List<string> { "VERTICE" };
                    spec.Widths = new List<double> { h * 6.5 };
                }
            }
            else if (ERARQConfig.TableType == "Rumbos")
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    spec.Headers = new List<string> { "VERTICE", "LADO", "DIST.", "RUMBO", "ESTE", "NORTE" };
                    spec.Widths = new List<double> { h * 6.3, h * 8.8, h * 7.2, h * 14.5, h * 13.0, h * 13.0 };
                }
                else
                {
                    spec.Headers = new List<string> { "VERTICE", "LADO", "DIST.", "RUMBO" };
                    spec.Widths = new List<double> { h * 6.3, h * 8.8, h * 7.2, h * 14.5 };
                }
            }
            else if (ERARQConfig.TableType == "Angulos")
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    spec.Headers = new List<string> { "VERTICE", "LADO", "DIST.", "ANGULO", "ESTE", "NORTE" };
                    spec.Widths = new List<double> { h * 6.3, h * 8.8, h * 7.2, h * 12.0, h * 13.0, h * 13.0 };
                }
                else
                {
                    spec.Headers = new List<string> { "VERTICE", "LADO", "DIST.", "ANGULO" };
                    spec.Widths = new List<double> { h * 6.3, h * 8.8, h * 7.2, h * 12.0 };
                }
            }
            else // Mixta (default)
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    spec.Headers = new List<string> { "VERTICE", "LADO", "DIST.", "ANGULO", "RUMBO", "ESTE", "NORTE" };
                    spec.Widths = new List<double> { h * 6.3, h * 8.8, h * 7.2, h * 12.0, h * 14.5, h * 13.0, h * 13.0 };
                }
                else
                {
                    spec.Headers = new List<string> { "VERTICE", "LADO", "DIST.", "ANGULO", "RUMBO" };
                    spec.Widths = new List<double> { h * 6.3, h * 8.8, h * 7.2, h * 12.0, h * 14.5 };
                }
            }

            return spec;
        }

        /// <summary>
        /// Genera fila de datos para un lado del polígono
        /// </summary>
        private static List<string> GetTableRowForSide(List<Point3d> pts, int i, int n)
        {
            Point3d pPrev = pts[i == 1 ? n - 2 : i - 2];
            Point3d p1 = pts[i - 1];
            Point3d p2 = pts[i == n ? 0 : i];

            double dist = ERARQUtils.GetDistance(p1, p2);
            double azDeg = ERARQUtils.RadToDeg(ERARQUtils.GetAzimuthRad(p1, p2));
            string angTxt = ERARQUtils.FormatDMS(ERARQUtils.GetInternalAngleDeg(pPrev, p1, p2));
            string rumboTxt = ERARQUtils.AzimuthToRumbo(azDeg);

            var row = new List<string>();

            if (ERARQConfig.TableType == "Simple")
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.FormatNumber(p1.X, ERARQConfig.DecCoord));
                    row.Add(ERARQUtils.FormatNumber(p1.Y, ERARQConfig.DecCoord));
                }
                else
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                }
            }
            else if (ERARQConfig.TableType == "Rumbos")
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.GetSideLabel(i, n));
                    row.Add(ERARQUtils.FormatNumber(dist, ERARQConfig.DecDist));
                    row.Add(rumboTxt);
                    row.Add(ERARQUtils.FormatNumber(p1.X, ERARQConfig.DecCoord));
                    row.Add(ERARQUtils.FormatNumber(p1.Y, ERARQConfig.DecCoord));
                }
                else
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.GetSideLabel(i, n));
                    row.Add(ERARQUtils.FormatNumber(dist, ERARQConfig.DecDist));
                    row.Add(rumboTxt);
                }
            }
            else if (ERARQConfig.TableType == "Angulos")
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.GetSideLabel(i, n));
                    row.Add(ERARQUtils.FormatNumber(dist, ERARQConfig.DecDist));
                    row.Add(angTxt);
                    row.Add(ERARQUtils.FormatNumber(p1.X, ERARQConfig.DecCoord));
                    row.Add(ERARQUtils.FormatNumber(p1.Y, ERARQConfig.DecCoord));
                }
                else
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.GetSideLabel(i, n));
                    row.Add(ERARQUtils.FormatNumber(dist, ERARQConfig.DecDist));
                    row.Add(angTxt);
                }
            }
            else // Mixta
            {
                if (ERARQConfig.IncludeEastNorth)
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.GetSideLabel(i, n));
                    row.Add(ERARQUtils.FormatNumber(dist, ERARQConfig.DecDist));
                    row.Add(angTxt);
                    row.Add(rumboTxt);
                    row.Add(ERARQUtils.FormatNumber(p1.X, ERARQConfig.DecCoord));
                    row.Add(ERARQUtils.FormatNumber(p1.Y, ERARQConfig.DecCoord));
                }
                else
                {
                    row.Add(ERARQUtils.GetVertexLabel(i));
                    row.Add(ERARQUtils.GetSideLabel(i, n));
                    row.Add(ERARQUtils.FormatNumber(dist, ERARQConfig.DecDist));
                    row.Add(angTxt);
                    row.Add(rumboTxt);
                }
            }

            return row;
        }

        /// <summary>
        /// Dibuja el bloque de título de tabla
        /// </summary>
        private static double DrawTableTitleBlock(Point3d ins, double totalW, string title1, string title2, string layerName)
        {
            double x = ins.X;
            double y = ins.Y;
            double titleH = GetTableTitleHeight();
            double smallH = GetTableSmallHeight();
            int n2 = CountTextLines(title2);

            double h1 = titleH * 1.70;
            double h2 = smallH * (1.80 + (n2 - 1) * 1.30);
            double totalH = h1 + h2;

            // Marco exterior
            DrawGridLine(new Point3d(x, y, 0), new Point3d(x + totalW, y, 0), layerName);
            DrawGridLine(new Point3d(x + totalW, y, 0), new Point3d(x + totalW, y - totalH, 0), layerName);
            DrawGridLine(new Point3d(x + totalW, y - totalH, 0), new Point3d(x, y - totalH, 0), layerName);
            DrawGridLine(new Point3d(x, y - totalH, 0), new Point3d(x, y, 0), layerName);

            // Separador
            DrawGridLine(new Point3d(x, y - h1, 0), new Point3d(x + totalW, y - h1, 0), layerName);

            // Título principal
            ERARQUtils.DrawMText(
                new Point3d(x + totalW / 2.0, y - h1 / 2.0, 0),
                totalW * 0.95,
                title1,
                layerName,
                AttachmentAlignment.MiddleCenter,
                titleH
            );

            // Subtítulo multilínea
            ERARQUtils.DrawMText(
                new Point3d(x + totalW / 2.0, y - h1 - h2 / 2.0, 0),
                totalW * 0.95,
                title2,
                layerName,
                AttachmentAlignment.MiddleCenter,
                smallH * 1.02
            );

            return y - totalH;
        }

        /// <summary>
        /// Dibuja la grilla de tabla
        /// </summary>
        private static void DrawTableGrid(Point3d ins, double totalW, int totalRows, double rowH, string layerName)
        {
            double x = ins.X;
            double y = ins.Y;
            double bottom = y - rowH * totalRows;

            DrawGridLine(new Point3d(x, y, 0), new Point3d(x + totalW, y, 0), layerName);
            DrawGridLine(new Point3d(x + totalW, y, 0), new Point3d(x + totalW, bottom, 0), layerName);
            DrawGridLine(new Point3d(x + totalW, bottom, 0), new Point3d(x, bottom, 0), layerName);
            DrawGridLine(new Point3d(x, bottom, 0), new Point3d(x, y, 0), layerName);

            // Líneas horizontales
            for (int r = 1; r < totalRows; r++)
            {
                DrawGridLine(
                    new Point3d(x, y - rowH * r, 0),
                    new Point3d(x + totalW, y - rowH * r, 0),
                    layerName
                );
            }
        }

        /// <summary>
        /// Dibuja celda con texto centrado
        /// </summary>
        private static void DrawCellTextCenter(double x, double y, double w, double h, string text, string layerName)
        {
            Point3d pt = new Point3d(x + w / 2.0, y - h / 2.0, 0);
            ERARQUtils.DrawMText(pt, w * 0.88, text, layerName, AttachmentAlignment.MiddleCenter, GetTableSmallHeight());
        }

        /// <summary>
        /// Dibuja tabla completa con encabezados y filas
        /// </summary>
        private static void DrawTableStable(Point3d ins, List<string> headers, List<List<string>> rows, 
            List<double> widths, string layerName)
        {
            double x = ins.X;
            double y = ins.Y;
            double rowH = GetTableSmallHeight() * 2.85;
            double totalW = widths.Sum();
            int totalRows = rows.Count + 1;

            DrawTableGrid(ins, totalW, totalRows, rowH, layerName);

            // Líneas verticales
            double colX = x;
            for (int c = 0; c < widths.Count - 1; c++)
            {
                colX += widths[c];
                DrawGridLine(
                    new Point3d(colX, y, 0),
                    new Point3d(colX, y - rowH * totalRows, 0),
                    layerName
                );
            }

            // Encabezados
            colX = x;
            for (int c = 0; c < headers.Count; c++)
            {
                double cellW = widths[c];
                DrawCellTextCenter(colX, y, cellW, rowH, headers[c], layerName);
                colX += cellW;
            }

            // Datos
            for (int r = 0; r < rows.Count; r++)
            {
                double rowY = y - rowH * (r + 1);
                colX = x;

                for (int c = 0; c < rows[r].Count; c++)
                {
                    double cellW = widths[c];
                    DrawCellTextCenter(colX, rowY, cellW, rowH, rows[r][c], layerName);
                    colX += cellW;
                }
            }
        }

        /// <summary>
        /// Dibuja bloque de resumen (área, hectáreas, perímetro)
        /// </summary>
        private static void DrawSummaryBlock(Point3d pt, double area, double hectares, double perimeter, string layerName)
        {
            double h = GetTableSmallHeight();
            double lead = h * 1.70;
            double w = h * 22.0;

            Point3d p1 = pt;
            Point3d p2 = new Point3d(pt.X, pt.Y - lead, 0);
            Point3d p3 = new Point3d(pt.X, pt.Y - lead * 2.0, 0);

            ERARQUtils.DrawMText(p1, w, $"Area: {ERARQUtils.FormatNumber(area, ERARQConfig.DecArea)} m2", 
                layerName, AttachmentAlignment.MiddleLeft, h);
            ERARQUtils.DrawMText(p2, w, $"Hectareas: {hectares.ToString("F2")} ha", 
                layerName, AttachmentAlignment.MiddleLeft, h);
            ERARQUtils.DrawMText(p3, w, $"Perimetro: {ERARQUtils.FormatNumber(perimeter, ERARQConfig.DecDist)} m", 
                layerName, AttachmentAlignment.MiddleLeft, h);
        }

        /// <summary>
        /// Comando para generar tabla técnica de parcela
        /// </summary>
        [CommandMethod("ERARQ_DATOS")]
        public static void ParcelTechTableCommand()
        {
            var doc = ERARQUtils.GetDocument();
            var ed = ERARQUtils.GetEditor();
            if (ed == null) return;

            var pline = ERARQUtils.SelectClosedPolyline();
            if (pline == null) return;

            try
            {
                // Asegurar capas base si existen
                // ERARQLayers.EnsureBaseLayers(); // Implementar cuando se cree ERARQLayers

                // Poner capa de parcela
                pline.Layer = "ERARQ_PARCELA"; // Asumiendo que existe esta función

                var pts = ERARQUtils.GetVertices(pline);
                int n = pts.Count;
                double area = ERARQUtils.GetPolylineArea(pline);
                double per = ERARQUtils.GetPolylinePerimeter(pline);
                double ha = ERARQUtils.AreaToHectares(area);

                string lay = "ERARQ_TABLAS"; // Capa de tablas técnicas
                ERARQUtils.EnsureLayer(lay);

                // Aplicar escala
                ApplyTableScale(n);

                // Generar filas
                var rows = new List<List<string>>();
                for (int i = 1; i <= n; i++)
                {
                    rows.Add(GetTableRowForSide(pts, i, n));
                }

                // Obtener especificación
                var spec = GetTableTypeSpec();
                var headers = spec.Headers;
                var widths = spec.Widths;
                double totalW = widths.Sum();

                if (ERARQConfig.DrawTables)
                {
                    var promptResult = ed.GetPoint("\nPunto de insercion para tabla tecnica: ");
                    if (promptResult.Status == PromptStatus.OK)
                    {
                        Point3d ins = promptResult.Value;

                        // Dibujar título
                        double gridY = DrawTableTitleBlock(
                            ins,
                            totalW,
                            ERARQConfig.TableTitle,
                            $"{ERARQConfig.ParcelName}\\P{ERARQConfig.CoordTitle}",
                            lay
                        );

                        // Dibujar tabla
                        DrawTableStable(
                            new Point3d(ins.X, gridY, 0),
                            headers,
                            rows,
                            widths,
                            lay
                        );

                        // Dibujar resumen si está configurado
                        if (ERARQConfig.IncludeSummary)
                        {
                            Point3d sumPt = new Point3d(ins.X, gridY - rows.Count * GetTableSmallHeight() * 2.85 - GetTableSmallHeight() * 5, 0);
                            DrawSummaryBlock(sumPt, area, ha, per, lay);
                        }

                        ed.WriteMessage($"\nTabla técnica generada. Area: {ha:F2} ha, Perimetro: {per:F2} m");
                    }
                }
            }
            finally
            {
                pline.Dispose();
            }
        }

        /// <summary>
        /// Inicializa variables de tabla
        /// </summary>
        public static void Initialize()
        {
            _tableSmallH = 0;
            _tableTitleH = 0;
        }
    }
}
