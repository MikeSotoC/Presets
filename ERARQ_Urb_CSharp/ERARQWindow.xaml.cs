using System;
using System.Windows;
using System.Windows.Controls;
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.DatabaseServices;
using ERARQ_Urb.Core;

namespace ERARQ_Urb
{
    /// <summary>
    /// Interfaz de usuario WPF para ERARQ-Urb
    /// Reemplaza el archivo DCL original de AutoLISP
    /// </summary>
    public partial class ERARQWindow : Window
    {
        private Document _doc;
        private Editor _ed;
        private Database _db;

        public ERARQWindow()
        {
            InitializeComponent();
            
            _doc = Application.DocumentManager.MdiActiveDocument;
            _ed = _doc?.Editor;
            _db = _doc?.Database;

            if (_doc == null)
            {
                txtStatus.Text = "Error: No hay documento activo en AutoCAD";
                txtStatus.Foreground = System.Windows.Media.Brushes.Red;
            }

            // Configurar eventos de habilitación
            radCutAngle.Checked += (s, e) => txtCutAngle.IsEnabled = true;
            radCutParallel.Checked += (s, e) => txtCutAngle.IsEnabled = false;
            radCutPerpendicular.Checked += (s, e) => txtCutAngle.IsEnabled = false;
        }

        #region Configuración
        
        private void BtnSaveConfig_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                // Guardar configuración global
                double scale = 1000;
                double.TryParse(txtScale.Text, out scale);
                
                double textHeight = 2.5;
                double.TryParse(txtTextHeight.Text, out textHeight);

                int areaPrecision = cmbAreaPrecision.SelectedIndex;
                int areaUnit = cmbAreaUnit.SelectedIndex;

                // Actualizar configuración estática
                ERARQConfig.PlotScale = scale;
                ERARQConfig.TextHeight = textHeight;
                ERARQConfig.AreaPrecision = areaPrecision;
                ERARQConfig.AreaUnit = areaUnit == 1 ? AreaUnit.Hectares : AreaUnit.SquareMeters;
                
                // Guardar nombres de capas
                ERARQConfig.LayerPolygon = txtLayerPoly.Text;
                ERARQConfig.LayerText = txtLayerText.Text;
                ERARQConfig.LayerTable = txtLayerTable.Text;

                MessageBox.Show("Configuración guardada exitosamente", "ERARQ-Urb", 
                    MessageBoxButton.OK, MessageBoxImage.Information);
                
                txtStatus.Text = "Configuración actualizada correctamente";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error al guardar: {ex.Message}", "Error", 
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        #endregion

        #region Tablas Técnicas

        private void BtnTableSimple_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_TABLE_SIMPLE");
        }

        private void BtnTableRumbos_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_TABLE_RUMBOS");
        }

        private void BtnTableAngles_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_TABLE_ANGULOS");
        }

        private void BtnTableMix_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_TABLE_MIXTA");
        }

        #endregion

        #region División

        private void BtnExecuteDivide_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                bool divideEqual = radDivEqual.IsChecked ?? true;
                
                if (divideEqual)
                {
                    int count = 2;
                    if (!int.TryParse(txtDivCount.Text, out count) || count < 2)
                    {
                        MessageBox.Show("Ingrese un número válido de lotes (mínimo 2)", "Error",
                            MessageBoxButton.OK, MessageBoxImage.Warning);
                        return;
                    }
                    
                    // Ejecutar división en partes iguales
                    _ed.Command("_.ERARQ_DIVIDE_EQUAL", count);
                }
                else
                {
                    double area = 500;
                    if (!double.TryParse(txtDivArea.Text, out area) || area <= 0)
                    {
                        MessageBox.Show("Ingrese un área válida mayor a 0", "Error",
                            MessageBoxButton.OK, MessageBoxImage.Warning);
                        return;
                    }

                    // Determinar método de corte
                    string cutMethod = "P"; // Parallel por defecto
                    if (radCutPerpendicular.IsChecked == true)
                        cutMethod = "E"; // Perpendicular
                    else if (radCutAngle.IsChecked == true)
                        cutMethod = "A"; // Angle

                    double angle = 90;
                    if (cutMethod == "A")
                        double.TryParse(txtCutAngle.Text, out angle);

                    _ed.Command("_.ERARQ_DIVIDE_AREA", area, cutMethod, angle);
                }

                txtStatus.Text = "División ejecutada - Verifique el dibujo";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error en división: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        #endregion

        #region Grilla y Etiquetado

        private void BtnCreateGrid_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                bool autoDetect = chkGridAuto.IsChecked ?? false;
                
                double spacingX = 10, spacingY = 10;
                double.TryParse(txtGridX.Text, out spacingX);
                double.TryParse(txtGridY.Text, out spacingY);

                if (autoDetect)
                    _ed.Command("_.ERARQ_GRID_AUTO", spacingX, spacingY);
                else
                    _ed.Command("_.ERARQ_GRID", spacingX, spacingY);

                txtStatus.Text = "Grilla generada exitosamente";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error creando grilla: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnLabelVerts_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_VERTICES");
        }

        private void BtnLabelLots_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_LOTES");
        }

        private void BtnLabelAreas_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_AREAS");
        }

        private void BtnLabelCoords_Click(object sender, RoutedEventArgs e)
        {
            ExecuteCommand("ERARQ_COORDS");
        }

        #endregion

        #region Exportación

        private void BtnExportCSV_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                bool exportCoords = chkExpCoords.IsChecked ?? true;
                bool exportSides = chkExpSides.IsChecked ?? true;
                bool exportAreas = chkExpAreas.IsChecked ?? true;
                bool exportAngles = chkExpAngles.IsChecked ?? false;

                // Llamar al comando de exportación
                _ed.Command("_.ERARQ_EXPORT_COORDS", exportCoords ? "Y" : "N");
                
                if (exportAreas)
                    _ed.Command("_.ERARQ_EXPORT_AREAS");

                txtExportStatus.Text = "✓ CSV generado correctamente";
                txtStatus.Text = "Exportación completada";
            }
            catch (Exception ex)
            {
                txtExportStatus.Text = "✗ Error en exportación";
                txtExportStatus.Foreground = System.Windows.Media.Brushes.Red;
                MessageBox.Show($"Error exportando: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        #endregion

        #region Utilidades

        private void ExecuteCommand(string commandName)
        {
            if (_ed == null)
            {
                MessageBox.Show("No hay documento de AutoCAD activo", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            try
            {
                _ed.Command($"_.{commandName}");
                txtStatus.Text = $"Comando {commandName} ejecutado";
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error ejecutando comando: {ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        #endregion
    }
}
