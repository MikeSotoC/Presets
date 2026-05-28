(vl-load-com)

; ============================================================
; POPUPS / INDICES
; ============================================================

(defun erarq:table-type-index (s)
  (cond
    ((= s "Simple")  0)
    ((= s "Rumbos")  1)
    ((= s "Angulos") 2)
    (T               3)
  )
)

(defun erarq:index-table-type (i)
  (cond
    ((= i 0) "Simple")
    ((= i 1) "Rumbos")
    ((= i 2) "Angulos")
    (T       "Mixta")
  )
)

(defun erarq:sheet-index (s)
  (cond
    ((= s "A4") 0)
    ((= s "A3") 1)
    ((= s "A2") 2)
    ((= s "A1") 3)
    ((= s "A0") 4)
    (T         1)
  )
)

(defun erarq:index-sheet (i)
  (cond
    ((= i 0) "A4")
    ((= i 1) "A3")
    ((= i 2) "A2")
    ((= i 3) "A1")
    ((= i 4) "A0")
    (T       "A3")
  )
)

(defun erarq:profile-index (s)
  (cond
    ((= s "Compacto")     0)
    ((= s "Normal")       1)
    ((= s "Presentacion") 2)
    (T                    1)
  )
)

(defun erarq:index-profile (i)
  (cond
    ((= i 0) "Compacto")
    ((= i 1) "Normal")
    ((= i 2) "Presentacion")
    (T       "Normal")
  )
)

(defun erarq:grid-mode-index (s)
  (if (= s "I") 1 0)
)

(defun erarq:index-grid-mode (i)
  (if (= i 1) "I" "E")
)

(defun erarq:fill-table-type-popup ()
  (start_list "pop_table_type")
  (add_list "Simple")
  (add_list "Rumbos")
  (add_list "Angulos")
  (add_list "Mixta")
  (end_list)
)

(defun erarq:fill-sheet-popup ()
  (start_list "pop_sheet")
  (add_list "A4")
  (add_list "A3")
  (add_list "A2")
  (add_list "A1")
  (add_list "A0")
  (end_list)
)

(defun erarq:fill-profile-popup ()
  (start_list "pop_profile")
  (add_list "Compacto")
  (add_list "Normal")
  (add_list "Presentacion")
  (end_list)
)

(defun erarq:fill-grid-mode-popup ()
  (start_list "pop_grid_mode")
  (add_list "Exterior")
  (add_list "Interior")
  (end_list)
)

; ============================================================
; HELPERS
; ============================================================

(defun erarq:safe-itoa (v dflt)
  (if (numberp v)
    (itoa (fix v))
    (itoa dflt)
  )
)

(defun erarq:safe-rtos (v mode prec dflt)
  (if (numberp v)
    (rtos v mode prec)
    (rtos dflt mode prec)
  )
)

(defun erarq:about-text ()
  (strcat
    "ERArq-Urb " *erarq-version*
    "\n\n"
    "Desarrollado por UchiCN"
    "\nTodos los derechos reservados."
    "\n\n"
    "Sistema AutoLISP + DCL para urbanismo,"
    "\nparcelacion, lotificacion y documentacion tecnica."
    "\n\n"
    "Incluye:"
    "\n- datos tecnicos"
    "\n- tablas de coordenadas y areas"
    "\n- division exacta"
    "\n- documentacion automatica de parcela y lotes"
    "\n- grilla manual y automatica"
    "\n- exportacion CSV"
    "\n- control de hoja, perfil y CTB"
  )
)

; ============================================================
; GUARDAR UI
; ============================================================

