(vl-load-com)

; ============================================================
; BASE COM / CAPAS
; ============================================================

(defun erarq:get-doc ()
  (vla-get-ActiveDocument (vlax-get-acad-object))
)

(defun erarq:get-layers ()
  (vla-get-Layers (erarq:get-doc))
)

(defun erarq:layer-exists-p (lay)
  (if (tblsearch "LAYER" lay) T nil)
)

(defun erarq:layer-ensure (lay / layers obj)
  (if (and lay (/= lay ""))
    (progn
      (setq layers (erarq:get-layers))
      (if (not (erarq:layer-exists-p lay))
        (setq obj (vla-add layers lay))
        (setq obj (vla-item layers lay))
      )
      obj
    )
  )
)

(defun erarq:linetype-exists-p (name)
  (if (tblsearch "LTYPE" name) T nil)
)

(defun erarq:ensure-linetype-loaded (name / doc ltypes)
  (if (and name (/= name ""))
    (progn
      (if (not (erarq:linetype-exists-p name))
        (progn
          (setq doc    (erarq:get-doc))
          (setq ltypes (vla-get-Linetypes doc))
          (vl-catch-all-apply
            'vla-load
            (list ltypes name "acad.lin")
          )
        )
      )
    )
  )
)

(defun erarq:layer-set-color (lay color / obj)
  (if (and lay (numberp color))
    (progn
      (setq obj (erarq:layer-ensure lay))
      (if obj
        (vla-put-Color obj color)
      )
    )
  )
)

(defun erarq:layer-set-linetype (lay lt / obj)
  (if (and lay lt (/= lt ""))
    (progn
      (erarq:ensure-linetype-loaded lt)
      (setq obj (erarq:layer-ensure lay))
      (if obj
        (vl-catch-all-apply
          'vla-put-Linetype
          (list obj lt)
        )
      )
    )
  )
)

(defun erarq:layer-set-lineweight (lay lw / obj)
  ;; Valores típicos:
  ;; -1 = Default / ByLayer
  ;; 13 = 0.13 mm
  ;; 15 = 0.15 mm
  ;; 18 = 0.18 mm
  ;; 20 = 0.20 mm
  ;; 25 = 0.25 mm
  ;; 30 = 0.30 mm
  ;; 35 = 0.35 mm
  ;; 40 = 0.40 mm
  ;; 50 = 0.50 mm
  (if (and lay (numberp lw))
    (progn
      (setq obj (erarq:layer-ensure lay))
      (if obj
        (vl-catch-all-apply
          'vla-put-Lineweight
          (list obj lw)
        )
      )
    )
  )
)

