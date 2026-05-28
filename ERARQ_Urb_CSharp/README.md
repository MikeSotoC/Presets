# ERARQ-Urb para AutoCAD (.NET/C#)

## Descripcion

Portaje completo a C# del sistema ERARQ-Urb original escrito en AutoLISP. Este sistema esta disenado para urbanismo y parcelacion en AutoCAD, proporcionando herramientas para:

- Generacion de tablas tecnicas de coordenadas
- Etiquetado de vertices y numeracion de lotes
- Tablas de areas de lotes
- Exportacion de datos
- Division de parcelas
- Grillas de referencia
- Interfaz grafica moderna (WPF)

## Estado del Proyecto: COMPLETADO

Todos los modulos del sistema ERARQ-Urb original han sido portados exitosamente a C#:

| Modulo Original (.lsp/.dcl) | Archivo C# | Estado | Lineas |
|-----------------------------|------------|--------|--------|
| `erarq_base.lsp` | ERARQBase.cs | Completado | 612 |
| `erarq_layers.lsp` | ERARQLayers.cs | Completado | 266 |
| `erarq_dims.lsp` | ERARQDims.cs | Completado | 524 |
| `erarq_tables.lsp` | ERARQTables.cs | Completado | 500 |
| `erarq_division.lsp` | ERARQDivision.cs | Completado | 643 |
| `erarq_grid.lsp` | ERARQGrid.cs | Completado | 535 |
| `erarq_labels.lsp` | ERARQLabels.cs | Completado | 283 |
| `erarq_export.lsp` | ERARQExport.cs | Completado | 203 |
| `erarq_ui.lsp` | ERARQUICommands.cs | Completado | 74 |
| `erarq_main.dcl` | ERARQWindow.xaml + .cs | Completado (WPF) | 477 |
| **TOTAL** | **11 archivos** | **100%** | **4,117** |

## Requisitos

- **AutoCAD** 2015 o superior (recomendado 2020+)
- **.NET Framework** 4.7.2 o .NET 6/7/8 (segun version de AutoCAD)
- **AutoCAD .NET API** (incluida con la instalacion de AutoCAD)
- **Windows** (requerido para WPF)

## Referencias Requeridas

Para compilar este proyecto, necesita agregar las siguientes referencias de AutoCAD:

```
- Autodesk.AutoCAD.ApplicationServices.dll
- Autodesk.AutoCAD.DatabaseServices.dll
- Autodesk.AutoCAD.Geometry.dll
- Autodesk.AutoCAD.Runtime.dll
- Autodesk.AutoCAD.EditorInput.dll
- PresentationCore.dll
- PresentationFramework.dll
- WindowsBase.dll
- System.Xaml.dll
```

Estas DLLs se encuentran tipicamente en:
- `C:\Program Files\Autodesk\AutoCAD 20XX\`
- `C:\Windows\Microsoft.NET\Framework\v4.0.30319\` (para WPF)

## Estructura del Proyecto

### Archivos Principales

1. **ERARQBase.cs** (612 lineas) - Configuracion y utilidades base
   - `ERARQConfig`: Clase estatica para configuracion global
   - `ERARQUtils`: Funciones geometricas y de dibujo
   - `ERARQCommands`: Comandos basicos de inicializacion

2. **ERARQLayers.cs** (266 lineas) - Gestion completa de capas
   - Nombres de capas base y por lote
   - Colores en escala de grises para presentacion
   - `EnsureBaseLayers()`: Crea todas las capas del sistema
   - `EnsureLotLayers(n)`: Crea capas para un lote especifico
   - Comandos: `ERARQ_LAYERS`, `ERARQ_LOTE_LAYERS`

3. **ERARQDims.cs** (524 lineas) - Dimensionamiento y documentacion
   - Utilidades vectoriales y de angulos
   - `DrawDistancesOnObject()`: Dibuja distancias en polilineas
   - `DrawRumbosOnObject()`: Dibuja rumbos (N/S E/W)
   - `DrawAnglesOnObject()`: Dibuja angulos internos con arcos
   - `DrawAreaPerimOnObject()`: Dibuja area y perimetro
   - Comandos: `ERARQ_PARCELA`, `ERARQ_LOTES_DOC`

4. **ERARQTables.cs** (500 lineas) - Generacion de tablas tecnicas
   - `ERARQTableBuilder`: Constructor de tablas tipo AutoCAD
   - `ERARQTableCommands`: Comandos para 4 tipos de tablas
   - Tablas de coordenadas, rumbos, angulos y mixtas
   - Bloques de resumen de area/perimetro

5. **ERARQDivision.cs** (643 lineas) - Division de parcelas
   - `DivisionUtils`: Utilidades geometricas para division
   - `ERARQDivisionCommands`: Comandos de division
   - Algoritmo de biseccion para areas iguales
   - Creacion automatica de lotes con capas individuales

6. **ERARQGrid.cs** (535 lineas) - Grillas de referencia
   - `GridUtils`: Utilidades para grilla
   - `ERARQGridCommands`: Comandos de grilla manual y automatica
   - Capas jerarquicas (minor, major, master)
   - Etiquetado automatico de coordenadas

7. **ERARQLabels.cs** (283 lineas) - Etiquetado y numeracion
   - `ERARQLabelsCommands`: Comandos de etiquetado
   - Numeracion de lotes en orden de seleccion
   - Etiquetado de vertices de parcela y por lote
   - Calculo y muestra de areas

8. **ERARQExport.cs** (203 lineas) - Exportacion a CSV
   - `ERARQExportCommands`: Comandos de exportacion
   - Exportacion de coordenadas de parcela
   - Exportacion de areas de multiples lotes
   - Ordenamiento por posicion grid

9. **ERARQUICommands.cs** (74 lineas) - Comandos de interfaz
   - `ERARQUICmds`: Comandos para mostrar la interfaz WPF
   - Integracion con ERARQWindow

10. **ERARQWindow.xaml** (211 lineas) - Interfaz WPF
    - Ventana principal con 5 pestanas
    - Configuracion de proyecto y parcela
    - Selector de tipo de tabla tecnica
    - Opciones de exportacion
    - Botones de accion rapida

11. **ERARQWindow.xaml.cs** (266 lineas) - Logica de interfaz
    - Manejo de eventos de la UI
    - Validacion de datos
    - Ejecucion de comandos desde la interfaz

## Comandos Disponibles (22 comandos)

### Comandos Base
| Comando | Descripcion |
|---------|-------------|
| `ERARQ` | Carga el sistema y muestra mensaje de bienvenida |
| `ERARQ_INIT` | Inicializa la configuracion con valores por defecto |
| `ERARQ_DATOS` | Genera tabla tecnica de parcela seleccionada |
| `ERARQ_UI` | Muestra la interfaz grafica WPF |

### Tablas Tecnicas
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_TABLE_SIMPLE` | Tabla simple de coordenadas X,Y |
| `ERARQ_TABLE_RUMBOS` | Tabla con rumbos y distancias |
| `ERARQ_TABLE_ANGULOS` | Tabla con angulos internos |
| `ERARQ_TABLE_MIXTA` | Tabla mixta completa (coordenadas + rumbos) |

