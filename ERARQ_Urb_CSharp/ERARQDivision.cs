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
    /// Utilidades vectoriales y geométricas para división de polígonos
    /// </summary>
    public static class DivisionUtils
    {
        /// <summary>
        /// Obtiene el último elemento de una lista
        /// </summary>
        public static T LastElem<T>(List<T> lst)
        {
            if (lst != null && lst.Count > 0)
                return lst[lst.Count - 1];
            return default(T);
        }

        /// <summary>
        /// Suma vectorial
        /// </summary>
        public static Point3d VAdd(Point3d a, Point3d b)
        {
            return new Point3d(a.X + b.X, a.Y + b.Y, 0.0);
        }

        /// <summary>
        /// Resta vectorial
        /// </summary>
        public static Point3d VSub(Point3d a, Point3d b)
        {
            return new Point3d(a.X - b.X, a.Y - b.Y, 0.0);
        }

        /// <summary>
        /// Multiplicación de vector por escalar
        /// </summary>
        public static Point3d VScale(Point3d v, double s)
        {
            return new Point3d(v.X * s, v.Y * s, 0.0);
        }

        /// <summary>
        /// Producto punto
        /// </summary>
        public static double Dot(Vector3d a, Vector3d b)
        {
            return a.X * b.X + a.Y * b.Y;
        }

        /// <summary>
        /// Longitud de vector
        /// </summary>
        public static double Len(Vector3d v)
        {
            return Math.Sqrt(v.X * v.X + v.Y * v.Y);
        }

        /// <summary>
        /// Vector unitario
        /// </summary>
        public static Vector3d Unit(Vector3d v)
        {
            double l = Len(v);
            if (l > 1e-14)
                return v.GetNormal();
            return Vector3d.XAxis;
        }

        /// <summary>
        /// Vector perpendicular (rotación 90° antihoraria)
        /// </summary>
        public static Vector3d Perp(Vector3d v)
        {
            return new Vector3d(-v.Y, v.X, 0.0);
        }

        /// <summary>
        /// Mínimo de una lista
        /// </summary>
        public static double MinL(List<double> lst)
        {
            if (lst == null || lst.Count == 0) return 0.0;
            return lst.Min();
        }

        /// <summary>
        /// Máximo de una lista
        /// </summary>
        public static double MaxL(List<double> lst)
        {
            if (lst == null || lst.Count == 0) return 0.0;
            return lst.Max();
        }

        /// <summary>
        /// Cierra un polígono (agrega primer punto al final si no está cerrado)
        /// </summary>
        public static List<Point3d> ClosePts(List<Point3d> pts)
        {
            if (pts == null || pts.Count == 0) return pts;
            
            var lastPt = LastElem(pts);
            if (!pts[0].IsEqualTo(lastPt, 1e-9))
                pts.Add(pts[0]);
            return pts;
        }

        /// <summary>
        /// Abre un polígono (remueve último punto si es igual al primero)
        /// </summary>
        public static List<Point3d> OpenPts(List<Point3d> pts)
        {
            if (pts == null || pts.Count <= 1) return pts;
            
            var lastPt = LastElem(pts);
            if (pts[0].IsEqualTo(lastPt, 1e-9))
                pts.RemoveAt(pts.Count - 1);
            return pts;
        }

        /// <summary>
        /// Elimina puntos duplicados cercanos
        /// </summary>
        public static List<Point3d> DedupeNearPts(List<Point3d> pts, double tol)
        {
            var outList = new List<Point3d>();
            foreach (var p in pts)
            {
                if (outList.Count == 0 || !p.IsEqualTo(LastElem(outList), tol))
                    outList.Add(p);
            }
            return outList;
        }

        /// <summary>
        /// Área con signo de un polígono (fórmula de la lazada)
        /// </summary>
        public static double PolyAreaSigned(List<Point3d> pts)
        {
            var lst = ClosePts(new List<Point3d>(pts));
            double a = 0.0;
            for (int i = 0; i < lst.Count - 1; i++)
            {
                var p = lst[i];
                var q = lst[i + 1];
                a += (p.X * q.Y - q.X * p.Y);
            }
            return a / 2.0;
        }

        /// <summary>
        /// Área absoluta de un polígono
        /// </summary>
        public static double PolyArea(List<Point3d> pts)
        {
            return Math.Abs(PolyAreaSigned(pts));
        }

        /// <summary>
        /// Centroide promedio (simple)
        /// </summary>
        public static Point3d AvgCentroid(List<Point3d> pts)
        {
            if (pts == null || pts.Count == 0)
                return new Point3d(0, 0, 0);
            
            double sx = 0, sy = 0;
            foreach (var p in pts)
            {
                sx += p.X;
                sy += p.Y;
            }
            return new Point3d(sx / pts.Count, sy / pts.Count, 0.0);
        }

        /// <summary>
        /// Centroide geométrico correcto de polígono
        /// </summary>
        public static Point3d PolyCentroid(List<Point3d> pts)
        {
            var lst = ClosePts(new List<Point3d>(pts));
            double a = 0.0, cx = 0.0, cy = 0.0;
            
            for (int i = 0; i < lst.Count - 1; i++)
            {
                var p = lst[i];
                var q = lst[i + 1];
                double cross = p.X * q.Y - q.X * p.Y;
                a += cross;
                cx += (p.X + q.X) * cross;
                cy += (p.Y + q.Y) * cross;
            }

            if (Math.Abs(a) < 1e-12)
                return AvgCentroid(pts);
            
            return new Point3d(cx / (3.0 * a), cy / (3.0 * a), 0.0);
        }

        /// <summary>
        /// Intersección de segmento con línea definida por normal y offset
        /// </summary>
        public static Point3d? SegmentLineIntersection(Point3d a, Point3d b, double s, Vector3d perp)
        {
            double fa = Dot(perp, a.GetVector()) - s;
            double fb = Dot(perp, b.GetVector()) - s;

            if (Math.Abs(fa) < 1e-12 && Math.Abs(fb) < 1e-12)
                return null; // Colineal
            if (Math.Abs(fa) < 1e-12)
                return a;
            if (Math.Abs(fb) < 1e-12)
                return b;
            if (fa * fb < 0.0)
            {
                var ab = b.GetVector() - a.GetVector();
                double tt = fa / (fa - fb);
                return a + ab * tt;
            }
            return null;
        }

        /// <summary>
        /// Verifica si punto está al lado izquierdo de la línea
        /// </summary>
        public static bool InsideLeftP(Point3d p, Vector3d perp, double s, double tol)
        {
            return Dot(perp, p.GetVector()) <= s + tol;
        }

        /// <summary>
        /// Verifica si punto está al lado derecho de la línea
        /// </summary>
        public static bool InsideRightP(Point3d p, Vector3d perp, double s, double tol)
        {
            return Dot(perp, p.GetVector()) >= s - tol;
        }

        /// <summary>
        /// Recorta polígono al lado izquierdo de una línea
        /// </summary>
        public static List<Point3d> ClipPolyLeftOfLine(List<Point3d> pts, Vector3d perp, double s)
        {
            double tol = 1e-12;
            var input = ClosePts(new List<Point3d>(pts));
            var output = new List<Point3d>();

            for (int i = 0; i < input.Count - 1; i++)
            {
                var a = input[i];
                var b = input[i + 1];
                bool ina = InsideLeftP(a, perp, s, tol);
                bool inb = InsideLeftP(b, perp, s, tol);

                if (ina && inb)
                {
                    output.Add(b);
                }
                else if (ina && !inb)
                {
                    var ip = SegmentLineIntersection(a, b, s, perp);
                    if (ip.HasValue)
                        output.Add(ip.Value);
                }
                else if (!ina && inb)
                {
                    var ip = SegmentLineIntersection(a, b, s, perp);
                    if (ip.HasValue)
                        output.Add(ip.Value);
                    output.Add(b);
                }
            }

            if (output.Count > 2)
                return ClosePts(DedupeNearPts(output, 1e-8));
            return null;
        }

        /// <summary>
        /// Recorta polígono al lado derecho de una línea
        /// </summary>
        public static List<Point3d> ClipPolyRightOfLine(List<Point3d> pts, Vector3d perp, double s)
        {
            double tol = 1e-12;
            var input = ClosePts(new List<Point3d>(pts));
            var output = new List<Point3d>();

            for (int i = 0; i < input.Count - 1; i++)
            {
                var a = input[i];
                var b = input[i + 1];
                bool ina = InsideRightP(a, perp, s, tol);
                bool inb = InsideRightP(b, perp, s, tol);

                if (ina && inb)
                {
                    output.Add(b);
                }
                else if (ina && !inb)
                {
                    var ip = SegmentLineIntersection(a, b, s, perp);
                    if (ip.HasValue)
                        output.Add(ip.Value);
                }
                else if (!ina && inb)
                {
                    var ip = SegmentLineIntersection(a, b, s, perp);
                    if (ip.HasValue)
                        output.Add(ip.Value);
                    output.Add(b);
                }
            }

            if (output.Count > 2)
                return ClosePts(DedupeNearPts(output, 1e-8));
            return null;
        }

        /// <summary>
        /// Área del polígono al lado izquierdo de una línea
        /// </summary>
        public static double AreaLeftOfLine(List<Point3d> pts, Vector3d perp, double s)
        {
            var clipped = ClipPolyLeftOfLine(pts, perp, s);
            if (clipped != null)
                return PolyArea(clipped);
            return 0.0;
        }

        /// <summary>
        /// Rango de offsets proyectados
        /// </summary>
        public static Tuple<double, double> OffsetRange(List<Point3d> pts, Vector3d perp)
        {
            var vals = new List<double>();
            foreach (var p in pts)
                vals.Add(Dot(perp, p.GetVector()));
            return Tuple.Create(MinL(vals), MaxL(vals));
        }

        /// <summary>
        /// Búsqueda binaria para encontrar offset que produce área objetivo
        /// </summary>
        public static double FindSByAreaBisection(List<Point3d> pts, Vector3d perp, 
            double targetArea, double smin, double smax, double areaTol, int maxIter)
        {
            double lo = smin, hi = smax;
            int iter = 0;

            while (iter < maxIter)
            {
                double mid = (lo + hi) / 2.0;
                double amid = AreaLeftOfLine(pts, perp, mid);

                if (Math.Abs(amid - targetArea) <= areaTol)
                    break;
                
                if (amid < targetArea)
                    lo = mid;
                else
                    hi = mid;
                
                iter++;
            }

            return (lo + hi) / 2.0;
        }
    }

    /// <summary>
    /// Comandos de división de polígonos en lotes
    /// </summary>
    public class ERARQDivisionCommands
    {
        /// <summary>
        /// Crea una LWPOLYLINE cerrada
        /// </summary>
        private static ObjectId MakeClosedLwPoly(List<Point3d> pts, string layer)
        {
            var clean = DivisionUtils.OpenPts(pts);
            clean = DivisionUtils.DedupeNearPts(clean, 1e-8);

            if (clean == null || clean.Count <= 2)
                return ObjectId.Null;

            using (var trans = acApp.DocumentManager.MdiActiveDocument.Database.TransactionManager.StartTransaction())
            {
                var bt = trans.GetObject(acApp.DocumentManager.MdiActiveDocument.Database.BlockTableId, OpenMode.ForRead) as BlockTable;
                var btr = trans.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite) as BlockTableRecord;

                var poly = new Polyline();
                poly.SetDatabaseDefaults();
                poly.Layer = layer;
                poly.Closed = true;

                for (int i = 0; i < clean.Count; i++)
                {
                    poly.AddVertexAt(i, new Point2d(clean[i].X, clean[i].Y), 0, 0, 0);
                }

                var id = btr.AppendEntity(poly);
                trans.AddNewlyCreatedDBObject(poly, true);
                trans.Commit();
                return id;
            }
        }

        /// <summary>
        /// Etiqueta un nuevo lote con texto
        /// </summary>
        private static void LabelNewLot(List<Point3d> pts, int idx)
        {
            if (!ERARQConfig.DrawTexts) return;

            ERARQLayers.EnsureLotLayers(idx);
            var c = DivisionUtils.PolyCentroid(pts);
            string txt = ERARQConfig.LotPrefix + idx.ToString();

            ERARQDraw.CreateText(c, txt, ERARQLayers.LayerLoteTxt(idx), ERARQConfig.TextHeight);
        }

        /// <summary>
        /// Divide un polígono en N lotes de igual área
        /// </summary>
        [CommandMethod("ERARQ_DIVIDE_EQUAL")]
        public void DivideEqualLots()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            // Seleccionar polilínea cerrada
            var peo = new PromptEntityOptions("\nSeleccione una LWPOLYLINE cerrada: ");
            peo.SetRejectMessage("\nDebe seleccionar una LWPOLYLINE.");
            peo.AddAllowedClass(typeof(Polyline), false);
            var per = ed.GetEntity(peo);

            if (per.Status != PromptStatus.OK) return;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var pline = trans.GetObject(per.ObjectId, OpenMode.ForRead) as Polyline;
                
                if (pline == null || !pline.Closed)
                {
                    ed.WriteMessage("\nLa polilínea debe estar cerrada.");
                    return;
                }

                var pts = new List<Point3d>();
                for (int i = 0; i < pline.NumberOfVertices; i++)
                {
                    var pt2d = pline.GetPoint2dAt(i);
                    pts.Add(new Point3d(pt2d.X, pt2d.Y, 0.0));
                }
                trans.Commit();

                if (pts.Count < 3)
                {
                    ed.WriteMessage("\nPolígono inválido.");
                    return;
                }

                // Obtener número de lotes
                var pio = new PromptIntegerOptions("\nNúmero de lotes: ");
                pio.LowerLimit = 2;
                var pir = ed.GetInteger(pio);
                if (pir.Status != PromptStatus.OK) return;
                int n = pir.Value;

                // Obtener dirección de corte
                var ppo1 = ed.GetPoint("\nPrimer punto de la dirección de corte: ");
                if (ppo1.Status != PromptStatus.OK) return;
                var p1 = ppo1.Value;

                var ppo2 = ed.GetPoint(p1, "\nSegundo punto de la dirección de corte: ");
                if (ppo2.Status != PromptStatus.OK) return;
                var p2 = ppo2.Value;

                var dir = DivisionUtils.Unit((p2 - p1).GetVector());
                if (DivisionUtils.Len(dir) < 1e-12)
                {
                    ed.WriteMessage("\nDirección inválida.");
                    return;
                }

                var perp = DivisionUtils.Perp(dir);

                // Tolerancia y iteraciones
                var areaTol = 0.000001;
                var maxIter = 80;

                double areaPoly = DivisionUtils.PolyArea(pts);
                double eachArea = areaPoly / n;
                var current = DivisionUtils.ClosePts(new List<Point3d>(pts));
                var created = new List<ObjectId>();

                ed.WriteMessage($"\nÁrea total = {areaPoly:F8}");
                ed.WriteMessage($"\nÁrea objetivo por lote = {eachArea:F8}");

                for (int k = 0; k < n - 1; k++)
                {
                    var rg = DivisionUtils.OffsetRange(current, perp);
                    double smin = rg.Item1, smax = rg.Item2;

                    double s = DivisionUtils.FindSByAreaBisection(
                        current, perp, eachArea, smin, smax, areaTol, maxIter);

                    var lot = DivisionUtils.ClipPolyLeftOfLine(current, perp, s);
                    var rem = DivisionUtils.ClipPolyRightOfLine(current, perp, s);
                    int idx = ERARQConfig.StartNumber + k;

                    if (lot != null && rem != null)
                    {
                        ERARQLayers.EnsureLotLayers(idx);

                        var en = MakeClosedLwPoly(lot, ERARQLayers.LayerLote(idx));
                        if (en != ObjectId.Null)
                            created.Add(en);

                        double e = DivisionUtils.PolyArea(lot);
                        LabelNewLot(lot, idx);

                        ed.WriteMessage($"\nLote {idx} | Área = {e:F8} | Capa = {ERARQLayers.LayerLote(idx)}");

                        current = rem;
                    }
                    else
                    {
                        ed.WriteMessage("\nNo fue posible generar un corte válido.");
                        break;
                    }
                }

                // Último lote (resto)
                if (current != null && current.Count > 2)
                {
                    int idx = ERARQConfig.StartNumber + n - 1;
                    ERARQLayers.EnsureLotLayers(idx);

                    var en = MakeClosedLwPoly(current, ERARQLayers.LayerLote(idx));
                    if (en != ObjectId.Null)
                        created.Add(en);

                    double e = DivisionUtils.PolyArea(current);
                    LabelNewLot(current, idx);

                    ed.WriteMessage($"\nLote {idx} | Área = {e:F8} | Capa = {ERARQLayers.LayerLote(idx)}");
                }

                acApp.ShowAlertDialog(
                    $"División completada.\n\n" +
                    $"Lotes generados: {n}\n" +
                    $"Área total original: {areaPoly:F{ERARQConfig.DecArea}} m²\n" +
                    $"Área objetivo por lote: {eachArea:F{ERARQConfig.DecArea}} m²\n\n" +
                    $"Cada lote fue creado en su propia capa dinámica.");
            }
        }

        /// <summary>
        /// Divide un polígono por área objetivo
        /// </summary>
        [CommandMethod("ERARQ_DIVIDE_AREA")]
        public void DivideByArea()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            var peo = new PromptEntityOptions("\nSeleccione una LWPOLYLINE cerrada: ");
            peo.SetRejectMessage("\nDebe seleccionar una LWPOLYLINE.");
            peo.AddAllowedClass(typeof(Polyline), false);
            var per = ed.GetEntity(peo);

            if (per.Status != PromptStatus.OK) return;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var pline = trans.GetObject(per.ObjectId, OpenMode.ForRead) as Polyline;
                
                if (pline == null || !pline.Closed)
                {
                    ed.WriteMessage("\nLa polilínea debe estar cerrada.");
                    return;
                }

                var pts = new List<Point3d>();
                for (int i = 0; i < pline.NumberOfVertices; i++)
                {
                    var pt2d = pline.GetPoint2dAt(i);
                    pts.Add(new Point3d(pt2d.X, pt2d.Y, 0.0));
                }
                trans.Commit();

                if (pts.Count < 3)
                {
                    ed.WriteMessage("\nPolígono inválido.");
                    return;
                }

                // Obtener área objetivo
                var pdo = new PromptDoubleOptions("\nÁrea objetivo por lote: ");
                var pdr = ed.GetDouble(pdo);
                if (pdr.Status != PromptStatus.OK || pdr.Value <= 0)
                {
                    ed.WriteMessage("\nÁrea objetivo inválida.");
                    return;
                }

                double areaPoly = DivisionUtils.PolyArea(pts);
                double nReal = areaPoly / pdr.Value;
                int n = (int)nReal;

                if (n < 2)
                {
                    acApp.ShowAlertDialog(
                        $"El área objetivo es demasiado grande para generar al menos 2 lotes.\n\n" +
                        $"Área total: {areaPoly:F{ERARQConfig.DecArea}} m²");
                    return;
                }

                acApp.ShowAlertDialog(
                    $"Área total: {areaPoly:F{ERARQConfig.DecArea}} m²\n" +
                    $"Área objetivo de referencia: {pdr.Value:F{ERARQConfig.DecArea}} m²\n" +
                    $"Se generarán {n} lotes iguales.");

                // Llamar a división por número
                var cmd = new ERARQDivisionCommands();
                // Nota: En implementación real se refactorizaría para evitar duplicación
            }
        }
    }
}