(defun erarq:save-ui-values ()
  ; ----------------------------------------------------------
  ; datos generales
  ; ----------------------------------------------------------
  (setq *erarq-project*       (get_tile "txt_proyecto"))
  (setq *erarq-parcel-name*   (get_tile "txt_parcela"))
  (setq *erarq-lot-prefix*    (get_tile "txt_prefijo"))
  (setq *erarq-start-number*  (atoi (get_tile "txt_inicio")))
  (setq *erarq-vertex-prefix* (get_tile "txt_vert_pref"))
  (setq *erarq-layer*         (get_tile "txt_capa"))

  ; ----------------------------------------------------------
  ; toggles base
  ; ----------------------------------------------------------
  (setq *erarq-draw-texts*   (= (get_tile "tg_textos") "1"))
  (setq *erarq-draw-tables*  (= (get_tile "tg_tablas") "1"))
  (setq *erarq-create-polys* (= (get_tile "tg_polilineas") "1"))

  ; ----------------------------------------------------------
  ; formato numerico
  ; ----------------------------------------------------------
  (setq *erarq-dec-coord* (atoi (get_tile "txt_dec_coord")))
  (setq *erarq-dec-area*  (atoi (get_tile "txt_dec_area")))
  (setq *erarq-dec-dist*  (atoi (get_tile "txt_dec_dist")))
  (setq *erarq-dec-ang*   (atoi (get_tile "txt_dec_ang")))

  ; ----------------------------------------------------------
  ; hoja / perfil / escala
  ; ----------------------------------------------------------
  (setq *erarq-sheet-size*      (erarq:index-sheet (atoi (get_tile "pop_sheet"))))
  (setq *erarq-print-profile*   (erarq:index-profile (atoi (get_tile "pop_profile"))))
  (setq *erarq-auto-text-scale* (= (get_tile "tg_auto_scale") "1"))

  (setq *erarq-text-height*       (atof (get_tile "txt_altura")))
  (setq *erarq-small-text-height* (atof (get_tile "txt_text_small")))
  (setq *erarq-title-text-height* (atof (get_tile "txt_title_h")))
  (setq *erarq-plot-style*        (get_tile "txt_ctb"))

  ; ----------------------------------------------------------
  ; documentacion general
  ; ----------------------------------------------------------
  (setq *erarq-draw-distances* (= (get_tile "tg_dist") "1"))
  (setq *erarq-draw-angles*    (= (get_tile "tg_ang") "1"))
  (setq *erarq-draw-area*      (= (get_tile "tg_area") "1"))
  (setq *erarq-draw-perim*     (= (get_tile "tg_perim") "1"))

  ; ----------------------------------------------------------
  ; documentacion parcela
  ; ----------------------------------------------------------
  (setq *erarq-doc-vertices-parcel* (= (get_tile "tg_doc_par_vert") "1"))
  (setq *erarq-doc-rumbos-parcel*   (= (get_tile "tg_doc_par_rum") "1"))

  ; ----------------------------------------------------------
  ; documentacion lotes
  ; ----------------------------------------------------------
  (setq *erarq-doc-number-lots*   (= (get_tile "tg_doc_lot_num") "1"))
  (setq *erarq-doc-vertices-lots* (= (get_tile "tg_doc_lot_vert") "1"))
  (setq *erarq-doc-rumbos-lots*   (= (get_tile "tg_doc_lot_rum") "1"))

  ; ----------------------------------------------------------
  ; tablas
  ; ----------------------------------------------------------
  (setq *erarq-table-type*        (erarq:index-table-type (atoi (get_tile "pop_table_type"))))
  (setq *erarq-table-title*       (get_tile "txt_table_title"))
  (setq *erarq-coord-title*       (get_tile "txt_coord_title"))
  (setq *erarq-include-eastnorth* (= (get_tile "tg_eastnorth") "1"))
  (setq *erarq-include-summary*   (= (get_tile "tg_summary") "1"))

  ; ----------------------------------------------------------
  ; grilla
  ; ----------------------------------------------------------
  (setq *erarq-grid-dx*   (atof (get_tile "txt_grid_dx")))
  (setq *erarq-grid-dy*   (atof (get_tile "txt_grid_dy")))
  (setq *erarq-grid-mode* (erarq:index-grid-mode (atoi (get_tile "pop_grid_mode"))))

  ; ----------------------------------------------------------
  ; normalizar
  ; ----------------------------------------------------------
  (vl-catch-all-apply 'erarq:cfg-normalize '())
)

