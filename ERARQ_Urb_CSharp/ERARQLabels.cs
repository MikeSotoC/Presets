using System;
using System.Collections.Generic;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using acApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace ERARQ_Urb
{
    /// <summary>
    /// Comandos de etiquetado y numeración de lotes y vértices
    /// </summary>
    public class ERARQLabelsCommands
    {
        /// <summary>
        /// Genera texto para etiqueta de lote
        /// </summary>
        private static string LotLabelText(int n)
        {
            return ERARQConfig.LotPrefix + n.ToString();
        }

        /// <summary>
        /// Genera texto para etiqueta de vértice
        /// </summary>
        private static string VertexText(int n)
        {
            return ERARQConfig.VertexPrefix + n.ToString();
        }

        /// <summary>
        /// Genera texto para vértice de lote específico
        /// </summary>
        private static string LotVertexText(int lotN, int vertN)
        {
            return $"{ERARQConfig.LotPrefix}{lotN}-{ERARQConfig.VertexPrefix}{vertN}";
        }

        /// <summary>
        /// Obtiene vértices de una polilínea
        /// </summary>
        private static List<Point3d> GetVertices(Polyline pline)
        {
            var pts = new List<Point3d>();
            for (int i = 0; i < pline.NumberOfVertices; i++)
            {
                var pt2d = pline.GetPoint2dAt(i);
                pts.Add(new Point3d(pt2d.X, pt2d.Y, 0.0));
            }
            return pts;
        }

        /// <summary>
        /// Etiqueta vértices de una polilínea
        /// </summary>
        private static void LabelVerticesOnObject(Polyline pline)
        {
            if (pline == null) return;

            ERARQLayers.EnsureBaseLayers();
            pline.Layer = ERARQLayers.LayerParcela;

            var pts = GetVertices(pline);
            double off = ERARQConfig.TextHeight * 1.2;
            string lay = ERARQLayers.LayerParcelaVert;

            int i = 1;
            foreach (var p in pts)
            {
                var labelPos = new Point3d(p.X + off, p.Y + off, 0.0);
                ERARQDraw.CreateText(labelPos, VertexText(i), lay, ERARQConfig.TextHeight);
                i++;
            }
        }

        /// <summary>
        /// Etiqueta vértices de parcela seleccionada
        /// </summary>
        [CommandMethod("ERARQ_VERTICES")]
        public void LabelVertices()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            var peo = new PromptEntityOptions("\nSeleccione la polilínea de la parcela: ");
            peo.SetRejectMessage("\nDebe seleccionar una LWPOLYLINE.");
            peo.AddAllowedClass(typeof(Polyline), false);
            var per = ed.GetEntity(peo);

            if (per.Status != PromptStatus.OK) return;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var pline = trans.GetObject(per.ObjectId, OpenMode.ForRead) as Polyline;
                
                if (pline != null)
                {
                    trans.Commit();
                    LabelVerticesOnObject(pline);
                    ed.WriteMessage("\nVértices de parcela etiquetados correctamente.");
                }
            }
        }

        /// <summary>
        /// Numera lotes seleccionados en orden
        /// </summary>
        [CommandMethod("ERARQ_LOTES")]
        public void NumberLots()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            // Seleccionar múltiples objetos
            var peo = new PromptSelectionOptions();
            peo.MessageForAdding = "\nSeleccione los lotes en orden: ";
            peo.AllowSubSelections = false;
            var ssr = ed.GetSelection(peo);

            if (ssr.Status != PromptStatus.OK || ssr.Value.Count == 0) return;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                int n = ERARQConfig.StartNumber;

                foreach (SelectedObject selObj in ssr.Value)
                {
                    var pline = trans.GetObject(selObj.ObjectId, OpenMode.ForWrite) as Polyline;
                    if (pline == null) continue;

                    ERARQLayers.EnsureLotLayers(n);

                    string polyLay = ERARQLayers.LayerLote(n);
                    string txtLay = ERARQLayers.LayerLoteTxt(n);

                    pline.Layer = polyLay;

                    var pts = GetVertices(pline);
                    var c = DivisionUtils.PolyCentroid(pts);

                    ERARQDraw.CreateText(c, LotLabelText(n), txtLay, ERARQConfig.TextHeight);

                    n++;
                }

                trans.Commit();
            }

            ed.WriteMessage("\nLotes numerados en el orden exacto de selección.");
        }

        /// <summary>
        /// Etiqueta vértices de cada lote seleccionado
        /// </summary>
        [CommandMethod("ERARQ_LOTES_VERTICES")]
        public void LabelLotVertices()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            // Seleccionar múltiples objetos
            var peo = new PromptSelectionOptions();
            peo.MessageForAdding = "\nSeleccione los lotes en orden: ";
            peo.AllowSubSelections = false;
            var ssr = ed.GetSelection(peo);

            if (ssr.Status != PromptStatus.OK || ssr.Value.Count == 0) return;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                int n = ERARQConfig.StartNumber;
                double off = ERARQConfig.TextHeight * 1.0;

                foreach (SelectedObject selObj in ssr.Value)
                {
                    var pline = trans.GetObject(selObj.ObjectId, OpenMode.ForWrite) as Polyline;
                    if (pline == null) continue;

                    ERARQLayers.EnsureLotLayers(n);
                    pline.Layer = ERARQLayers.LayerLote(n);

                    var pts = GetVertices(pline);
                    string lay = ERARQLayers.LayerLoteVert(n);

                    int i = 1;
                    foreach (var p in pts)
                    {
                        var labelPos = new Point3d(p.X + off, p.Y + off, 0.0);
                        ERARQDraw.CreateText(labelPos, LotVertexText(n, i), lay, ERARQConfig.TextHeight);
                        i++;
                    }

                    n++;
                }

                trans.Commit();
            }

            ed.WriteMessage("\nVértices por lote etiquetados en el orden exacto de selección.");
        }

        /// <summary>
        /// Calcula y muestra áreas de lotes seleccionados
        /// </summary>
        [CommandMethod("ERARQ_AREAS")]
        public void ShowAreas()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            var peo = new PromptSelectionOptions();
            peo.MessageForAdding = "\nSeleccione los lotes: ";
            var ssr = ed.GetSelection(peo);

            if (ssr.Status != PromptStatus.OK || ssr.Value.Count == 0) return;

            double totalArea = 0.0;
            int count = 0;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                foreach (SelectedObject selObj in ssr.Value)
                {
                    var pline = trans.GetObject(selObj.ObjectId, OpenMode.ForRead) as Polyline;
                    if (pline == null) continue;

                    var pts = GetVertices(pline);
                    double area = DivisionUtils.PolyArea(pts);
                    totalArea += area;
                    count++;

                    ed.WriteMessage($"\nÁrea del lote {count}: {area:F{ERARQConfig.DecArea}} m²");
                }
                trans.Commit();
            }

            ed.WriteMessage($"\n\nTotal de lotes: {count}");
            ed.WriteMessage($"\nÁrea total: {totalArea:F{ERARQConfig.DecArea}} m²");
        }

        /// <summary>
        /// Muestra coordenadas de vértices de parcela
        /// </summary>
        [CommandMethod("ERARQ_COORDS")]
        public void ShowCoords()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            var peo = new PromptEntityOptions("\nSeleccione la polilínea de la parcela: ");
            peo.SetRejectMessage("\nDebe seleccionar una LWPOLYLINE.");
            peo.AddAllowedClass(typeof(Polyline), false);
            var per = ed.GetEntity(peo);

            if (per.Status != PromptStatus.OK) return;

            using (var trans = db.TransactionManager.StartTransaction())
            {
                var pline = trans.GetObject(per.ObjectId, OpenMode.ForRead) as Polyline;
                
                if (pline != null)
                {
                    var pts = GetVertices(pline);
                    
                    ed.WriteMessage("\n=== COORDENADAS DE VÉRTICES ===");
                    for (int i = 0; i < pts.Count; i++)
                    {
                        var p = pts[i];
                        ed.WriteMessage($"\nV{i + 1}: N={p.Y:F{ERARQConfig.DecCoord}}, E={p.X:F{ERARQConfig.DecCoord}}");
                    }
                    trans.Commit();
                }
            }
        }
    }
}
