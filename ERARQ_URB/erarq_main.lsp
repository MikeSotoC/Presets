(vl-load-com)

; ============================================================
; UTILIDADES BASE
; ============================================================

(defun erarq:fn-exists-p (sym / res)
  (if (and sym (= (type sym) 'SYM))
    (progn
      (setq res
        (vl-catch-all-apply
          sym
          '()
        )
      )
      (not
        (and
          (vl-catch-all-error-p res)
          (wcmatch
            (strcase (vl-catch-all-error-message res))
            "*NO FUNCTION DEFINITION*"
          )
        )
      )
    )
    nil
  )
)

(defun erarq:file-exists-p (path / f)
  (if (and path (= (type path) 'STR) (/= path ""))
    (progn
      (setq f (open path "r"))
      (if f
        (progn
          (close f)
          T
        )
        nil
      )
    )
    nil
  )
)

(defun erarq:path-join (a b)
  (if (and a b (= (type a) 'STR) (= (type b) 'STR))
    (strcat a "\\" b)
    nil
  )
)

(defun erarq:str-list-join (lst sep / out)
  (if lst
    (progn
      (setq out (car lst))
      (foreach x (cdr lst)
        (setq out (strcat out sep x))
      )
      out
    )
    ""
  )
)

; ============================================================
; APP DIR
; ============================================================

(defun erarq:get-saved-app-dir (/ p cfg)
  (setq p (getenv "ERARQ_APP_DIR"))
  (if (and p (= (type p) 'STR) (/= p ""))
    (progn
      (setq cfg (erarq:path-join p "erarq_config.lsp"))
      (if (erarq:file-exists-p cfg)
        p
        nil
      )
    )
    nil
  )
)

(defun erarq:pick-app-dir (/ file)
  (setq file (getfiled "Seleccione app\\erarq_config.lsp" "" "lsp" 0))
  (if file
    (vl-filename-directory file)
    nil
  )
)

(defun erarq:ensure-app-dir (/ p)
  (setq p (erarq:get-saved-app-dir))
  (if (null p)
    (setq p (erarq:pick-app-dir))
  )
  (if p
    (setenv "ERARQ_APP_DIR" p)
  )
  p
)

(setq *erarq-app-dir* (erarq:ensure-app-dir))

; ============================================================
; MODULOS
; ============================================================

(setq *erarq-modules*
  '(
    "erarq_config.lsp"
    "erarq_layers.lsp"
    "erarq_utils.lsp"
    "erarq_tables.lsp"
    "erarq_core.lsp"
    "erarq_labels.lsp"
    "erarq_dims.lsp"
    "erarq_export.lsp"
    "erarq_division.lsp"
    "erarq_grid.lsp"
    "erarq_ui.lsp"
  )
)

(setq *erarq-critical-functions*
  '(
    erarq:ensure-base-layers
    erarq:run-dialog
    erarq:dispatch
    erarq:table-construction
    erarq:grid-command
    erarq:grid-auto-command
  )
)

; ============================================================
; RESOLVER / CARGAR
; ============================================================

(defun erarq:resolve-app-file (fname / full)
  (if *erarq-app-dir*
    (progn
      (setq full (erarq:path-join *erarq-app-dir* fname))
      (if (erarq:file-exists-p full)
        full
        nil
      )
    )
    nil
  )
)

(defun erarq:load-module-result (fname / full res)
  (setq full (erarq:resolve-app-file fname))
  (cond
    ((null full)
      (list "missing" fname nil)
    )
    (T
      (setq res (vl-catch-all-apply 'load (list full)))
      (if (vl-catch-all-error-p res)
        (list "error" fname (vl-catch-all-error-message res))
        (list "ok" fname full)
      )
    )
  )
)

(defun erarq:collect-load-results (mods / results item)
  (setq results '())
  (foreach item mods
    (setq results (append results (list (erarq:load-module-result item))))
  )
  results
)

(defun erarq:results-by-status (results status / out r)
  (setq out '())
  (foreach r results
    (if (= (car r) status)
      (setq out (append out (list r)))
    )
  )
  out
)

(defun erarq:result-names (results / out r)
  (setq out '())
  (foreach r results
    (setq out (append out (list (cadr r))))
  )
  out
)

(defun erarq:validate-critical-functions (/ missing f)
  (setq missing '())
  (foreach f *erarq-critical-functions*
    (if (not (erarq:fn-exists-p f))
      (setq missing (append missing (list (vl-symbol-name f))))
    )
  )
  missing
)

(defun erarq:print-load-report (results / oks miss errs missingFns)
  (setq oks  (erarq:results-by-status results "ok"))
  (setq miss (erarq:results-by-status results "missing"))
  (setq errs (erarq:results-by-status results "error"))

  (prompt
    (strcat
      "\n[ERARQ] Modulos OK: " (itoa (length oks))
      " | Faltan: " (itoa (length miss))
      " | Error: " (itoa (length errs))
    )
  )

  (if miss
    (prompt
      (strcat
        "\n[ERARQ] Faltan: "
        (erarq:str-list-join (erarq:result-names miss) ", ")
      )
    )
  )

  (if errs
    (progn
      (foreach e errs
        (prompt
          (strcat
            "\n[ERARQ] Error en "
            (cadr e)
            " -> "
            (if (caddr e) (caddr e) "desconocido")
          )
        )
      )
    )
  )

  (setq missingFns (erarq:validate-critical-functions))
  (if missingFns
    (prompt
      (strcat
        "\n[ERARQ] Funciones criticas faltantes: "
        (erarq:str-list-join missingFns ", ")
      )
    )
  )
)

(defun erarq:load-all (/ modules m full res ok fail)
  (if *erarq-app-dir*
    (progn

      (setq modules
        '(
          "erarq_config.lsp"
          "erarq_layers.lsp"
          "erarq_utils.lsp"
          "erarq_tables.lsp"
          "erarq_core.lsp"
          "erarq_labels.lsp"
          "erarq_dims.lsp"
          "erarq_export.lsp"
          "erarq_division.lsp"
          "erarq_grid.lsp"
          "erarq_ui.lsp"
        )
      )

      (setq ok 0)
      (setq fail 0)

      (prompt (strcat "\n[ERARQ] Carpeta app: " *erarq-app-dir*))

      (foreach m modules

        (setq full (erarq:resolve-app-file m))

        (cond

          ((null full)
            (setq fail (1+ fail))
            (prompt (strcat "\n[ERARQ] Falta: " m))
          )

          (T
            (setq res (vl-catch-all-apply 'load (list full)))

            (if (vl-catch-all-error-p res)

              (progn
                (setq fail (1+ fail))
                (prompt
                  (strcat
                    "\n[ERARQ] Error cargando "
                    m
                    " -> "
                    (vl-catch-all-error-message res)
                  )
                )
              )

              (progn
                (setq ok (1+ ok))
                (prompt (strcat "\n[ERARQ] Cargado: " m))
              )
            )
          )
        )
      )

      (prompt
        (strcat
          "\n[ERARQ] Modulos OK: "
          (itoa ok)
          " | Fallos: "
          (itoa fail)
        )
      )

      (setq res (vl-catch-all-apply 'erarq:ensure-base-layers '()))
      (if (vl-catch-all-error-p res)
        nil
      )

    )

    (alert
      "No se pudo definir la carpeta app.\n\nVuelva a cargar erarq_main.lsp y seleccione app\\erarq_config.lsp."
    )
  )
)

(erarq:load-all)

; ============================================================
; AYUDAS DE COMANDOS
; ============================================================

(defun erarq:run-safe-command (fn missingMsg / r)
  (setq r (vl-catch-all-apply fn '()))
  (if (vl-catch-all-error-p r)
    (if (wcmatch
          (strcase (vl-catch-all-error-message r))
          "*NO FUNCTION DEFINITION*"
        )
      (prompt missingMsg)
      (alert
        (strcat
          "Error ejecutando "
          (vl-symbol-name fn)
          ".\n\n"
          (vl-catch-all-error-message r)
        )
      )
    )
  )
  (princ)
)

; ============================================================
; COMANDO PRINCIPAL
; ============================================================

(defun c:ERARQ (/ r)

  (setq r
    (vl-catch-all-apply
      'erarq:run-dialog
      '()
    )
  )

  (cond
    ((vl-catch-all-error-p r)
      (alert
        (strcat
          "Fallo la interfaz ERArq.\n\n"
          (vl-catch-all-error-message r)
        )
      )
    )
    ((numberp r)
      (if (> r 1)
        (progn
          (setq r
            (vl-catch-all-apply
              'erarq:dispatch
              (list r)
            )
          )
          (if (vl-catch-all-error-p r)
            (alert
              (strcat
                "Fallo la accion seleccionada.\n\n"
                (vl-catch-all-error-message r)
              )
            )
          )
        )
      )
    )
  )

  (princ)
)

(defun c:ERARQ_RELOAD ()
  (erarq:load-all)
  (princ)
)

(defun c:ERARQ_RELINK ()
  (setq *erarq-app-dir* (erarq:pick-app-dir))
  (if *erarq-app-dir*
    (progn
      (setenv "ERARQ_APP_DIR" *erarq-app-dir*)
      (prompt (strcat "\n[ERARQ] Nueva carpeta app: " *erarq-app-dir*))
      (erarq:load-all)
    )
    (prompt "\n[ERARQ] Operacion cancelada.")
  )
  (princ)
)

(defun c:ERARQ_CHECK ()
  (if *erarq-last-load-results*
    (erarq:print-load-report *erarq-last-load-results*)
    (prompt "\n[ERARQ] Aun no hay reporte de carga.")
  )
  (princ)
)

; ============================================================
; COMANDOS DIRECTOS
; ============================================================

(defun c:ERARQ_DATOS ()
  (erarq:run-safe-command
    'erarq:parcel-summary-command
    "\n[ERARQ] No se cargo erarq_core.lsp."
  )
)

(defun c:ERARQ_COORDS ()
  (erarq:run-safe-command
    'erarq:coords-table-command
    "\n[ERARQ] No se cargo erarq_core.lsp."
  )
)

(defun c:ERARQ_VERTICES ()
  (erarq:run-safe-command
    'erarq:vertices-command
    "\n[ERARQ] No se cargo erarq_labels.lsp."
  )
)

(defun c:ERARQ_LOTES ()
  (erarq:run-safe-command
    'erarq:number-lots-command
    "\n[ERARQ] No se cargo erarq_labels.lsp."
  )
)

(defun c:ERARQ_LOTES_VERTICES ()
  (erarq:run-safe-command
    'erarq:lot-vertices-command
    "\n[ERARQ] No se cargo erarq_labels.lsp."
  )
)

(defun c:ERARQ_AREAS ()
  (erarq:run-safe-command
    'erarq:areas-table-command
    "\n[ERARQ] No se cargo erarq_core.lsp."
  )
)

(defun c:ERARQ_CONST ()
  (erarq:run-safe-command
    'erarq:table-construction
    "\n[ERARQ] No se cargo erarq_tables.lsp."
  )
)

(defun c:ERARQ_EXPORT_COORDS ()
  (erarq:run-safe-command
    'erarq:export-coords-command
    "\n[ERARQ] No se cargo erarq_export.lsp."
  )
)

(defun c:ERARQ_EXPORT_AREAS ()
  (erarq:run-safe-command
    'erarq:export-areas-command
    "\n[ERARQ] No se cargo erarq_export.lsp."
  )
)

(defun c:ERARQ_DIVIDIR ()
  (erarq:run-safe-command
    'erarq:division-command
    "\n[ERARQ] No se cargo erarq_division.lsp."
  )
)

(defun c:ERARQ_GRID ()
  (erarq:run-safe-command
    'erarq:grid-command
    "\n[ERARQ] No se cargo erarq_grid.lsp."
  )
)

(defun c:ERARQ_GRID_AUTO ()
  (erarq:run-safe-command
    'erarq:grid-auto-command
    "\n[ERARQ] No se cargo erarq_grid.lsp."
  )
)

(defun c:ERARQ_DOC_PARCELA ()
  (erarq:run-safe-command
    'erarq:parcel-doc-command
    "\n[ERARQ] No se cargo erarq_dims.lsp."
  )
)

(defun c:ERARQ_DOC_LOTES ()
  (erarq:run-safe-command
    'erarq:lots-doc-command
    "\n[ERARQ] No se cargo erarq_dims.lsp."
  )
)

(prompt "\nERArq-Urb cargado. Use ERARQ.")
(princ)