# ERARQ-Urb para AutoCAD (.NET/C#)

## Descripción

Portaje a C# del sistema ERARQ-Urb original escrito en AutoLISP. Este sistema está diseñado para urbanismo y parcelación en AutoCAD, proporcionando herramientas para:

- Generación de tablas técnicas de coordenadas
- Etiquetado de vértices y numeración de lotes
- Tablas de áreas de lotes
- Exportación de datos
- División de parcelas
- Grillas de referencia

## Requisitos

- **AutoCAD** 2015 o superior (recomendado 2020+)
- **.NET Framework** 4.7.2 o .NET 6/7/8 (según versión de AutoCAD)
- **AutoCAD .NET API** (incluida con la instalación de AutoCAD)

## Referencias Requeridas

Para compilar este proyecto, necesita agregar las siguientes referencias de AutoCAD:

```
- Autodesk.AutoCAD.ApplicationServices.dll
- Autodesk.AutoCAD.DatabaseServices.dll
- Autodesk.AutoCAD.Geometry.dll
- Autodesk.AutoCAD.Runtime.dll
- Autodesk.AutoCAD.EditorInput.dll
```

Estas DLLs se encuentran típicamente en:
- `C:\Program Files\Autodesk\AutoCAD 20XX\`

## Estructura del Proyecto

### Archivos Principales

1. **ERARQBase.cs** (612 líneas) - Configuración y utilidades base
   - `ERARQConfig`: Clase estática para configuración global
   - `ERARQUtils`: Funciones geométricas y de dibujo
   - `ERARQCommands`: Comandos básicos de inicialización

2. **ERARQLayers.cs** (266 líneas) - Gestión completa de capas
   - Nombres de capas base y por lote
   - Colores en escala de grises para presentación
   - `EnsureBaseLayers()`: Crea todas las capas del sistema
   - `EnsureLotLayers(n)`: Crea capas para un lote específico
   - Comandos: `ERARQ_LAYERS`, `ERARQ_LOTE_LAYERS`

3. **ERARQDims.cs** (524 líneas) - Dimensionamiento y documentación
   - Utilidades vectoriales y de ángulos
   - `DrawDistancesOnObject()`: Dibuja distancias en polilíneas
   - `DrawRumbosOnObject()`: Dibuja rumbos (N/S E/W)
   - `DrawAnglesOnObject()`: Dibuja ángulos internos con arcos
   - `DrawAreaPerimOnObject()`: Dibuja área y perímetro
   - Comandos: `ERARQ_PARCELA`, `ERARQ_LOTES_DOC`

4. **ERARQTables.cs** (500 líneas) - Generación de tablas técnicas
   - `ERARQTableBuilder`: Constructor de tablas tipo AutoCAD
   - `ERARQTableCommands`: Comandos para 4 tipos de tablas
   - Tablas de coordenadas, rumbos, ángulos y mixtas
   - Bloques de resumen de área/perímetro

3. **ERARQDivision.cs** (643 líneas) - División de parcelas
   - `DivisionUtils`: Utilidades geométricas para división
   - `ERARQDivisionCommands`: Comandos de división
   - Algoritmo de bisección para áreas iguales
   - Creación automática de lotes con capas individuales

4. **ERARQGrid.cs** (535 líneas) - Grillas de referencia
   - `GridUtils`: Utilidades para grilla
   - `ERARQGridCommands`: Comandos de grilla manual y automática
   - Capas jerárquicas (minor, major, master)
   - Etiquetado automático de coordenadas

5. **ERARQLabels.cs** (283 líneas) - Etiquetado y numeración
   - `ERARQLabelsCommands`: Comandos de etiquetado
   - Numeración de lotes en orden de selección
   - Etiquetado de vértices de parcela y por lote
   - Cálculo y muestra de áreas

6. **ERARQExport.cs** (203 líneas) - Exportación a CSV
   - `ERARQExportCommands`: Comandos de exportación
   - Exportación de coordenadas de parcela
   - Exportación de áreas de múltiples lotes
   - Ordenamiento por posición grid

## Comandos Disponibles

### Comandos Base
| Comando | Descripción |
|---------|-------------|
| `ERARQ` | Carga el sistema y muestra mensaje de bienvenida |
| `ERARQ_INIT` | Inicializa la configuración con valores por defecto |
| `ERARQ_DATOS` | Genera tabla técnica de parcela seleccionada |

### Tablas Técnicas
| Comando | Descripción |
|---------|-------------|
| `ERARQ_TABLE_SIMPLE` | Tabla simple de coordenadas X,Y |
| `ERARQ_TABLE_RUMBOS` | Tabla con rumbos y distancias |
| `ERARQ_TABLE_ANGULOS` | Tabla con ángulos internos |
| `ERARQ_TABLE_MIXTA` | Tabla mixta completa (coordenadas + rumbos) |

### División de Polígonos
| Comando | Descripción |
|---------|-------------|
| `ERARQ_DIVIDE_EQUAL` | Divide polígono en N lotes de igual área |
| `ERARQ_DIVIDE_AREA` | Divide polígono por área objetivo por lote |

### Grilla
| Comando | Descripción |
|---------|-------------|
| `ERARQ_GRID` | Crea grilla manual entre dos puntos |
| `ERARQ_GRID_AUTO` | Crea grilla automática desde selección |

### Etiquetado
| Comando | Descripción |
|---------|-------------|
| `ERARQ_VERTICES` | Etiqueta vértices de parcela |
| `ERARQ_LOTES` | Numera lotes seleccionados en orden |
| `ERARQ_LOTES_VERTICES` | Etiqueta vértices de cada lote |
| `ERARQ_AREAS` | Muestra áreas de lotes seleccionados |
| `ERARQ_COORDS` | Muestra coordenadas de vértices |

### Exportación
| Comando | Descripción |
|---------|-------------|
| `ERARQ_EXPORT_COORDS` | Exporta coordenadas a CSV |
| `ERARQ_EXPORT_AREAS` | Exporta áreas de lotes a CSV |

## Instalación

### Opción 1: Compilación Manual

1. Cree un nuevo proyecto Class Library en Visual Studio
2. Agregue las referencias de AutoCAD mencionadas arriba
3. Copie los archivos `.cs` al proyecto
4. Compile el proyecto
5. Copie el DLL resultante a una carpeta accesible

### Opción 2: Usando dotnet CLI

```bash
dotnet new classlib -n ERARQ_Urb -f net6.0
cd ERARQ_Urb
# Agregar referencias de AutoCAD manualmente o vía NuGet si están disponibles
# Copiar archivos .cs
dotnet build
```

### Cargar en AutoCAD

1. En AutoCAD, ejecute el comando `NETLOAD`
2. Navegue al archivo `ERARQ_Urb.dll` compilado
3. El sistema cargará los comandos automáticamente

## Configuración

La configuración se maneja mediante la clase `ERARQConfig`:

```csharp
// Ejemplo de personalización
ERARQConfig.Project = "Mi Proyecto Urbano";
ERARQConfig.ParcelName = "Parcela A-1";
ERARQConfig.LotPrefix = "M";
ERARQConfig.SheetSize = "A2";
ERARQConfig.TableType = "Mixta"; // Simple, Rumbos, Angulos, Mixta
```

## Uso Básico

1. **Inicializar**: Ejecute `ERARQ_INIT` en la línea de comandos
2. **Seleccionar parcela**: Dibuje o seleccione una LWPOLYLINE cerrada
3. **Generar tabla**: Ejecute `ERARQ_DATOS` y siga las instrucciones

## Desarrollo Futuro

Módulos pendientes de portar:

- [ ] Gestión completa de capas (`erarq_layers.lsp`)
- [ ] Etiquetado de vértices (`erarq_labels.lsp`)
- [ ] Numeración de lotes (`erarq_labels.lsp`)
- [ ] División de parcelas (`erarq_division.lsp`)
- [ ] Exportación CSV (`erarq_export.lsp`)
- [ ] Grillas (`erarq_grid.lsp`)
- [ ] Interfaz DCL (`erarq_main.dcl` → WPF/Windows Forms)
- [ ] Acotado (`erarq_dims.lsp`)
- [ ] UI moderna (`erarq_ui.lsp`)

## Notas Importantes

1. **Gestión de memoria**: Los objetos de AutoCAD deben ser disposed correctamente
2. **Transacciones**: Todas las operaciones de dibujo usan transacciones
3. **Capas**: Las capas se crean automáticamente si no existen
4. **Unidades**: El sistema asume unidades métricas (metros)

## Licencia

Este código es un portaje del sistema ERARQ-Urb original. Consulte la licencia del proyecto original.

## Soporte

Para issues relacionados con el portaje a C#, revisar:
- Compatibilidad de versiones de AutoCAD
- Referencias correctas del .NET SDK
- Permisos de carga de aplicaciones .NET en AutoCAD (`NETLOAD`)

---

**Versión**: 1.0 (Portaje inicial)  
**Original**: ERARQ-Urb v1.4 (AutoLISP)  
**Autor del portaje**: Asistente de código IA
