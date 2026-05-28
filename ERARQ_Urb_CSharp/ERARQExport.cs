using System;
using System.Collections.Generic;
using System.IO;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using acApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace ERARQ_Urb
{
    /// <summary>
    /// Comandos de exportación a CSV
    /// </summary>
    public class ERARQExportCommands
    {
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
        /// Formatea número con decimales específicos
        /// </summary>
        private static string FormatNumber(double val, int decimals)
        {
            return val.ToString($"F{decimals}");
        }

        /// <summary>
        /// Exporta coordenadas de parcela a CSV
        /// </summary>
        [CommandMethod("ERARQ_EXPORT_COORDS")]
        public void ExportCoordinatesCSV()
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
                
                if (pline == null)
                {
                    trans.Commit();
                    return;
                }

                var pts = GetVertices(pline);
                double area = DivisionUtils.PolyArea(pts);
                double perimeter = 0.0;
                
                // Calcular perímetro
                var closedPts = DivisionUtils.ClosePts(new List<Point3d>(pts));
                for (int i = 0; i < closedPts.Count - 1; i++)
                {
                    perimeter += closedPts[i].DistanceTo(closedPts[i + 1]);
                }

                trans.Commit();

                // Diálogo para guardar archivo
                var fd = new SaveFileDialog();
                fd.Filter = "Archivos CSV (*.csv)|*.csv";
                fd.InitialDirectory = Path.GetDirectoryName(doc.Name);
                fd.FileName = $"{ERARQConfig.ParcelName}_coordenadas.csv";
                
                if (fd.ShowDialog() != System.Windows.Forms.DialogResult.OK)
                    return;

                string path = fd.FileName;

                using (var writer = new StreamWriter(path))
                {
                    writer.WriteLine($"PROYECTO,{ERARQConfig.Project}");
                    writer.WriteLine($"PARCELA,{ERARQConfig.ParcelName}");
                    writer.WriteLine($"VERTICES,{pts.Count}");
                    writer.WriteLine($"AREA_M2,{FormatNumber(area, ERARQConfig.DecArea)}");
                    writer.WriteLine($"PERIMETRO_ML,{FormatNumber(perimeter, ERARQConfig.DecDist)}");
                    writer.WriteLine("");
                    writer.WriteLine("ID,X,Y");

                    for (int i = 0; i < pts.Count; i++)
                    {
                        var p = pts[i];
                        writer.WriteLine(
                            $"V{i + 1},{FormatNumber(p.X, ERARQConfig.DecCoord)},{FormatNumber(p.Y, ERARQConfig.DecCoord)}");
                    }
                }

                ed.WriteMessage($"\nCSV exportado: {path}");
            }
        }

        /// <summary>
        /// Exporta áreas de múltiples lotes a CSV
        /// </summary>
        [CommandMethod("ERARQ_EXPORT_AREAS")]
        public void ExportAreasCSV()
        {
            var doc = acApp.DocumentManager.MdiActiveDocument;
            var ed = doc.Editor;
            var db = doc.Database;

            // Seleccionar múltiples polilíneas cerradas
            var peo = new PromptSelectionOptions();
            peo.MessageForAdding = "\nSeleccione los lotes (polilíneas cerradas): ";
            var ssr = ed.GetSelection(peo);

            if (ssr.Status != PromptStatus.OK || ssr.Value.Count == 0) return;

            var objects = new List<Polyline>();

            using (var trans = db.TransactionManager.StartTransaction())
            {
                foreach (SelectedObject selObj in ssr.Value)
                {
                    var pline = trans.GetObject(selObj.ObjectId, OpenMode.ForRead) as Polyline;
                    if (pline != null && pline.Closed)
                        objects.Add(pline);
                }
                trans.Commit();
            }

            if (objects.Count == 0)
            {
                ed.WriteMessage("\nNo se seleccionaron polilíneas cerradas válidas.");
                return;
            }

            // Ordenar objetos por posición (grid sort simple)
            objects.Sort((a, b) =>
            {
                var extA = a.GeometricExtents;
                var extB = b.GeometricExtents;
                
                // Primero por Y (de abajo hacia arriba)
                int cmpY = extA.MinPoint.Y.CompareTo(extB.MinPoint.Y);
                if (Math.Abs(cmpY) > 1e-6)
                    return -cmpY; // Invertido: de arriba hacia abajo
                
                // Luego por X (de izquierda a derecha)
                return extA.MinPoint.X.CompareTo(extB.MinPoint.X);
            });

            // Diálogo para guardar archivo
            var fd = new SaveFileDialog();
            fd.Filter = "Archivos CSV (*.csv)|*.csv";
            fd.InitialDirectory = Path.GetDirectoryName(doc.Name);
            fd.FileName = $"{ERARQConfig.Project}_areas.csv";
            
            if (fd.ShowDialog() != System.Windows.Forms.DialogResult.OK)
                return;

            string path = fd.FileName;

            using (var writer = new StreamWriter(path))
            {
                writer.WriteLine($"PROYECTO,{ERARQConfig.Project}");
                writer.WriteLine("LOTE,AREA_M2,PERIMETRO_ML");

                int n = ERARQConfig.StartNumber;
                foreach (var pline in objects)
                {
                    var pts = GetVertices(pline);
                    double area = DivisionUtils.PolyArea(pts);
                    
                    double perimeter = 0.0;
                    var closedPts = DivisionUtils.ClosePts(new List<Point3d>(pts));
                    for (int i = 0; i < closedPts.Count - 1; i++)
                    {
                        perimeter += closedPts[i].DistanceTo(closedPts[i + 1]);
                    }

                    writer.WriteLine(
                        $"{ERARQConfig.LotPrefix}{n},{FormatNumber(area, ERARQConfig.DecArea)},{FormatNumber(perimeter, ERARQConfig.DecDist)}");
                    
                    n++;
                }
            }

            ed.WriteMessage($"\nCSV exportado: {path}");
        }
    }
}
