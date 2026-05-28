using Autodesk.AutoCAD.Runtime;
using Autodesk.AutoCAD.ApplicationServices;
using System.Windows;

namespace ERARQ_Urb.Commands
{
    /// <summary>
    /// Comandos para lanzar la interfaz WPF
    /// Reemplaza el diálogo DCL original
    /// </summary>
    public class ERARQUICommands
    {
        /// <summary>
        /// Comando principal ERARQ - Muestra la ventana WPF
        /// </summary>
        [CommandMethod("ERARQ")]
        public void ShowERARQWindow()
        {
            Document doc = Application.DocumentManager.MdiActiveDocument;
            
            if (doc == null)
            {
                Application.ShowAlertDialog("Error: No hay documento activo en AutoCAD");
                return;
            }

            // Crear y mostrar la ventana WPF modal
            var window = new ERARQWindow();
            window.Owner = Application.MainWindow.Window;
            
            // Mostrar como modal (bloquea AutoCAD hasta cerrar)
            bool? result = window.ShowDialog();
        }

        /// <summary>
        /// Comando ERARQ_INIT - Inicializa configuración por defecto
        /// </summary>
        [CommandMethod("ERARQ_INIT")]
        public void InitializeConfig()
        {
            Core.ERARQConfig.InitializeDefaults();
            
            Document doc = Application.DocumentManager.MdiActiveDocument;
            if (doc != null)
            {
                doc.Editor.WriteMessage("\n✓ Configuración ERARQ inicializada correctamente.");
            }
        }

        /// <summary>
        /// Comando ERARQ_DATOS - Muestra información de configuración actual
        /// </summary>
        [CommandMethod("ERARQ_DATOS")]
        public void ShowConfigData()
        {
            Document doc = Application.DocumentManager.MdiActiveDocument;
            if (doc == null) return;

            var config = Core.ERARQConfig.Instance;
            
            string msg = $"\n=== CONFIGURACIÓN ERARQ-Urb ===" +
                        $"\nEscala Plot: {config.PlotScale}" +
                        $"\nAltura Texto: {config.TextHeight}" +
                        $"\nPrecisión Área: {config.AreaPrecision} decimales" +
                        $"\nUnidad Área: {(config.AreaUnit == Core.AreaUnit.Hectares ? "Hectáreas" : "m²")}" +
                        $"\nCapa Polígono: {config.LayerPolygon}" +
                        $"\nCapa Texto: {config.LayerText}" +
                        $"\nCapa Tabla: {config.LayerTable}" +
                        $"\n================================";

            doc.Editor.WriteMessage(msg);
        }
    }
}