### Division de Poligonos
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_DIVIDE_EQUAL` | Divide poligono en N lotes de igual area |
| `ERARQ_DIVIDE_AREA` | Divide poligono por area objetivo por lote |

### Grilla
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_GRID` | Crea grilla manual entre dos puntos |
| `ERARQ_GRID_AUTO` | Crea grilla automatica desde seleccion |

### Etiquetado
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_VERTICES` | Etiqueta vertices de parcela |
| `ERARQ_LOTES` | Numera lotes seleccionados en orden |
| `ERARQ_LOTES_VERTICES` | Etiqueta vertices de cada lote |
| `ERARQ_AREAS` | Muestra areas de lotes seleccionados |
| `ERARQ_COORDS` | Muestra coordenadas de vertices |

### Exportacion
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_EXPORT_COORDS` | Exporta coordenadas a CSV |
| `ERARQ_EXPORT_AREAS` | Exporta areas de lotes a CSV |

### Capas
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_LAYERS` | Crea todas las capas base del sistema |
| `ERARQ_LOTE_LAYERS` | Crea capas para un lote especifico |

### Documentacion
| Comando | Descripcion |
|---------|-------------|
| `ERARQ_PARCELA` | Documenta parcela con distancias y rumbos |
| `ERARQ_LOTES_DOC` | Documenta todos los lotes seleccionados |

## Instalacion

### Opcion 1: Compilacion Manual

1. Cree un nuevo proyecto Class Library en Visual Studio
2. Agregue las referencias de AutoCAD y WPF mencionadas arriba
3. Copie los archivos `.cs` y `.xaml` al proyecto
4. Para archivos XAML, asegurese de establecer:
   - Build Action: `Page`
   - Custom Tool: `MSBuild:Compile`
5. Compile el proyecto
6. Copie el DLL resultante a una carpeta accesible

### Opcion 2: Usando dotnet CLI

```bash
dotnet new classlib -n ERARQ_Urb -f net6.0-windows
cd ERARQ_Urb

# Agregar referencias de AutoCAD manualmente
# Editar ERARQ_Urb.csproj para incluir referencias WPF

# Copiar archivos .cs y .xaml
dotnet build
```

### Proyecto .csproj sugerido

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net6.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  
  <ItemGroup>
    <Reference Include="Autodesk.AutoCAD.ApplicationServices">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2023\Autodesk.AutoCAD.ApplicationServices.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Autodesk.AutoCAD.DatabaseServices">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2023\Autodesk.AutoCAD.DatabaseServices.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Autodesk.AutoCAD.Geometry">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2023\Autodesk.AutoCAD.Geometry.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Autodesk.AutoCAD.Runtime">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2023\Autodesk.AutoCAD.Runtime.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="Autodesk.AutoCAD.EditorInput">
      <HintPath>C:\Program Files\Autodesk\AutoCAD 2023\Autodesk.AutoCAD.EditorInput.dll</HintPath>
      <Private>false</Private>
    </Reference>
  </ItemGroup>
</Project>
```