(defun erarq:layer-thaw-on-unlock (lay / obj)
  (setq obj (erarq:layer-ensure lay))
  (if obj
    (progn
      (vl-catch-all-apply 'vla-put-Freeze (list obj :vlax-false))
      (vl-catch-all-apply 'vla-put-LayerOn (list obj :vlax-true))
      (vl-catch-all-apply 'vla-put-Lock (list obj :vlax-false))
      T
    )
    nil
  )
)

(defun erarq:layer-setup (lay color ltype lw / obj)
  (setq obj (erarq:layer-ensure lay))
  (if obj
    (progn
      (erarq:layer-thaw-on-unlock lay)
      (if (numberp color)
        (vla-put-Color obj color)
      )
      (if (and ltype (/= ltype ""))
        (progn
          (erarq:ensure-linetype-loaded ltype)
          (vl-catch-all-apply 'vla-put-Linetype (list obj ltype))
        )
      )
      (if (numberp lw)
        (vl-catch-all-apply 'vla-put-Lineweight (list obj lw))
      )
      obj
    )
  )
)

(defun erarq:layer-setup-list (lst / item lay color lt lw)
  ;; cada item = (list "CAPA" color "linetype" lineweight)
  (foreach item lst
    (setq lay   (nth 0 item))
    (setq color (nth 1 item))
    (setq lt    (nth 2 item))
    (setq lw    (nth 3 item))
    (erarq:layer-setup lay color lt lw)
  )
)

; ============================================================
; NOMBRES DE CAPAS BASE
; ============================================================

(defun erarq:layer-parcela () "ERARQ_PARCELA")
(defun erarq:layer-parcela-txt () "ERARQ_PARCELA_TXT")
(defun erarq:layer-parcela-vert () "ERARQ_PARCELA_VERT")
(defun erarq:layer-parcela-dist () "ERARQ_PARCELA_DIST")
(defun erarq:layer-parcela-ang () "ERARQ_PARCELA_ANG")
(defun erarq:layer-parcela-rumbo () "ERARQ_PARCELA_RUMBO")

(defun erarq:layer-tablas () "ERARQ_TABLAS")
(defun erarq:layer-tablas-tec () "ERARQ_TABLAS_TEC")
(defun erarq:layer-tablas-coord () "ERARQ_TABLAS_COORD")
(defun erarq:layer-tablas-col () "ERARQ_TABLAS_COL")
(defun erarq:layer-tablas-area () "ERARQ_TABLAS_AREA")
(defun erarq:layer-tablas-repl () "ERARQ_TABLAS_REPL")

(defun erarq:layer-grid () "ERARQ_GRID")
(defun erarq:layer-grid-minor () "ERARQ_GRID_MINOR")
(defun erarq:layer-grid-major () "ERARQ_GRID_MAJOR")
(defun erarq:layer-grid-master () "ERARQ_GRID_MASTER")
(defun erarq:layer-grid-border () "ERARQ_GRID_BORDER")
(defun erarq:layer-grid-txt () "ERARQ_GRID_TXT")

(defun erarq:layer-repl () "ERARQ_REPL")
(defun erarq:layer-repl-txt () "ERARQ_REPL_TXT")
(defun erarq:layer-repl-vert () "ERARQ_REPL_VERT")

; ============================================================
; NOMBRES DE CAPAS POR LOTE
; ============================================================

(defun erarq:layer-lote (n)
  (strcat "ERARQ_LOTES_" (itoa n))
)

(defun erarq:layer-lote-txt (n)
  (strcat "ERARQ_LOTES_" (itoa n) "_TXT")
)

(defun erarq:layer-lote-vert (n)
  (strcat "ERARQ_LOTES_" (itoa n) "_VERT")
)

(defun erarq:layer-lote-dist (n)
  (strcat "ERARQ_LOTES_" (itoa n) "_DIST")
)

(defun erarq:layer-lote-ang (n)
  (strcat "ERARQ_LOTES_" (itoa n) "_ANG")
)

(defun erarq:layer-lote-rumbo (n)
  (strcat "ERARQ_LOTES_" (itoa n) "_RUMBO")
)

(defun erarq:layer-lote-area (n)
  (strcat "ERARQ_LOTES_" (itoa n) "_AREA")
)

; ============================================================
; PALETA VISUAL ESCALA DE GRISES / PRESENTACION FINAL
; ============================================================
; Nota:
; - 7  = blanco/negro según fondo
; - 8  = gris oscuro
; - 9  = gris medio
; - 250/251/252/253/254 = grises suaves si el CAD los soporta bien
; Para máxima compatibilidad, uso principalmente 7, 8 y 9.

(defun erarq:col-main () 7)       ; negro/blanco fuerte
(defun erarq:col-strong () 8)     ; gris oscuro
(defun erarq:col-medium () 9)     ; gris medio
(defun erarq:col-soft () 8)       ; gris oscuro compatible
(defun erarq:col-very-soft () 9)  ; gris medio compatible

; ============================================================
; CONFIGURACION VISUAL BASE - PRESENTACION FINAL
; ============================================================

(defun erarq:ensure-base-layers ()
  (erarq:layer-setup-list
    (list
      ;; ------------------------------------------------------
      ;; PARCELA
      ;; Jerarquía:
      ;; contorno > textos auxiliares / vértices / cotas
      ;; ------------------------------------------------------
      (list (erarq:layer-parcela)        (erarq:col-main)      "Continuous" 40)
      (list (erarq:layer-parcela-txt)    (erarq:col-main)      "Continuous" 18)
      (list (erarq:layer-parcela-vert)   (erarq:col-strong)    "Continuous" 18)
      (list (erarq:layer-parcela-dist)   (erarq:col-medium)    "Continuous" 18)
      (list (erarq:layer-parcela-ang)    (erarq:col-medium)    "Continuous" 15)
      (list (erarq:layer-parcela-rumbo)  (erarq:col-medium)    "Continuous" 18)

      ;; ------------------------------------------------------
      ;; TABLAS
      ;; borde/base con peso medio, contenido fino
      ;; ------------------------------------------------------
      (list (erarq:layer-tablas)         (erarq:col-main)      "Continuous" 25)
      (list (erarq:layer-tablas-tec)     (erarq:col-strong)    "Continuous" 18)
      (list (erarq:layer-tablas-coord)   (erarq:col-strong)    "Continuous" 18)
      (list (erarq:layer-tablas-col)     (erarq:col-medium)    "Continuous" 18)
      (list (erarq:layer-tablas-area)    (erarq:col-main)      "Continuous" 20)
      (list (erarq:layer-tablas-repl)    (erarq:col-strong)    "Continuous" 18)

      ;; ------------------------------------------------------
      ;; GRILLA
      ;; muy sutil para no ensuciar presentación
      ;; ------------------------------------------------------
      (list (erarq:layer-grid)           (erarq:col-very-soft) "Continuous" 13)
      (list (erarq:layer-grid-minor)     (erarq:col-very-soft) "Continuous" 13)
      (list (erarq:layer-grid-major)     (erarq:col-soft)      "Continuous" 18)
      (list (erarq:layer-grid-master)    (erarq:col-strong)    "Continuous" 25)
      (list (erarq:layer-grid-border)    (erarq:col-main)      "Continuous" 35)
      (list (erarq:layer-grid-txt)       (erarq:col-medium)    "Continuous" 13)

      ;; ------------------------------------------------------
      ;; REPLANTEO
      ;; visible, pero sin competir con el contorno principal
      ;; ------------------------------------------------------
      (list (erarq:layer-repl)           (erarq:col-main)      "Continuous" 25)
      (list (erarq:layer-repl-txt)       (erarq:col-strong)    "Continuous" 18)
      (list (erarq:layer-repl-vert)      (erarq:col-strong)    "Continuous" 18)
    )
  )
)

(defun erarq:ensure-lot-layers (n)
  (erarq:layer-setup-list
    (list
      ;; ------------------------------------------------------
      ;; LOTES
      ;; contorno fuerte, texto/cotas finos en gris
      ;; ------------------------------------------------------
      (list (erarq:layer-lote n)         (erarq:col-main)      "Continuous" 30)
      (list (erarq:layer-lote-txt n)     (erarq:col-main)      "Continuous" 18)
      (list (erarq:layer-lote-vert n)    (erarq:col-strong)    "Continuous" 18)
      (list (erarq:layer-lote-dist n)    (erarq:col-medium)    "Continuous" 18)
      (list (erarq:layer-lote-ang n)     (erarq:col-medium)    "Continuous" 15)
      (list (erarq:layer-lote-rumbo n)   (erarq:col-medium)    "Continuous" 18)
      (list (erarq:layer-lote-area n)    (erarq:col-main)      "Continuous" 20)
    )
  )
)

; ============================================================
; COMANDO BASE
; ============================================================

(defun c:ERARQ_LAYERS ()
  (erarq:ensure-base-layers)
  (prompt "\n[ERARQ] Capas base de presentacion final creadas/actualizadas en escala de grises.")
  (princ)
)

; ============================================================
; COMANDO OPCIONAL PARA PROBAR UN LOTE
; ============================================================

(defun c:ERARQ_LOTE_LAYERS (/ n)
  (setq n (getint "\nNumero de lote: "))
  (if (and n (> n 0))
    (progn
      (erarq:ensure-lot-layers n)
      (prompt (strcat "\n[ERARQ] Capas del lote " (itoa n) " creadas/actualizadas."))
    )
    (prompt "\n[ERARQ] Numero invalido.")
  )
  (princ)
)

(princ)