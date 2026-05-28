using System;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using acApp = Autodesk.AutoCAD.ApplicationServices.Application;

namespace ERARQ_Urb
{
    /// <summary>
    /// Gestión de capas para ERARQ-Urb
    /// Portado desde erarq_layers.lsp
    /// </summary>
    public static class ERARQLayers
    {
        #region Nombres de Capas Base

        public static string LayerParcela => "ERARQ_PARCELA";
        public static string LayerParcelaTxt => "ERARQ_PARCELA_TXT";
        public static string LayerParcelaVert => "ERARQ_PARCELA_VERT";
        public static string LayerParcelaDist => "ERARQ_PARCELA_DIST";
        public static string LayerParcelaAng => "ERARQ_PARCELA_ANG";
        public static string LayerParcelaRumbo => "ERARQ_PARCELA_RUMBO";

        public static string LayerTablas => "ERARQ_TABLAS";
        public static string LayerTablasTec => "ERARQ_TABLAS_TEC";
        public static string LayerTablasCoord => "ERARQ_TABLAS_COORD";
        public static string LayerTablasCol => "ERARQ_TABLAS_COL";
        public static string LayerTablasArea => "ERARQ_TABLAS_AREA";
        public static string LayerTablasRepl => "ERARQ_TABLAS_REPL";

        public static string LayerGrid => "ERARQ_GRID";
        public static string LayerGridMinor => "ERARQ_GRID_MINOR";
        public static string LayerGridMajor => "ERARQ_GRID_MAJOR";
        public static string LayerGridMaster => "ERARQ_GRID_MASTER";
        public static string LayerGridBorder => "ERARQ_GRID_BORDER";
        public static string LayerGridTxt => "ERARQ_GRID_TXT";

        public static string LayerRepl => "ERARQ_REPL";
        public static string LayerReplTxt => "ERARQ_REPL_TXT";
        public static string LayerReplVert => "ERARQ_REPL_VERT";

        #endregion

        #region Nombres de Capas por Lote

        public static string LayerLote(int n) => $"ERARQ_LOTES_{n}";
        public static string LayerLoteTxt(int n) => $"ERARQ_LOTES_{n}_TXT";
        public static string LayerLoteVert(int n) => $"ERARQ_LOTES_{n}_VERT";
        public static string LayerLoteDist(int n) => $"ERARQ_LOTES_{n}_DIST";
        public static string LayerLoteAng(int n) => $"ERARQ_LOTES_{n}_ANG";
        public static string LayerLoteRumbo(int n) => $"ERARQ_LOTES_{n}_RUMBO";
        public static string LayerLoteArea(int n) => $"ERARQ_LOTES_{n}_AREA";

        #endregion

        #region Colores (Escala de Grises)

        // 7 = blanco/negro según fondo
        // 8 = gris oscuro
        // 9 = gris medio
        private static int ColMain => 7;
        private static int ColStrong => 8;
        private static int ColMedium => 9;
        private static int ColSoft => 8;
        private static int ColVerySoft => 9;

        #endregion

        #region Utilidades de Capas

        /// <summary>
        /// Verifica si una capa existe
        /// </summary>
        public static bool LayerExists(string layerName)
        {
            var db = ERARQUtils.GetDatabase();
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                LayerTable lt = tr.GetObject(db.LayerTableId, OpenMode.ForRead) as LayerTable;
                bool exists = lt.Has(layerName);
                tr.Commit();
                return exists;
            }
        }

