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
    /// Módulo de dimensionamiento y documentación de parcelas y lotes
    /// Portado desde erarq_dims.lsp
    /// </summary>
    public static class ERARQDims
    {
        #region Utilidades Vectoriales

        public static double Clamp(double v, double a, double b)
        {
            return Math.Max(a, Math.Min(b, v));
        }

        public static Point3d VecAdd(Point3d a, Point3d b)
        {
            return new Point3d(a.X + b.X, a.Y + b.Y, 0.0);
        }

        public static Point3d VecSub(Point3d a, Point3d b)
        {
            return new Point3d(a.X - b.X, a.Y - b.Y, 0.0);
        }

        public static Point3d VecScale(Point3d v, double s)
        {
            return new Point3d(v.X * s, v.Y * s, 0.0);
        }

        public static double VecDot(Point3d a, Point3d b)
        {
            return a.X * b.X + a.Y * b.Y;
        }

        public static double VecLen(Point3d v)
        {
            return Math.Sqrt(v.X * v.X + v.Y * v.Y);
        }

        public static Point3d VecUnit(Point3d v)
        {
            double l = VecLen(v);
            if (l > 1e-12)
                return new Point3d(v.X / l, v.Y / l, 0.0);
            return new Point3d(0.0, 0.0, 0.0);
        }

        public static Point3d VecPerpLeft(Point3d v)
        {
            return new Point3d(-v.Y, v.X, 0.0);
        }

        public static Point3d Midpoint(Point3d p1, Point3d p2)
        {
            return new Point3d((p1.X + p2.X) / 2.0, (p1.Y + p2.Y) / 2.0, 0.0);
        }

        public static Point3d PolarPt(Point3d p, double ang, double dist)
        {
            return new Point3d(p.X + dist * Math.Cos(ang), p.Y + dist * Math.Sin(ang), 0.0);
        }

        public static double AcosSafe(double x)
        {
            double v = Clamp(x, -1.0, 1.0);
            return Math.Atan(Math.Sqrt(Math.Max(0.0, 1.0 - v * v)), v);
        }

        #endregion

        #region Ángulos

        public static double AngNorm(double a)
        {
            while (a < 0.0)
                a += 2.0 * Math.PI;
            while (a >= 2.0 * Math.PI)
                a -= 2.0 * Math.PI;
            return a;
        }

        public static double AngleDiffCCW(double a1, double a2)
        {
            double d = AngNorm(a2) - AngNorm(a1);
            while (d < 0.0)
                d += 2.0 * Math.PI;
            while (d >= 2.0 * Math.PI)
                d -= 2.0 * Math.PI;
            return d;
        }

        public static double AngleMidCCW(double a1, double a2)
        {
            double d = AngleDiffCCW(a1, a2);
            return AngNorm(a1 + d / 2.0);
        }

        public static double AngleReadable(double rot)
        {
            rot = AngNorm(rot);
            if (rot > Math.PI / 2.0 && rot < 1.5 * Math.PI)
                rot += Math.PI;
            return AngNorm(rot);
        }

        #endregion

        #region Apoyo Geométrico

        public static Point3d SideNormalOutward(Point3d p1, Point3d p2, Point3d ctr)
        {
            Point3d mid = Midpoint(p1, p2);
            Point3d edge = VecSub(p2, p1);
            Point3d n = VecUnit(VecPerpLeft(edge));
            Point3d testPt = VecAdd(mid, VecScale(n, 1.0));

            if (testPt.DistanceTo(ctr) < mid.DistanceTo(ctr))
                n = VecScale(n, -1.0);

            return n;
        }

        public static Point3d SideNormalInward(Point3d p1, Point3d p2, Point3d ctr)
        {
            return VecScale(SideNormalOutward(p1, p2, ctr), -1.0);
        }

        public static Point3d SideTextPoint(Point3d p1, Point3d p2, Point3d ctr, 
            double offAlong, double offNormal, bool outwardP)
        {
            Point3d mid = Midpoint(p1, p2);
            Point3d dir = VecUnit(VecSub(p2, p1));
            Point3d n = outwardP ? SideNormalOutward(p1, p2, ctr) : SideNormalInward(p1, p2, ctr);

            return VecAdd(VecAdd(mid, VecScale(dir, offAlong)), VecScale(n, offNormal));
        }

        public static bool AngleSideFacingCentroidP(Point3d p, double a1, double a2, Point3d ctr)
        {
            double amid = AngleMidCCW(a1, a2);
            Point3d testPt = PolarPt(p, amid, 1.0);
            return testPt.DistanceTo(ctr) < p.DistanceTo(ctr);
        }

        public static Tuple<double, double> ChooseInternalArcAngles(Point3d pPrev, Point3d p, 
            Point3d pNext, Point3d ctr)
        {
            double aPrev = AngNorm(Math.Atan2(p.Y - pPrev.Y, p.X - pPrev.X));
            double aNext = AngNorm(Math.Atan2(p.Y - pNext.Y, p.X - pNext.X));

            if (AngleSideFacingCentroidP(p, aPrev, aNext, ctr))
                return Tuple.Create(aPrev, aNext);
            else
                return Tuple.Create(aNext, aPrev);
        }

        public static double InternalAngleDegDirected(Point3d pPrev, Point3d p, Point3d pNext, Point3d ctr)
        {
            var aa = ChooseInternalArcAngles(pPrev, p, pNext, ctr);
            double a1 = aa.Item1;
            double a2 = aa.Item2;
            return 180.0 * AngleDiffCCW(a1, a2) / Math.PI;
        }

        public static Point3d InternalAngleTextPoint(Point3d pPrev, Point3d p, Point3d pNext, 
            Point3d ctr, double fac)
        {
            var aa = ChooseInternalArcAngles(pPrev, p, pNext, ctr);
            double a1 = aa.Item1;
            double a2 = aa.Item2;
            double amid = AngleMidCCW(a1, a2);
            return PolarPt(p, amid, fac);
        }

        public static double InternalAngleTextRotation(Point3d pPrev, Point3d p, Point3d pNext, Point3d ctr)
        {
            var aa = ChooseInternalArcAngles(pPrev, p, pNext, ctr);
            double a1 = aa.Item1;
            double a2 = aa.Item2;
            double amid = AngleMidCCW(a1, a2);
            double rot = amid - Math.PI / 2.0;
            return AngleReadable(rot);
        }

        #endregion

        #region Dibujo de Entidades

        public static void DrawAngleArcInternal(Point3d pPrev, Point3d p, Point3d pNext, 
            Point3d ctr, double rad, string lay)
        {
            var aa = ChooseInternalArcAngles(pPrev, p, pNext, ctr);
            double a1 = aa.Item1;
            double a2 = aa.Item2;

            using (Transaction tr = ERARQBase.StartTransaction())
            {
                BlockTable bt = (BlockTable)tr.GetObject(acApp.DocumentManager.MdiActiveDocument.Database.BlockTableId, OpenMode.ForRead);
                BlockTableRecord btr = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

                Arc arc = new Arc(new Circle(p, Vector3d.ZAxis, rad).Center, Vector3d.ZAxis, rad, a1, a2);
                arc.Layer = lay;
                ERARQBase.EnsureLayerExists(lay);
                
                btr.AppendEntity(arc);
                tr.AddNewlyCreatedDBObject(arc, true);
                tr.Commit();
            }
        }

        public static void DrawTextRot(Point3d pt, string txt, double hgt, double rot, string lay)
        {
            using (Transaction tr = ERARQBase.StartTransaction())
            {
                BlockTable bt = (BlockTable)tr.GetObject(acApp.DocumentManager.MdiActiveDocument.Database.BlockTableId, OpenMode.ForRead);
                BlockTableRecord btr = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

                DBText text = new DBText();
                text.Position = pt;
                text.AlignmentPoint = pt;
                text.Height = hgt;
                text.TextString = txt;
                text.Justify = AttachmentPoint.MiddleCenter;
                text.Rotation = rot;
                text.Layer = lay;
                ERARQBase.EnsureLayerExists(lay);

                btr.AppendEntity(text);
                tr.AddNewlyCreatedDBObject(text, true);
                tr.Commit();
            }
        }

        public static void DrawMTextCenter(Point3d pt, double width, string txt, double hgt, string lay)
        {
            using (Transaction tr = ERARQBase.StartTransaction())
            {
                BlockTable bt = (BlockTable)tr.GetObject(acApp.DocumentManager.MdiActiveDocument.Database.BlockTableId, OpenMode.ForRead);
                BlockTableRecord btr = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

                MText mtext = new MText();
                mtext.Location = pt;
                mtext.Width = width;
                mtext.Contents = txt;
                mtext.TextHeight = hgt;
                mtext.Layer = lay;
                ERARQBase.EnsureLayerExists(lay);

                btr.AppendEntity(mtext);
                tr.AddNewlyCreatedDBObject(mtext, true);
                tr.Commit();
            }
        }

        #endregion

        #region Documentación de Objetos

        public static void DrawDistancesOnObject(Polyline obj, string lay)
        {
            List<Point3d> pts = ERARQBase.GetPolygonVertices(obj);
            Point3d ctr = ERARQBase.PolygonCentroid(pts);
            int n = pts.Count;

            for (int i = 0; i < n; i++)
            {
                Point3d p1 = pts[i];
                Point3d p2 = pts[(i == n - 1) ? 0 : i + 1];

                Point3d pt = SideTextPoint(p1, p2, ctr, 0.0, ERARQConfig.SmallTextHeight * 1.20, true);
                string txt = ERARQBase.NumToStr(p1.DistanceTo(p2), ERARQConfig.DecDist);
                double rot = AngleReadable(Math.Atan2(p2.Y - p1.Y, p2.X - p1.X));

                DrawTextRot(pt, txt, ERARQConfig.SmallTextHeight, rot, lay);
            }
        }

        public static void DrawRumbosOnObject(Polyline obj, string lay)
        {
            List<Point3d> pts = ERARQBase.GetPolygonVertices(obj);
            Point3d ctr = ERARQBase.PolygonCentroid(pts);
            int n = pts.Count;

            for (int i = 0; i < n; i++)
            {
                Point3d p1 = pts[i];
                Point3d p2 = pts[(i == n - 1) ? 0 : i + 1];

                Point3d pt = SideTextPoint(p1, p2, ctr, 0.0, ERARQConfig.SmallTextHeight * 2.30, true);
                double az = ERARQBase.AzimuthDeg(p1, p2);
                string rumbo = ERARQBase.AzimuthToRumbo(az);
                double rot = AngleReadable(Math.Atan2(p2.Y - p1.Y, p2.X - p1.X));

                DrawTextRot(pt, rumbo, ERARQConfig.SmallTextHeight, rot, lay);
            }
        }

        public static void DrawAnglesOnObject(Polyline obj, string lay)
        {
            List<Point3d> pts = ERARQBase.GetPolygonVertices(obj);
            Point3d ctr = ERARQBase.PolygonCentroid(pts);
            int n = pts.Count;

            double arcRad = ERARQConfig.SmallTextHeight * 1.40;
            double txtFac = ERARQConfig.SmallTextHeight * 2.40;

            for (int i = 0; i < n; i++)
            {
                Point3d pPrev = pts[(i == 0) ? n - 1 : i - 1];
                Point3d p = pts[i];
                Point3d pNext = pts[(i == n - 1) ? 0 : i + 1];

                double ang = InternalAngleDegDirected(pPrev, p, pNext, ctr);
                Point3d txtPt = InternalAngleTextPoint(pPrev, p, pNext, ctr, txtFac);
                double rot = InternalAngleTextRotation(pPrev, p, pNext, ctr);

                DrawAngleArcInternal(pPrev, p, pNext, ctr, arcRad, lay);
                DrawTextRot(txtPt, ERARQBase.DegToDmsStr(ang), ERARQConfig.SmallTextHeight, rot, lay);
            }
        }

        public static void DrawAreaPerimOnObject(Polyline obj, string lotName, string lay)
        {
            List<Point3d> pts = ERARQBase.GetPolygonVertices(obj);
            Point3d ctr = ERARQBase.PolygonCentroid(pts);
            double area = ERARQBase.PolygonArea(pts);
            double per = ERARQBase.PolygonPerimeter(pts);

            string txt = lotName;

            if (ERARQConfig.DrawArea)
                txt += $"\\PArea: {ERARQBase.NumToStr(area, ERARQConfig.DecArea)} m2";

            if (ERARQConfig.DrawPerim)
                txt += $"\\PPerimetro: {ERARQBase.NumToStr(per, ERARQConfig.DecDist)} m";

            DrawMTextCenter(ctr, ERARQConfig.TextHeight * 25.0, txt, ERARQConfig.TextHeight, lay);
        }

        #endregion

        #region Comandos

        /// <summary>
        /// Documentación completa de parcela
        /// </summary>
        [CommandMethod("ERARQ_PARCELA")]
        public static void ParcelDocCommand()
        {
            Document doc = acApp.DocumentManager.MdiActiveDocument;
            Editor ed = doc.Editor;

            PromptEntityOptions peo = new PromptEntityOptions("\nSeleccione polilínea de parcela: ");
            peo.SetRejectMessage("\nSolo polilíneas cerradas.");
            peo.AddAllowedClass(typeof(Polyline), false);

            PromptEntityResult per = ed.GetEntity(peo);
            if (per.Status != PromptStatus.OK)
                return;

            using (Transaction tr = ERARQBase.StartTransaction())
            {
                Polyline obj = (Polyline)tr.GetObject(per.ObjectId, OpenMode.ForRead);
                
                if (!(obj.Closed && obj.NumberOfVertices >= 3))
                {
                    ed.WriteMessage("\nLa polilínea debe estar cerrada.");
                    return;
                }

                ERARQBase.StartUndo();
                ERARQBase.EnsureBaseLayers();

                obj.UpgradeOpen();
                obj.Layer = ERARQLayers.LayerParcela;

                if (ERARQConfig.DocVerticesParcel)
                    ERARQLabels.LabelVerticesOnObject(obj);

                if (ERARQConfig.DrawDistances)
                    DrawDistancesOnObject(obj, ERARQLayers.LayerParcelaDist);

                if (ERARQConfig.DrawAngles)
                    DrawAnglesOnObject(obj, ERARQLayers.LayerParcelaAng);

                if (ERARQConfig.DocRumbosParcel)
                    DrawRumbosOnObject(obj, ERARQLayers.LayerParcelaRumbo);

                if (ERARQConfig.DrawArea || ERARQConfig.DrawPerim)
                    DrawAreaPerimOnObject(obj, ERARQConfig.ParcelName, ERARQLayers.LayerParcelaTxt);

                ERARQBase.EndUndo();
                tr.Commit();
            }

            ed.WriteMessage("\nParcela documentada.");
        }

        /// <summary>
        /// Documentación múltiple de lotes
        /// </summary>
        [CommandMethod("ERARQ_LOTES_DOC")]
        public static void LotsDocCommand()
        {
            Document doc = acApp.DocumentManager.MdiActiveDocument;
            Editor ed = doc.Editor;

            PromptSelectionOptions pso = new PromptSelectionOptions();
            pso.MessageForAdding = "\nSeleccione lotes (polilíneas): ";
            pso.MessageForRemoving = "\nRemover selección: ";

            TypedFilter[] filters = new TypedFilter[] {
                new TypedFilter((int)DxfCode.Start, "LWPOLYLINE")
            };
            SelectionFilter sf = new SelectionFilter(filters);

            PromptSelectionResult psr = ed.GetSelection(pso, sf);
            if (psr.Status != PromptStatus.OK)
                return;

            SelectionSet ss = psr.Value;
            if (ss.Count == 0)
            {
                ed.WriteMessage("\nNo se seleccionaron lotes.");
                return;
            }

            List<Polyline> objs = new List<Polyline>();
            using (Transaction tr = ERARQBase.StartTransaction())
            {
                foreach (SelectedObject so in ss)
                {
                    try
                    {
                        Polyline pl = (Polyline)tr.GetObject(so.ObjectId, OpenMode.ForRead);
                        if (pl.Closed && pl.NumberOfVertices >= 3)
                            objs.Add(pl);
                    }
                    catch { }
                }
            }

            if (objs.Count == 0)
            {
                ed.WriteMessage("\nNo hay lotes válidos.");
                return;
            }

            int n = ERARQConfig.StartNumber;

            using (Transaction tr = ERARQBase.StartTransaction())
            {
                ERARQBase.StartUndo();

                if (ERARQConfig.DocNumberLots)
                    ERARQLabels.NumberLotsOnList(objs);

                if (ERARQConfig.DocVerticesLots)
                    ERARQLabels.LabelLotVerticesOnList(objs);

                if (ERARQConfig.DrawDistances)
                {
                    foreach (var o in objs)
                    {
                        ERARQLayers.EnsureLotLayers(n);
                        DrawDistancesOnObject(o, ERARQLayers.LayerLoteDist(n));
                        n++;
                    }
                    n = ERARQConfig.StartNumber;
                }

                if (ERARQConfig.DrawAngles)
                {
                    foreach (var o in objs)
                    {
                        ERARQLayers.EnsureLotLayers(n);
                        DrawAnglesOnObject(o, ERARQLayers.LayerLoteAng(n));
                        n++;
                    }
                    n = ERARQConfig.StartNumber;
                }

                if (ERARQConfig.DocRumbosLots)
                {
                    foreach (var o in objs)
                    {
                        ERARQLayers.EnsureLotLayers(n);
                        DrawRumbosOnObject(o, ERARQLayers.LayerLoteRumbo(n));
                        n++;
                    }
                    n = ERARQConfig.StartNumber;
                }

                if (ERARQConfig.DrawArea || ERARQConfig.DrawPerim)
                {
                    foreach (var o in objs)
                    {
                        ERARQLayers.EnsureLotLayers(n);
                        DrawAreaPerimOnObject(o, $"{ERARQConfig.LotPrefix}{n}", ERARQLayers.LayerLoteArea(n));
                        n++;
                    }
                }

                ERARQBase.EndUndo();
                tr.Commit();
            }

            ed.WriteMessage($"\n{n - ERARQConfig.StartNumber} lotes documentados.");
        }

        #endregion
    }
}
