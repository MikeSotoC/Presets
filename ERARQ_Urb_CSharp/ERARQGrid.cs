using System;
using System.Collections.Generic;
using System.Linq;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using acApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace ERARQ_Urb
{
    /// <summary>
    /// Utilidades para grilla de coordenadas
    /// </summary>
    public static class GridUtils
    {
        /// <summary>
        /// Redondea entero más cercano
        /// </summary>
        public static int RoundInt(double n)
        {
            return (int)Math.Round(n, MidpointRounding.AwayFromZero);
        }

        /// <summary>
        /// Piso al múltiplo de step más cercano
        /// </summary>
        public static double FloorStep(double v, double step)
        {
            double q = v / step;
            if (q >= 0.0)
                return step * Math.Floor(q);
            else
                return step * (Math.Floor(q));
        }

        /// <summary>
        /// Techo al múltiplo de step más cercano
        /// </summary>
        public static double CeilStep(double v, double step)
        {
            double q = v / step;
            double f = Math.Floor(q);
            if (Math.Abs(q - f) < 1e-12)
                return step * f;
            if (q > 0.0)
                return step * (f + 1);
            else
                return step * f;
        }

        /// <summary>
        /// Formatea entero con separadores de miles
        /// </summary>
        public static string FormatInt(double n)
        {
            int val = RoundInt(Math.Abs(n));
            string s = val.ToString();
            int len = s.Length;

            if (len <= 3)
                s = s;
            else if (len == 4)
                s = s.Substring(0, 1) + " " + s.Substring(1);
            else if (len == 5)
                s = s.Substring(0, 2) + " " + s.Substring(2);
            else if (len == 6)
                s = s.Substring(0, 3) + " " + s.Substring(3);
            else if (len == 7)
                s = s.Substring(0, 1) + " " + s.Substring(1, 3) + " " + s.Substring(4);
            else if (len == 8)
                s = s.Substring(0, 2) + " " + s.Substring(2, 3) + " " + s.Substring(5);
            else if (len == 9)
                s = s.Substring(0, 3) + " " + s.Substring(3, 3) + " " + s.Substring(6);
            else if (len == 10)
                s = s.Substring(0, 1) + " " + s.Substring(1, 3) + " " + s.Substring(4, 3) + " " + s.Substring(7);

            if (n < 0.0)
                s = "-" + s;
            return s;
        }

        /// <summary>
        /// Verifica si valor es múltiplo de step
        /// </summary>
        public static bool IsMultipleOf(double value, double step)
        {
            if (step <= 0.0) return false;
            double q = value / step;
            return Math.Abs(q - RoundInt(q)) < 1e-8;
        }

        /// <summary>
        /// Ajusta rectángulo a grilla
        /// </summary>
        public static Tuple<Point3d, Point3d> SnapRect(Point3d p1, Point3d p2, double dx, double dy)
        {
            double x1 = FloorStep(Math.Min(p1.X, p2.X), dx);
            double y1 = FloorStep(Math.Min(p1.Y, p2.Y), dy);
            double x2 = CeilStep(Math.Max(p1.X, p2.X), dx);
            double y2 = CeilStep(Math.Max(p1.Y, p2.Y), dy);

            if (Math.Abs(x1 - x2) < 1e-12)
                x2 = x1 + dx;
            if (Math.Abs(y1 - y2) < 1e-12)
                y2 = y1 + dy;

            return Tuple.Create(new Point3d(x1, y1, 0.0), new Point3d(x2, y2, 0.0));
        }

        /// <summary>
        /// Normaliza rectángulo (asegura p1.x <= p2.x, p1.y <= p2.y)
        /// </summary>
        public static Tuple<Point3d, Point3d> NormalizeRect(Point3d p1, Point3d p2)
        {
            double x1 = Math.Min(p1.X, p2.X);
            double y1 = Math.Min(p1.Y, p2.Y);
            double x2 = Math.Max(p1.X, p2.X);
            double y2 = Math.Max(p1.Y, p2.Y);
            return Tuple.Create(new Point3d(x1, y1, 0.0), new Point3d(x2, y2, 0.0));
        }

        /// <summary>
        /// Primer valor dentro de la grilla
        /// </summary>
        public static double FirstInsideStep(double v, double step)
        {
            return CeilStep(v, step);
        }

        /// <summary>
        /// Último valor dentro de la grilla
        /// </summary>
        public static double LastInsideStep(double v, double step)
        {
            return FloorStep(v, step);
        }

        /// <summary>
        /// Obtiene capa según nivel de grilla
        /// </summary>
        public static string GetGridLayer(double coord, double step)
        {
            double step5 = step * 5.0;
            double step10 = step * 10.0;

            if (IsMultipleOf(coord, step10))
                return ERARQLayers.LayerGridMaster;
            else if (IsMultipleOf(coord, step5))
                return ERARQLayers.LayerGridMajor;
            else
                return ERARQLayers.LayerGridMinor;
        }

        /// <summary>
        /// Crea estilo de texto para grilla
        /// </summary>
        public static void EnsureTextStyle()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var db = doc.Database;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var stDict = (DBDictionary)trans.GetObject(db.TextStyleTableId, OpenMode.ForRead);
                
                if (!stDict.Contains("GRID"))
                {
                    trans.GetObject(db.TextStyleTableId, OpenMode.ForWrite);
                    var textStyle = new TextStyleTableRecord("GRID");
                    textStyle.Font = new FontDescriptor("ROMAND", false, false, 0, 0);
                    
                    var stDictWrite = (DBDictionary)trans.GetObject(db.TextStyleTableId, OpenMode.ForWrite);
                    stDictWrite.SetAt("GRID", textStyle);
                    trans.AddNewlyCreatedDBObject(textStyle, true);
                }
                
                trans.Commit();
            }
            
            // Establecer como actual
            Application.SetSystemVariable("TEXTSTYLE", "GRID");
        }

        /// <summary>
        /// Asegura capas de grilla
        /// </summary>
        public static void EnsureLayers()
        {
            ERARQLayers.EnsureBaseLayers();
            ERARQLayers.LayerSetup(ERARQLayers.LayerGridMinor, 8, "Continuous", 13);
            ERARQLayers.LayerSetup(ERARQLayers.LayerGridMajor, 8, "Continuous", 18);
            ERARQLayers.LayerSetup(ERARQLayers.LayerGridMaster, 7, "Continuous", 25);
            ERARQLayers.LayerSetup(ERARQLayers.LayerGridBorder, 7, "Continuous", 35);
            ERARQLayers.LayerSetup(ERARQLayers.LayerGridTxt, 9, "Continuous", 13);
        }

        /// <summary>
        /// Dibuja línea de grilla
        /// </summary>
        public static ObjectId DrawLine(Point3d p1, Point3d p2, string layer)
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var db = doc.Database;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)trans.GetObject(db.BlockTableId, OpenMode.ForRead);
                var btr = (BlockTableRecord)trans.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

                var line = new Line(p1, p2);
                line.Layer = layer;

                var id = btr.AppendEntity(line);
                trans.AddNewlyCreatedDBObject(line, true);
                trans.Commit();
                return id;
            }
        }

        /// <summary>
        /// Dibuja texto de grilla
        /// </summary>
        public static ObjectId DrawText(Point3d pt, string txt, double hgt, double rot, 
            string just, string layer)
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var db = doc.Database;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var bt = (BlockTable)trans.GetObject(db.BlockTableId, OpenMode.ForRead);
                var btr = (BlockTableRecord)trans.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

                var mtext = new MText();
                mtext.Location = pt;
                mtext.Contents = txt;
                mtext.Height = hgt;
                mtext.Rotation = rot;
                mtext.Layer = layer;
                mtext.StyleId = db.Textstyle;

                // Justificación
                switch (just.ToUpper())
                {
                    case "L": mtext.Attachment = AttachmentPoint.MiddleLeft; break;
                    case "C": mtext.Attachment = AttachmentPoint.MiddleCenter; break;
                    case "R": mtext.Attachment = AttachmentPoint.MiddleRight; break;
                    case "TL": mtext.Attachment = AttachmentPoint.TopLeft; break;
                    case "TC": mtext.Attachment = AttachmentPoint.TopCenter; break;
                    case "TR": mtext.Attachment = AttachmentPoint.TopRight; break;
                    case "ML": mtext.Attachment = AttachmentPoint.MiddleLeft; break;
                    case "MR": mtext.Attachment = AttachmentPoint.MiddleRight; break;
                    default: mtext.Attachment = AttachmentPoint.BottomLeft; break;
                }

                var id = btr.AppendEntity(mtext);
                trans.AddNewlyCreatedDBObject(mtext, true);
                trans.Commit();
                return id;
            }
        }

        /// <summary>
        /// Obtiene bounding box de selection set
        /// </summary>
        public static Tuple<Point3d, Point3d>? GetSSBbox(PromptSelectionResult ssr)
        {
            if (ssr == null || ssr.Status != PromptStatus.OK)
                return null;

            var ss = ssr.Value;
            if (ss.Count == 0)
                return null;

            double minx = 0, miny = 0, maxx = 0, maxy = 0;
            bool first = true;

            var doc = acApp.DocumentManager.MdiActiveDocument;
            var db = doc.Database;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                foreach (SelectedObject selObj in ss)
                {
                    var ent = trans.GetObject(selObj.ObjectId, OpenMode.ForRead) as Entity;
                    if (ent == null) continue;

                    extMin = ent.GeometricExtents.MinPoint;
                    extMax = ent.GeometricExtents.MaxPoint;

                    if (first)
                    {
                        minx = extMin.X;
                        miny = extMin.Y;
                        maxx = extMax.X;
                        maxy = extMax.Y;
                        first = false;
                    }
                    else
                    {
                        minx = Math.Min(minx, extMin.X);
                        miny = Math.Min(miny, extMin.Y);
                        maxx = Math.Max(maxx, extMax.X);
                        maxy = Math.Max(maxy, extMax.Y);
                    }
                }
                trans.Commit();
            }

            return Tuple.Create(new Point3d(minx, miny, 0.0), new Point3d(maxx, maxy, 0.0));
        }

        /// <summary>
        /// Crea rectángulo desde bounding box ajustado a grilla
        /// </summary>
        public static Tuple<Point3d, Point3d> RectFromBbox(Tuple<Point3d, Point3d> bbox, double dx, double dy)
        {
            var pmin = bbox.Item1;
            var pmax = bbox.Item2;

            double x1 = FloorStep(pmin.X, dx);
            double y1 = FloorStep(pmin.Y, dy);
            double x2 = CeilStep(pmax.X, dx);
            double y2 = CeilStep(pmax.Y, dy);

            if (Math.Abs(x1 - x2) < 1e-12)
                x2 = x1 + dx;
            if (Math.Abs(y1 - y2) < 1e-12)
                y2 = y1 + dy;

            return Tuple.Create(new Point3d(x1, y1, 0.0), new Point3d(x2, y2, 0.0));
        }
    }

    /// <summary>
    /// Comandos de grilla
    /// </summary>
    public class ERARQGridCommands
    {
        /// <summary>
        /// Dibuja grilla manual entre dos puntos
        /// </summary>
        [CommandMethod("ERARQ_GRID")]
        public void DrawGridManual()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;

            // Obtener punto inicial
            var ppr1 = ed.GetPoint("\nPrimer punto de la grilla: ");
            if (ppr1.Status != PromptStatus.OK) return;
            var p1 = ppr1.Value;

            // Obtener punto opuesto
            var ppr2 = ed.GetPoint(p1, "\nPunto opuesto de la grilla: ");
            if (ppr2.Status != PromptStatus.OK) return;
            var p2 = ppr2.Value;

            // Obtener espaciado
            var pdoX = new PromptDoubleOptions("\nEspaciado en X <100>: ");
            pdoX.AllowNone = true;
            var pdX = ed.GetDouble(pdoX);
            double dx = pdX.Status == PromptStatus.OK ? pdX.Value : 100.0;

            var pdoY = new PromptDoubleOptions("\nEspaciado en Y <100>: ");
            pdoY.AllowNone = true;
            var pdY = ed.GetDouble(pdoY);
            double dy = pdY.Status == PromptStatus.OK ? pdY.Value : 100.0;

            // Asegurar configuración
            GridUtils.EnsureTextStyle();
            GridUtils.EnsureLayers();

            // Normalizar rectángulo
            var rect = GridUtils.NormalizeRect(p1, p2);
            var pMin = rect.Item1;
            var pMax = rect.Item2;

            // Dibujar líneas verticales
            for (double x = GridUtils.FirstInsideStep(pMin.X, dx); 
                 x <= pMax.X + 1e-12; x += dx)
            {
                string layer = GridUtils.GetGridLayer(x, dx);
                GridUtils.DrawLine(
                    new Point3d(x, pMin.Y, 0.0),
                    new Point3d(x, pMax.Y, 0.0),
                    layer);
            }

            // Dibujar líneas horizontales
            for (double y = GridUtils.FirstInsideStep(pMin.Y, dy); 
                 y <= pMax.Y + 1e-12; y += dy)
            {
                string layer = GridUtils.GetGridLayer(y, dy);
                GridUtils.DrawLine(
                    new Point3d(pMin.X, y, 0.0),
                    new Point3d(pMax.X, y, 0.0),
                    layer);
            }

            // Dibujar etiquetas
            double textHeight = ERARQConfig.SmallTextHeight;
            double offset = dx * 0.02;

            // Etiquetas X (eje horizontal)
            for (double x = GridUtils.FirstInsideStep(pMin.X, dx); 
                 x <= pMax.X + 1e-12; x += dx)
            {
                string label = GridUtils.FormatInt(x);
                GridUtils.DrawText(
                    new Point3d(x, pMin.Y - offset, 0.0),
                    label,
                    textHeight,
                    0.0,
                    "C",
                    ERARQLayers.LayerGridTxt);
            }

            // Etiquetas Y (eje vertical)
            for (double y = GridUtils.FirstInsideStep(pMin.Y, dy); 
                 y <= pMax.Y + 1e-12; y += dy)
            {
                string label = GridUtils.FormatInt(y);
                GridUtils.DrawText(
                    new Point3d(pMin.X - offset, y, 0.0),
                    label,
                    textHeight,
                    0.0,
                    "R",
                    ERARQLayers.LayerGridTxt);
            }

            ed.WriteMessage("\nGrilla creada exitosamente.");
        }

        /// <summary>
        /// Dibuja grilla automática basada en selección
        /// </summary>
        [CommandMethod("ERARQ_GRID_AUTO")]
        public void DrawGridAuto()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;

            // Seleccionar objetos
            var peo = new PromptSelectionOptions();
            peo.MessageForAdding = "\nSeleccione objetos para delimitar grilla: ";
            var ssr = ed.GetSelection(peo);

            if (ssr.Status != PromptStatus.OK) return;

            // Obtener bounding box
            var bbox = GridUtils.GetSSBbox(ssr);
            if (!bbox.HasValue)
            {
                ed.WriteMessage("\nNo se pudo obtener el bounding box.");
                return;
            }

            // Obtener espaciado
            var pdoX = new PromptDoubleOptions("\nEspaciado en X <100>: ");
            pdoX.AllowNone = true;
            var pdX = ed.GetDouble(pdoX);
            double dx = pdX.Status == PromptStatus.OK ? pdX.Value : 100.0;

            var pdoY = new PromptDoubleOptions("\nEspaciado en Y <100>: ");
            pdoY.AllowNone = true;
            var pdY = ed.GetDouble(pdoY);
            double dy = pdY.Status == PromptStatus.OK ? pdY.Value : 100.0;

            // Asegurar configuración
            GridUtils.EnsureTextStyle();
            GridUtils.EnsureLayers();

            // Crear rectángulo ajustado a grilla
            var rect = GridUtils.RectFromBbox(bbox.Value, dx, dy);
            var pMin = rect.Item1;
            var pMax = rect.Item2;

            // Dibujar líneas verticales
            for (double x = pMin.X; x <= pMax.X + 1e-12; x += dx)
            {
                string layer = GridUtils.GetGridLayer(x, dx);
                GridUtils.DrawLine(
                    new Point3d(x, pMin.Y, 0.0),
                    new Point3d(x, pMax.Y, 0.0),
                    layer);
            }

            // Dibujar líneas horizontales
            for (double y = pMin.Y; y <= pMax.Y + 1e-12; y += dy)
            {
                string layer = GridUtils.GetGridLayer(y, dy);
                GridUtils.DrawLine(
                    new Point3d(pMin.X, y, 0.0),
                    new Point3d(pMax.X, y, 0.0),
                    layer);
            }

            // Dibujar etiquetas
            double textHeight = ERARQConfig.SmallTextHeight;
            double offset = dx * 0.02;

            // Etiquetas X
            for (double x = pMin.X; x <= pMax.X + 1e-12; x += dx)
            {
                string label = GridUtils.FormatInt(x);
                GridUtils.DrawText(
                    new Point3d(x, pMin.Y - offset, 0.0),
                    label,
                    textHeight,
                    0.0,
                    "C",
                    ERARQLayers.LayerGridTxt);
            }

            // Etiquetas Y
            for (double y = pMin.Y; y <= pMax.Y + 1e-12; y += dy)
            {
                string label = GridUtils.FormatInt(y);
                GridUtils.DrawText(
                    new Point3d(pMin.X - offset, y, 0.0),
                    label,
                    textHeight,
                    0.0,
                    "R",
                    ERARQLayers.LayerGridTxt);
            }

            ed.WriteMessage("\nGrilla automática creada exitosamente.");
        }
    }
}
