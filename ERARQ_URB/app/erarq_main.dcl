erarq_main : dialog {
    label = "ERArq-Urb v1.4";
    spacer;

    : row {
        : boxed_column {
            label = "Parcela";
            width = 26;

            : button { key = "btn_datos";    label = "Datos tecnicos";        width = 22; fixed_width = true; }
            : button { key = "btn_coords";   label = "Tabla coordenadas";     width = 22; fixed_width = true; }
            : button { key = "btn_vertices"; label = "Etiquetar vertices";    width = 22; fixed_width = true; }
            : button { key = "btn_const";    label = "Tabla construccion";    width = 22; fixed_width = true; }
            : button { key = "btn_doc_par";  label = "Documentar parcela";    width = 22; fixed_width = true; }
        }

        : boxed_column {
            label = "Lotes";
            width = 26;

            : button { key = "btn_numerar";   label = "Numerar lotes";        width = 22; fixed_width = true; }
            : button { key = "btn_areas";     label = "Tabla areas";          width = 22; fixed_width = true; }
            : button { key = "btn_dividir";   label = "Division exacta";      width = 22; fixed_width = true; }
            : button { key = "btn_doc_lotes"; label = "Documentar lotes";     width = 22; fixed_width = true; }
        }

        : boxed_column {
            label = "Salida";
            width = 26;

            : button { key = "btn_grid";          label = "Dibujar grilla";      width = 22; fixed_width = true; }
            : button { key = "btn_grid_auto";     label = "Grilla automatica";   width = 22; fixed_width = true; }
            : button { key = "btn_export_coords"; label = "Exportar coord. CSV"; width = 22; fixed_width = true; }
            : button { key = "btn_export_areas";  label = "Exportar areas CSV";  width = 22; fixed_width = true; }
        }
    }

    spacer;

    : boxed_column {
        label = "Datos generales";

        : row {
            : edit_box { key = "txt_proyecto";  label = "Proyecto:";       edit_width = 24; value = "Proyecto Urbano"; }
            : edit_box { key = "txt_parcela";   label = "Parcela:";        edit_width = 16; value = "Parcela 01"; }
        }

        : row {
            : edit_box { key = "txt_prefijo";   label = "Prefijo lote:";   edit_width = 8; value = "L"; }
            : edit_box { key = "txt_inicio";    label = "No inicial:";     edit_width = 6; value = "1"; }
            : edit_box { key = "txt_vert_pref"; label = "Prefijo vertice:";edit_width = 8; value = "V"; }
            : edit_box { key = "txt_capa";      label = "Capa base:";      edit_width = 12; value = "ERARQ"; }
        }

        : row {
            : toggle { key = "tg_textos";     label = "Textos";      value = "1"; }
            : toggle { key = "tg_tablas";     label = "Tablas";      value = "1"; }
            : toggle { key = "tg_polilineas"; label = "Polilineas";  value = "1"; }
        }
    }

    spacer;

    : boxed_column {
        label = "Formato y presentacion";

        : row {
            : edit_box   { key = "txt_dec_coord"; label = "Dec. coord:"; edit_width = 6; value = "3"; }
            : edit_box   { key = "txt_dec_area";  label = "Dec. area:";  edit_width = 6; value = "2"; }
            : edit_box   { key = "txt_dec_dist";  label = "Dec. dist:";  edit_width = 6; value = "2"; }
            : edit_box   { key = "txt_dec_ang";   label = "Dec. ang:";   edit_width = 6; value = "0"; }
        }

        : row {
            : popup_list { key = "pop_sheet";      label = "Hoja:";   width = 12; }
            : popup_list { key = "pop_profile";    label = "Perfil:"; width = 14; }
            : toggle     { key = "tg_auto_scale";  label = "Escala automatica"; value = "1"; }
        }

        : row {
            : edit_box { key = "txt_altura";      label = "Texto principal:";  edit_width = 8; value = "2.50"; }
            : edit_box { key = "txt_text_small";  label = "Texto secundario:"; edit_width = 8; value = "1.88"; }
            : edit_box { key = "txt_title_h";     label = "Titulos:";          edit_width = 8; value = "3.00"; }
            : edit_box { key = "txt_ctb";         label = "CTB:";              edit_width = 16; value = "ERARQ_PRESENTACION.ctb"; }
        }
    }

    spacer;

    : row {
        : boxed_column {
            label = "Documentacion de parcela";
            width = 38;

            : row {
                : toggle { key = "tg_doc_par_vert"; label = "Vertices";   value = "1"; }
                : toggle { key = "tg_dist";         label = "Distancias"; value = "1"; }
                : toggle { key = "tg_ang";          label = "Angulos";    value = "1"; }
            }

            : row {
                : toggle { key = "tg_doc_par_rum"; label = "Rumbos";    value = "1"; }
                : toggle { key = "tg_area";        label = "Area";      value = "1"; }
                : toggle { key = "tg_perim";       label = "Perimetro"; value = "1"; }
            }
        }

        : boxed_column {
            label = "Documentacion de lotes";
            width = 38;

            : row {
                : toggle { key = "tg_doc_lot_num";  label = "Numerar";  value = "1"; }
                : toggle { key = "tg_doc_lot_vert"; label = "Vertices"; value = "1"; }
                : toggle { key = "tg_doc_lot_rum";  label = "Rumbos";   value = "1"; }
            }

            : text { label = "Distancias, angulos, area y perimetro usan los toggles generales."; }
        }
    }

    spacer;

    : boxed_column {
        label = "Tablas y grilla";

        : row {
            : popup_list { key = "pop_table_type"; label = "Tabla:";  width = 14; }
            : edit_box   { key = "txt_table_title"; label = "Titulo:"; edit_width = 18; value = "DATOS TECNICOS"; }
            : edit_box   { key = "txt_coord_title"; label = "Coord.:"; edit_width = 10; value = "WGS 84"; }
        }

        : row {
            : toggle     { key = "tg_eastnorth";  label = "Este/Norte"; value = "1"; }
            : toggle     { key = "tg_summary";    label = "Resumen";    value = "1"; }
        }

        : row {
            : edit_box   { key = "txt_grid_dx";   label = "Paso X:";     edit_width = 8; value = "100.00"; }
            : edit_box   { key = "txt_grid_dy";   label = "Paso Y:";     edit_width = 8; value = "100.00"; }
            : popup_list { key = "pop_grid_mode"; label = "Ubicacion:";  width = 12; }
        }

        : text {
            label = "La grilla automatica se ajusta a multiplos limpios del paso configurado.";
        }
    }

    spacer;

    : row {
        alignment = centered;
        : button { key = "btn_about"; label = "Acerca de..."; width = 14; fixed_width = true; }
        : button { key = "accept";    label = "Cerrar"; is_default = true; width = 14; fixed_width = true; }
    }

    spacer;

    : text {
        label = "ERArq-Urb v1.4 | Dev UchiCN | Urbanismo y parcelacion automatizada";
        alignment = centered;
    }

    spacer;
}