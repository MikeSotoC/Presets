using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using acApp = Autodesk.AutoCAD.ApplicationServices.Application;

[assembly: CommandClass(typeof(ERARQ_Urb.ERARQCommands))]

namespace ERARQ_Urb
{
    /// <summary>
    /// Configuración global del sistema ERARQ-Urb para AutoCAD
    /// </summary>
    public static class ERARQConfig
    {
        // Datos generales
        public static string Project { get; set; } = "Proyecto Urbano";
        public static string ParcelName { get; set; } = "Parcela 01";
        public static string LotPrefix { get; set; } = "L";
        public static int StartNumber { get; set; } = 1;
        public static string VertexPrefix { get; set; } = "V";

        // Formato numérico
        public static int DecCoord { get; set; } = 3;
        public static int DecArea { get; set; } = 2;
        public static int DecDist { get; set; } = 2;
        public static int DecAng { get; set; } = 0;

        // Presentación / hoja
        public static string SheetSize { get; set; } = "A3";
        public static string PrintProfile { get; set; } = "Normal";
        public static string PlotStyle { get; set; } = "ERARQ_PRESENTACION.ctb";
        public static bool AutoTextScale { get; set; } = true;

        // Alturas de texto
        public static double TextHeight { get; set; } = 2.50;
        public static double SmallTextHeight { get; set; } = 1.88;
        public static double TitleTextHeight { get; set; } = 3.00;

        // Capa general
        public static string Layer { get; set; } = "ERARQ";

        // Toggles base
        public static bool DrawTexts { get; set; } = true;
        public static bool DrawTables { get; set; } = true;
        public static bool CreatePolys { get; set; } = true;
        public static bool DrawArea { get; set; } = true;
        public static bool DrawPerim { get; set; } = true;
        public static bool DrawDistances { get; set; } = true;
        public static bool DrawAngles { get; set; } = true;

        // Documentación específica
        public static bool DocVerticesParcel { get; set; } = true;
        public static bool DocRumbosParcel { get; set; } = true;
        public static bool DocNumberLots { get; set; } = true;
        public static bool DocVerticesLots { get; set; } = true;
        public static bool DocRumbosLots { get; set; } = true;

        // Grilla
        public static double GridDx { get; set; } = 100.0;
        public static double GridDy { get; set; } = 100.0;
        public static string GridMode { get; set; } = "E";

        // Documentación
        public static bool DrawDistances { get; set; } = true;
        public static bool DrawAngles { get; set; } = true;
        public static bool DrawArea { get; set; } = true;
        public static bool DrawPerim { get; set; } = true;
        public static bool DocVerticesParcel { get; set; } = true;
        public static bool DocRumbosParcel { get; set; } = true;
        public static bool DocNumberLots { get; set; } = true;
        public static bool DocVerticesLots { get; set; } = true;
        public static bool DocRumbosLots { get; set; } = true;

        // Tabla técnica
        public static string TableType { get; set; } = "Mixta";
        public static string TableTitle { get; set; } = "DATOS TECNICOS";
        public static string CoordTitle { get; set; } = "WGS 84";
        public static bool IncludeEastNorth { get; set; } = true;
        public static bool IncludeSummary { get; set; } = true;

        /// <summary>
        /// Inicializa la configuración con valores por defecto
        /// </summary>
        public static void Initialize()
        {
            Project = "Proyecto Urbano";
            ParcelName = "Parcela 01";
            LotPrefix = "L";
            StartNumber = 1;
            VertexPrefix = "V";

            DecCoord = 3;
            DecArea = 2;
            DecDist = 2;
            DecAng = 0;

            SheetSize = "A3";
            PrintProfile = "Normal";
            PlotStyle = "ERARQ_PRESENTACION.ctb";
            AutoTextScale = true;

            ApplyTextProfile();

            Layer = "ERARQ";

            DrawTexts = true;
            DrawTables = true;
            CreatePolys = true;

            GridDx = 100.0;
            GridDy = 100.0;
            GridMode = "E";

            DrawDistances = true;
            DrawAngles = true;
            DrawArea = true;
            DrawPerim = true;
            DocVerticesParcel = true;
            DocRumbosParcel = true;
            DocNumberLots = true;
            DocVerticesLots = true;
            DocRumbosLots = true;

            TableType = "Mixta";
            TableTitle = "DATOS TECNICOS";
            CoordTitle = "WGS 84";
            IncludeEastNorth = true;
            IncludeSummary = true;
        }