### Cargar en AutoCAD

1. En AutoCAD, ejecute el comando `NETLOAD`
2. Navegue al archivo `ERARQ_Urb.dll` compilado
3. El sistema cargara los comandos automaticamente
4. Ejecute `ERARQ_UI` para mostrar la interfaz grafica

## Configuracion

La configuracion se maneja mediante la clase `ERARQConfig`:

```csharp
// Ejemplo de personalizacion
ERARQConfig.Project = "Mi Proyecto Urbano";
ERARQConfig.ParcelName = "Parcela A-1";
ERARQConfig.LotPrefix = "M";
ERARQConfig.SheetSize = "A2";
ERARQConfig.TableType = "Mixta"; // Simple, Rumbos, Angulos, Mixta
```

## Uso Basico

### Desde la linea de comandos:

1. **Inicializar**: Ejecute `ERARQ_INIT` en la linea de comandos
2. **Seleccionar parcela**: Dibuje o seleccione una LWPOLYLINE cerrada
3. **Generar tabla**: Ejecute `ERARQ_DATOS` y siga las instrucciones

### Desde la interfaz grafica:

1. **Abrir UI**: Ejecute `ERARQ_UI` para mostrar la ventana WPF
2. **Configurar**: Complete los campos de proyecto y parcela
3. **Seleccionar opciones**: Elija tipo de tabla, formato de exportacion, etc.
4. **Ejecutar**: Use los botones de accion rapida para cada funcion

## Caracteristicas de la Interfaz WPF

La interfaz grafica incluye:

- **Pestana Principal**: Configuracion de proyecto y parcela
- **Pestana Tablas**: Seleccion de tipo de tabla tecnica
- **Pestana Division**: Herramientas de division de parcelas
- **Pestana Grilla**: Configuracion de grillas de referencia
- **Pestana Exportacion**: Opciones de exportacion a CSV

Ventajas sobre el DCL original:
- Diseño moderno y responsivo
- Validacion de datos en tiempo real
- Mejores controles de entrada
- Integracion nativa con Windows
- Soporte para temas y personalizaciones

## Notas Importantes

1. **Gestion de memoria**: Los objetos de AutoCAD deben ser disposed correctamente
2. **Transacciones**: Todas las operaciones de dibujo usan transacciones
3. **Capas**: Las capas se crean automaticamente si no existen
4. **Unidades**: El sistema asume unidades metricas (metros)
5. **WPF**: Requiere ejecutarse en Windows con soporte para WPF
6. **Thread affinity**: Las operaciones de AutoCAD deben ejecutarse en el thread principal

## Comparativa: DCL vs WPF

| Caracteristica | DCL (AutoLISP) | WPF (C#) |
|---------------|----------------|----------|
| Plataforma | Multi-plataforma | Windows |
| Diseño | Basico, limitado | Moderno, flexible |
| Controles | Limitados | Amplia gama |
| Estilos | Muy basicos | CSS-like (XAML) |
| Validacion | Manual | Data binding |
| Eventos | Basicos | Complejos |
| Integracion | Limitada | Nativa .NET |

## Solucion de Problemas

### Error al cargar DLL
- Verifique que las referencias de AutoCAD coincidan con su version
- Asegurese de usar NETLOAD (no APPLOAD)

### Error con WPF
- Verifique que target framework sea `net6.0-windows` o similar
- Confirme que `<UseWPF>true</UseWPF>` este en el .csproj
- Los archivos .xaml deben tener Build Action: Page

### Comandos no disponibles
- Verifique que NETLOAD se ejecuto correctamente
- Revise la consola de AutoCAD para mensajes de error
- Confirme que la aplicacion .NET tiene permisos de carga

## Desarrollo Futuro

El portaje esta completo. Posibles mejoras:
- [ ] Agregar tests unitarios
- [ ] Implementar async/await para operaciones largas
- [ ] Agregar soporte para Undo/Redo mejorado
- [ ] Crear installer para distribucion
- [ ] Documentacion en video

## Licencia

Este codigo es un portaje del sistema ERARQ-Urb original. Consulte la licencia del proyecto original.

## Soporte

Para issues relacionados con el portaje a C#, revisar:
- Compatibilidad de versiones de AutoCAD
- Referencias correctas del .NET SDK
- Permisos de carga de aplicaciones .NET en AutoCAD (`NETLOAD`)
- Configuracion correcta de WPF en el proyecto

---

**Version**: 1.0 (Portaje completo)  
**Original**: ERARQ-Urb v1.4 (AutoLISP)  
**Estado**: Todos los modulos portados incluyendo interfaz WPF  
**Total lineas de codigo**: 4,117 lineas