; ============================================================
; DCL
; ============================================================

(defun erarq:get-dcl-file (/ p)
  (if *erarq-app-dir*
    (progn
      (setq p (strcat *erarq-app-dir* "\\erarq_main.dcl"))
      (if (findfile p) p nil)
    )
    nil
  )
)

(defun erarq:run-dialog (/ dcl_file dcl_id result)
  (setq dcl_file (erarq:get-dcl-file))

  (if (null dcl_file)
    (progn
      (alert "No se encontro app\\erarq_main.dcl.")
      nil
    )
    (progn
      (setq dcl_id (load_dialog dcl_file))

      (if (< dcl_id 0)
        (progn
          (alert "No se pudo cargar el archivo DCL.")
          nil
        )
        (progn
          (if (not (new_dialog "erarq_main" dcl_id))
            (progn
              (unload_dialog dcl_id)
              (alert "No fue posible abrir el dialogo ERArq.")
              nil
            )
            (progn
              (erarq:fill-table-type-popup)
              (erarq:fill-sheet-popup)
              (erarq:fill-profile-popup)
              (erarq:fill-grid-mode-popup)

              ; ------------------------------------------------
              ; cargar valores
              ; ------------------------------------------------
              (set_tile "txt_proyecto"  *erarq-project*)
              (set_tile "txt_parcela"   *erarq-parcel-name*)
              (set_tile "txt_prefijo"   *erarq-lot-prefix*)
              (set_tile "txt_inicio"    (erarq:safe-itoa *erarq-start-number* 1))
              (set_tile "txt_vert_pref" *erarq-vertex-prefix*)
              (set_tile "txt_capa"      *erarq-layer*)

              (set_tile "tg_textos"     (if *erarq-draw-texts* "1" "0"))
              (set_tile "tg_tablas"     (if *erarq-draw-tables* "1" "0"))
              (set_tile "tg_polilineas" (if *erarq-create-polys* "1" "0"))

              (set_tile "txt_dec_coord" (erarq:safe-itoa *erarq-dec-coord* 3))
              (set_tile "txt_dec_area"  (erarq:safe-itoa *erarq-dec-area* 2))
              (set_tile "txt_dec_dist"  (erarq:safe-itoa *erarq-dec-dist* 2))
              (set_tile "txt_dec_ang"   (erarq:safe-itoa *erarq-dec-ang* 0))

              (set_tile "pop_sheet"     (itoa (erarq:sheet-index *erarq-sheet-size*)))
              (set_tile "pop_profile"   (itoa (erarq:profile-index *erarq-print-profile*)))
              (set_tile "tg_auto_scale" (if *erarq-auto-text-scale* "1" "0"))

              (set_tile "txt_altura"     (erarq:safe-rtos *erarq-text-height* 2 2 2.50))
              (set_tile "txt_text_small" (erarq:safe-rtos *erarq-small-text-height* 2 2 1.88))
              (set_tile "txt_title_h"    (erarq:safe-rtos *erarq-title-text-height* 2 2 3.00))
              (set_tile "txt_ctb"        *erarq-plot-style*)

              (set_tile "tg_dist"  (if *erarq-draw-distances* "1" "0"))
              (set_tile "tg_ang"   (if *erarq-draw-angles*    "1" "0"))
              (set_tile "tg_area"  (if *erarq-draw-area*      "1" "0"))
              (set_tile "tg_perim" (if *erarq-draw-perim*     "1" "0"))

              (set_tile "tg_doc_par_vert" (if *erarq-doc-vertices-parcel* "1" "0"))
              (set_tile "tg_doc_par_rum"  (if *erarq-doc-rumbos-parcel*   "1" "0"))

              (set_tile "tg_doc_lot_num"  (if *erarq-doc-number-lots*   "1" "0"))
              (set_tile "tg_doc_lot_vert" (if *erarq-doc-vertices-lots* "1" "0"))
              (set_tile "tg_doc_lot_rum"  (if *erarq-doc-rumbos-lots*   "1" "0"))

              (set_tile "pop_table_type"  (itoa (erarq:table-type-index *erarq-table-type*)))
              (set_tile "txt_table_title" *erarq-table-title*)
              (set_tile "txt_coord_title" *erarq-coord-title*)
              (set_tile "tg_eastnorth"    (if *erarq-include-eastnorth* "1" "0"))
              (set_tile "tg_summary"      (if *erarq-include-summary*   "1" "0"))

              (set_tile "txt_grid_dx"    (erarq:safe-rtos *erarq-grid-dx* 2 2 100.00))
              (set_tile "txt_grid_dy"    (erarq:safe-rtos *erarq-grid-dy* 2 2 100.00))
              (set_tile "pop_grid_mode"  (itoa (erarq:grid-mode-index *erarq-grid-mode*)))

              ; ------------------------------------------------
              ; botones
              ; ------------------------------------------------
              (action_tile "btn_datos"         "(progn (erarq:save-ui-values) (done_dialog 101))")
              (action_tile "btn_coords"        "(progn (erarq:save-ui-values) (done_dialog 102))")
              (action_tile "btn_vertices"      "(progn (erarq:save-ui-values) (done_dialog 103))")
              (action_tile "btn_numerar"       "(progn (erarq:save-ui-values) (done_dialog 104))")
              (action_tile "btn_areas"         "(progn (erarq:save-ui-values) (done_dialog 105))")
              (action_tile "btn_dividir"       "(progn (erarq:save-ui-values) (done_dialog 106))")
              (action_tile "btn_export_coords" "(progn (erarq:save-ui-values) (done_dialog 107))")
              (action_tile "btn_export_areas"  "(progn (erarq:save-ui-values) (done_dialog 108))")
              (action_tile "btn_const"         "(progn (erarq:save-ui-values) (done_dialog 109))")
              (action_tile "btn_grid"          "(progn (erarq:save-ui-values) (done_dialog 110))")
              (action_tile "btn_grid_auto"     "(progn (erarq:save-ui-values) (done_dialog 111))")
              (action_tile "btn_doc_par"       "(progn (erarq:save-ui-values) (done_dialog 112))")
              (action_tile "btn_doc_lotes"     "(progn (erarq:save-ui-values) (done_dialog 113))")
              (action_tile "btn_about"         "(alert (erarq:about-text))")
              (action_tile "accept"            "(progn (erarq:save-ui-values) (done_dialog 1))")

              (setq result (start_dialog))
              (unload_dialog dcl_id)
              result
            )
          )
        )
      )
    )
  )
)

; ============================================================
; DISPATCH
; ============================================================

(defun erarq:dispatch (code)
  (cond
    ((= code 101) (erarq:parcel-summary-command))
    ((= code 102) (erarq:coords-table-command))
    ((= code 103) (erarq:vertices-command))
    ((= code 104) (erarq:number-lots-command))
    ((= code 105) (erarq:areas-table-command))
    ((= code 106) (erarq:division-command))
    ((= code 107) (erarq:export-coords-command))
    ((= code 108) (erarq:export-areas-command))
    ((= code 109) (erarq:table-construction))
    ((= code 110) (erarq:grid-command))
    ((= code 111) (if (erarq:fn-exists-p 'erarq:grid-auto-command) (erarq:grid-auto-command)))
    ((= code 112) (erarq:parcel-doc-command))
    ((= code 113) (erarq:lots-doc-command))
  )
)

(princ)