        /// <summary>
        /// Aplica el perfil de texto según tamaño de hoja y perfil
        /// </summary>
        public static void ApplyTextProfile()
        {
            double baseHeight = GetSheetBaseTextHeight(SheetSize);
            double factor = GetProfileFactor(PrintProfile);

            TextHeight = baseHeight * factor;
            SmallTextHeight = TextHeight * 0.75;
            TitleTextHeight = TextHeight * 1.20;
        }

        private static double GetSheetBaseTextHeight(string sheet)
        {
            switch (sheet)
            {
                case "A4": return 2.00;
                case "A3": return 2.50;
                case "A2": return 3.50;
                case "A1": return 5.00;
                case "A0": return 7.00;
                default: return 2.50;
            }
        }

        private static double GetProfileFactor(string profile)
        {
            switch (profile)
            {
                case "Compacto": return 0.90;
                case "Presentacion": return 1.20;
                default: return 1.00;
            }
        }

        public static bool IsValidSheetSize(string s)
        {
            return new[] { "A4", "A3", "A2", "A1", "A0" }.Contains(s);
        }

        public static bool IsValidProfile(string s)
        {
            return new[] { "Compacto", "Normal", "Presentacion" }.Contains(s);
        }

        public static bool IsValidTableType(string s)
        {
            return new[] { "Simple", "Rumbos", "Angulos", "Mixta" }.Contains(s);
        }
    }

    /// <summary>
    /// Utilidades geométricas y de dibujo para ERARQ-Urb
    /// </summary>
    public static class ERARQUtils
    {
        /// <summary>
        /// Obtiene el documento activo de AutoCAD
        /// </summary>
        public static Document GetDocument()
        {
            return acApp.DocumentManager.MdiActiveDocument;
        }

        /// <summary>
        /// Obtiene la base de datos activa
        /// </summary>
        public static Database GetDatabase()
        {
            return GetDocument()?.Database;
        }

        /// <summary>
        /// Obtiene el editor activo
        /// </summary>
        public static Editor GetEditor()
        {
            return GetDocument()?.Editor;
        }

        /// <summary>
        /// Convierte un punto 2D a Point3d
        /// </summary>
        public static Point3d ToPoint3d(double x, double y)
        {
            return new Point3d(x, y, 0.0);
        }

        /// <summary>
        /// Formatea un número como cadena con decimales especificados
        /// </summary>
        public static string FormatNumber(double value, int decimals)
        {
            return value.ToString($"F{decimals}");
        }

        /// <summary>
        /// Formatea un entero como cadena
        /// </summary>
        public static string FormatInt(int value)
        /// </summary>
        {
            return value.ToString();
        }

        /// <summary>
        /// Calcula el área de una polilínea cerrada
        /// </summary>
        public static double GetPolylineArea(Polyline pline)
        {
            return pline.Area;
        }

        /// <summary>
        /// Calcula el perímetro de una polilínea cerrada
        /// </summary>
        public static double GetPolylinePerimeter(Polyline pline)
        {
            return pline.Length;
        }

        /// <summary>
        /// Obtiene los vértices de una polilínea como lista de Point3d
        /// </summary>
        public static List<Point3d> GetVertices(Polyline pline)
        {
            var vertices = new List<Point3d>();
            if (pline == null) return vertices;

            for (int i = 0; i < pline.NumberOfVertices; i++)
            {
                vertices.Add(pline.GetPoint3dAt(i));
            }
            return vertices;
        }

        /// <summary>
        /// Calcula el centroide de un polígono usando el método del área
        /// </summary>
        public static Point3d GetPolygonCentroid(List<Point3d> pts)
        {
            int n = pts.Count;
            if (n < 3)
            {
                return GetAverageCentroid(pts);
            }

            double a = 0.0;
            double cx = 0.0;
            double cy = 0.0;

            for (int i = 0; i < n; i++)
            {
                Point3d p1 = pts[i];
                Point3d p2 = pts[(i + 1) % n];

                double cross = p1.X * p2.Y - p2.X * p1.Y;
                a += cross;
                cx += (p1.X + p2.X) * cross;
                cy += (p1.Y + p2.Y) * cross;
            }

            if (Math.Abs(a) < 1e-12)
            {
                return GetAverageCentroid(pts);
            }

            a /= 2.0;
            return new Point3d(cx / (6.0 * a), cy / (6.0 * a), 0.0);
        }