        /// <summary>
        /// Asegura que una capa existe, la crea si no existe
        /// </summary>
        public static ObjectId EnsureLayer(string layerName)
        {
            var db = ERARQUtils.GetDatabase();
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                LayerTable lt = tr.GetObject(db.LayerTableId, OpenMode.ForRead) as LayerTable;
                
                if (!lt.Has(layerName))
                {
                    LayerTableRecord ltr = new LayerTableRecord();
                    ltr.Name = layerName;
                    
                    lt.UpgradeOpen();
                    ObjectId layerId = lt.Add(ltr);
                    tr.AddNewlyCreatedDBObject(ltr, true);
                    tr.Commit();
                    return layerId;
                }
                
                tr.Commit();
                return lt[layerName];
            }
        }

        /// <summary>
        /// Configura una capa con color, tipo de línea y grosor
        /// </summary>
        public static void LayerSetup(string layerName, int color, string linetype, int lineweight)
        {
            EnsureLayer(layerName);
            
            var db = ERARQUtils.GetDatabase();
            using (Transaction tr = db.TransactionManager.StartTransaction())
            {
                LayerTable lt = tr.GetObject(db.LayerTableId, OpenMode.ForRead) as LayerTable;
                LayerTableRecord ltr = tr.GetObject(lt[layerName], OpenMode.ForWrite) as LayerTableRecord;

                // Descongelar, activar y desbloquear
                ltr.IsFrozen = false;
                ltr.IsOff = false;
                ltr.IsLocked = false;

                // Configurar propiedades
                ltr.Color = Color.FromColorIndex(ColorMethod.ByAci, (short)color);
                
                if (!string.IsNullOrEmpty(linetype) && linetype != "Continuous")
                {
                    // Asegurar que el tipo de línea existe
                    LinetypeTable ltt = tr.GetObject(db.LinetypeTableId, OpenMode.ForRead) as LinetypeTable;
                    if (!ltt.Has(linetype))
                    {
                        // Intentar cargar desde acad.lin
                        ltt.UpgradeOpen();
                        try
                        {
                            ltt.Add(linetype, "acad.lin", "Continuous line");
                        }
                        catch { }
                    }
                    ltr.LinetypeObjectId = ltt[linetype];
                }

                // Grosor de línea (valores en unidades de base de datos AutoCAD)
                // -1 = Default, 13 = 0.13mm, 15 = 0.15mm, etc.
                ltr.LineWeight = (LineWeight)lineweight;

                tr.Commit();
            }
        }

        /// <summary>
        /// Configura múltiples capas desde una lista
        /// </summary>
        public static void LayerSetupList(params Tuple<string, int, string, int>[] layers)
        {
            foreach (var layer in layers)
            {
                LayerSetup(layer.Item1, layer.Item2, layer.Item3, layer.Item4);
            }
        }

        #endregion

        #region Configuración de Capas Base

        /// <summary>
        /// Crea/actualiza todas las capas base del sistema
        /// </summary>
        public static void EnsureBaseLayers()
        {
            LayerSetupList(
                // PARCELA
                Tuple.Create(LayerParcela, ColMain, "Continuous", 40),
                Tuple.Create(LayerParcelaTxt, ColMain, "Continuous", 18),
                Tuple.Create(LayerParcelaVert, ColStrong, "Continuous", 18),
                Tuple.Create(LayerParcelaDist, ColMedium, "Continuous", 18),
                Tuple.Create(LayerParcelaAng, ColMedium, "Continuous", 15),
                Tuple.Create(LayerParcelaRumbo, ColMedium, "Continuous", 18),

                // TABLAS
                Tuple.Create(LayerTablas, ColMain, "Continuous", 25),
                Tuple.Create(LayerTablasTec, ColStrong, "Continuous", 18),
                Tuple.Create(LayerTablasCoord, ColStrong, "Continuous", 18),
                Tuple.Create(LayerTablasCol, ColMedium, "Continuous", 18),
                Tuple.Create(LayerTablasArea, ColMain, "Continuous", 20),
                Tuple.Create(LayerTablasRepl, ColStrong, "Continuous", 18),

                // GRILLA
                Tuple.Create(LayerGrid, ColVerySoft, "Continuous", 13),
                Tuple.Create(LayerGridMinor, ColVerySoft, "Continuous", 13),
                Tuple.Create(LayerGridMajor, ColSoft, "Continuous", 18),
                Tuple.Create(LayerGridMaster, ColStrong, "Continuous", 25),
                Tuple.Create(LayerGridBorder, ColMain, "Continuous", 35),
                Tuple.Create(LayerGridTxt, ColMedium, "Continuous", 13),

                // REPLANTEO
                Tuple.Create(LayerRepl, ColMain, "Continuous", 25),
                Tuple.Create(LayerReplTxt, ColStrong, "Continuous", 18),
                Tuple.Create(LayerReplVert, ColStrong, "Continuous", 18)
            );
        }

        /// <summary>
        /// Crea/actualiza las capas para un lote específico
        /// </summary>
        public static void EnsureLotLayers(int n)
        {
            LayerSetupList(
                Tuple.Create(LayerLote(n), ColMain, "Continuous", 30),
                Tuple.Create(LayerLoteTxt(n), ColMain, "Continuous", 18),
                Tuple.Create(LayerLoteVert(n), ColStrong, "Continuous", 18),
                Tuple.Create(LayerLoteDist(n), ColMedium, "Continuous", 18),
                Tuple.Create(LayerLoteAng(n), ColMedium, "Continuous", 15),
                Tuple.Create(LayerLoteRumbo(n), ColMedium, "Continuous", 18),
                Tuple.Create(LayerLoteArea(n), ColMain, "Continuous", 20)
            );
        }

        #endregion

        #region Comandos

        /// <summary>
        /// Comando para crear/actualizar capas base
        /// </summary>
        [Autodesk.AutoCAD.Runtime.CommandMethod("ERARQ_LAYERS")]
        public static void LayersCommand()
        {
            EnsureBaseLayers();
            var ed = ERARQUtils.GetEditor();
            ed?.WriteMessage("\n[ERARQ] Capas base de presentacion final creadas/actualizadas en escala de grises.");
        }

        /// <summary>
        /// Comando para crear capas de un lote específico
        /// </summary>
        [Autodesk.AutoCAD.Runtime.CommandMethod("ERARQ_LOTE_LAYERS")]
        public static void LoteLayersCommand()
        {
            var ed = ERARQUtils.GetEditor();
            if (ed == null) return;

            var pio = new PromptIntegerOptions("\nNumero de lote: ");
            var pir = ed.GetInteger(pio);
            
            if (pir.Status == PromptStatus.OK && pir.Value > 0)
            {
                EnsureLotLayers(pir.Value);
                ed.WriteMessage($"\n[ERARQ] Capas del lote {pir.Value} creadas/actualizadas.");
            }
            else
            {
                ed.WriteMessage("\n[ERARQ] Numero invalido.");
            }
        }

        #endregion
    }
}