        /// <summary>
        /// Calcula el centroide promedio (simple)
        /// </summary>
        private static Point3d GetAverageCentroid(List<Point3d> pts)
        {
            if (pts.Count == 0) return new Point3d(0, 0, 0);

            double sx = 0, sy = 0;
            foreach (var p in pts)
            {
                sx += p.X;
                sy += p.Y;
            }

            int n = pts.Count;
            return new Point3d(sx / n, sy / n, 0.0);
        }

        /// <summary>
        /// Calcula la distancia entre dos puntos
        /// </summary>
        public static double GetDistance(Point3d p1, Point3d p2)
        {
            return p1.DistanceTo(p2);
        }

        /// <summary>
        /// Calcula el azimut en radianes entre dos puntos
        /// </summary>
        public static double GetAzimuthRad(Point3d p1, Point3d p2)
        {
            double dx = p2.X - p1.X;
            double dy = p2.Y - p1.Y;
            double ang = Math.Atan2(dy, dx);
            if (ang < 0) ang += 2 * Math.PI;
            return ang;
        }

        /// <summary>
        /// Convierte radianes a grados
        /// </summary>
        public static double RadToDeg(double rad)
        {
            return rad * 180.0 / Math.PI;
        }

        /// <summary>
        /// Formatea un ángulo en grados a formato DMS (Grados, Minutos, Segundos)
        /// </summary>
        public static string FormatDMS(double angleDeg)
        {
            int dd = (int)Math.Floor(angleDeg);
            double m = (angleDeg - dd) * 60.0;
            int mm = (int)Math.Floor(m);
            double s = (m - mm) * 60.0;
            int ss = (int)Math.Round(s);

            if (ss == 60)
            {
                ss = 0;
                mm++;
            }
            if (mm == 60)
            {
                mm = 0;
                dd++;
            }

            return $"{dd}°{mm}'{ss}\"";
        }

        /// <summary>
        /// Convierte azimut en grados a rumbo (ej: N 45° E)
        /// </summary>
        public static string AzimuthToRumbo(double angleDeg)
        {
            double a = angleDeg;
            double beta;

            if (a >= 0 && a < 90)
            {
                beta = a;
                return $"N {FormatDMS(beta)} E";
            }
            else if (a >= 90 && a < 180)
            {
                beta = 180 - a;
                return $"S {FormatDMS(beta)} E";
            }
            else if (a >= 180 && a < 270)
            {
                beta = a - 180;
                return $"S {FormatDMS(beta)} W";
            }
            else
            {
                beta = 360 - a;
                return $"N {FormatDMS(beta)} W";
            }
        }

        /// <summary>
        /// Calcula el ángulo interno en un vértice del polígono
        /// </summary>
        public static double GetInternalAngleDeg(Point3d pPrev, Point3d p, Point3d pNext)
        {
            Vector3d v1 = (pPrev - p).GetNormal();
            Vector3d v2 = (pNext - p).GetNormal();

            double dot = Vector3d.DotProduct(v1, v2);
            dot = Math.Max(-1.0, Math.Min(1.0, dot)); // Clamp

            return Math.Acos(dot) * 180.0 / Math.PI;
        }

        /// <summary>
        /// Genera etiqueta de vértice
        /// </summary>
        public static string GetVertexLabel(int n)
        {
            return $"{ERARQConfig.VertexPrefix}{n}";
        }

        /// <summary>
        /// Genera etiqueta de lado
        /// </summary>
        public static string GetSideLabel(int i, int n)
        {
            string a = GetVertexLabel(i);
            string b = GetVertexLabel(i == n ? 1 : i + 1);
            return $"{a}-{b}";
        }

        /// <summary>
        /// Convierte área a hectáreas
        /// </summary>
        public static double AreaToHectares(double areaM2)
        {
            return areaM2 / 10000.0;
        }

        /// <summary>
        /// Asegura que una capa existe en el dibujo
        /// </summary>
        public static ObjectId EnsureLayer(string layerName)
        {
            var doc = GetDocument();
            var db = GetDatabase();
            ObjectId layerId = ObjectId.Null;

            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                LayerTable lt = tr.GetObject(db.LayerTableId, OpenMode.ForRead) as LayerTable;
                
                if (!lt.Has(layerName))
                {
                    LayerTableRecord ltr = new LayerTableRecord();
                    ltr.Name = layerName;
                    
                    lt.UpgradeOpen();
                    layerId = lt.Add(ltr);
                    tr.AddNewlyCreatedDBObject(ltr, true);
                }
                else
                {
                    layerId = lt[layerName];
                }

                tr.Commit();
            }

            return layerId;
        }

        /// <summary>
        /// Dibuja una línea
        /// </summary>
        public static ObjectId DrawLine(Point3d p1, Point3d p2, string layerName)
        {
            var db = GetDatabase();
            ObjectId lineId = ObjectId.Null;

            EnsureLayer(layerName);

            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                BlockTable bt = tr.GetObject(db.BlockTableId, OpenMode.ForRead) as BlockTable;
                BlockTableRecord btr = tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite) as BlockTableRecord;

                Line line = new Line(p1, p2);
                line.Layer = layerName;

                lineId = btr.AppendEntity(line);
                tr.AddNewlyCreatedDBObject(line, true);

                tr.Commit();
            }

            return lineId;
        }

        /// <summary>
        /// Dibuja un texto MText
        /// </summary>
        public static ObjectId DrawMText(Point3d pt, double width, string text, string layerName, 
            AttachmentAlignment alignment = AttachmentAlignment.MiddleCenter, double height = 2.5)
        {
            var db = GetDatabase();
            ObjectId textId = ObjectId.Null;

            EnsureLayer(layerName);

            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                BlockTable bt = tr.GetObject(db.BlockTableId, OpenMode.ForRead) as BlockTable;
                BlockTableRecord btr = tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite) as BlockTableRecord;

                MText mtext = new MText();
                mtext.Location = pt;
                mtext.Width = width;
                mtext.Contents = text;
                mtext.Layer = layerName;
                mtext.TextHeight = height;
                mtext.Attachment = alignment;

                textId = btr.AppendEntity(mtext);
                tr.AddNewlyCreatedDBObject(mtext, true);

                tr.Commit();
            }

            return textId;
        }

        /// <summary>
        /// Selecciona una polilínea cerrada del usuario
        /// </summary>
        public static Polyline SelectClosedPolyline(string prompt = "\nSeleccione una polilinea cerrada: ")
        {
            var ed = GetEditor();
            if (ed == null) return null;

            var options = new PromptEntityOptions(prompt);
            options.SetRejectMessage("\nSolo se aceptan LWPOLYLINEs.");
            options.AddAllowedClass(typeof(Polyline), false);

            var result = ed.GetEntity(options);
            if (result.Status != PromptStatus.OK) return null;

            var db = GetDatabase();
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                Polyline pline = tr.GetObject(result.ObjectId, OpenMode.ForRead) as Polyline;
                if (pline != null && !pline.Closed)
                {
                    ed.WriteMessage("\nLa polilinea debe estar cerrada.");
                    return null;
                }
                tr.Commit();
                return pline;
            }
        }

        /// <summary>
        /// Ordena objetos por grilla (de arriba-abajo, izquierda-derecha)
        /// </summary>
        public static List<T> SortObjectsByGrid<T>(List<Tuple<double, double, T>> objects)
        {
            // Ordena primero por Y descendente, luego por X ascendente
            return objects
                .OrderByDescending(o => o.Item1) // Y (cadr)
                .ThenBy(o => o.Item2)             // X (car)
                .Select(o => o.Item3)
                .ToList();
        }
    }

    /// <summary>
    /// Comandos principales de ERARQ-Urb
    /// </summary>
    public class ERARQCommands
    {
        [CommandMethod("ERARQ")]
        public void ERARQCommand()
        {
            ERARQConfig.Initialize();
            var ed = ERARQUtils.GetEditor();
            if (ed != null)
            {
                ed.WriteMessage("\nERArq-Urb cargado correctamente. Use ERARQ_DATOS, ERARQ_COORDS, etc.");
            }
        }

        [CommandMethod("ERARQ_INIT")]
        public void ERARQInitCommand()
        {
            ERARQConfig.Initialize();
            var ed = ERARQUtils.GetEditor();
            if (ed != null)
            {
                ed.WriteMessage($"\nERArq-Urb inicializado. Capa: {ERARQConfig.Layer}, Altura texto: {ERARQConfig.TextHeight}");
            }
        }
    }
}
