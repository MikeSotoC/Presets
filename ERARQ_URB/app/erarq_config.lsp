(vl-load-com)

(setq *erarq-app* "ERArq-Urb")
(setq *erarq-version* "v1.4")

(defun erarq:cfg-bool (v)
  (if v T nil)
)

(defun erarq:sheet-size-valid-p (s)
  (member s '("A4" "A3" "A2" "A1" "A0"))
)

(defun erarq:profile-valid-p (s)
  (member s '("Compacto" "Normal" "Presentacion"))
)

(defun erarq:table-type-valid-p (s)
  (member s '("Simple" "Rumbos" "Angulos" "Mixta"))
)

(defun erarq:sheet-base-text-height (sheet)
  (cond
    ((= sheet "A4") 2.00)
    ((= sheet "A3") 2.50)
    ((= sheet "A2") 3.50)
    ((= sheet "A1") 5.00)
    ((= sheet "A0") 7.00)
    (T 2.50)
  )
)

(defun erarq:profile-factor (profile)
  (cond
    ((= profile "Compacto") 0.90)
    ((= profile "Presentacion") 1.20)
    (T 1.00)
  )
)

(defun erarq:apply-text-profile (/ base fac main small title)
  (setq base (erarq:sheet-base-text-height *erarq-sheet-size*))
  (setq fac  (erarq:profile-factor *erarq-print-profile*))

  (setq main  (* base fac))
  (setq small (* main 0.75))
  (setq title (* main 1.20))

  (setq *erarq-text-height*       main)
  (setq *erarq-small-text-height* small)
  (setq *erarq-title-text-height* title)
)

(defun erarq:cfg-defaults ()
  ;; ------------------------------------------------------------
  ;; datos generales
  ;; ------------------------------------------------------------
  (setq *erarq-project*       "Proyecto Urbano")
  (setq *erarq-parcel-name*   "Parcela 01")
  (setq *erarq-lot-prefix*    "L")
  (setq *erarq-start-number*  1)
  (setq *erarq-vertex-prefix* "V")

  ;; ------------------------------------------------------------
  ;; formato numérico
  ;; ------------------------------------------------------------
  (setq *erarq-dec-coord* 3)
  (setq *erarq-dec-area*  2)
  (setq *erarq-dec-dist*  2)
  (setq *erarq-dec-ang*   0)

  ;; ------------------------------------------------------------
  ;; presentación / hoja
  ;; ------------------------------------------------------------
  (setq *erarq-sheet-size*      "A3")
  (setq *erarq-print-profile*   "Normal")
  (setq *erarq-plot-style*      "ERARQ_PRESENTACION.ctb")
  (setq *erarq-auto-text-scale* T)

  ;; alturas
  (setq *erarq-text-height*       2.50)
  (setq *erarq-small-text-height* 1.88)
  (setq *erarq-title-text-height* 3.00)

  ;; ------------------------------------------------------------
  ;; capa general
  ;; ------------------------------------------------------------
  (setq *erarq-layer* "ERARQ")

  ;; ------------------------------------------------------------
  ;; toggles base
  ;; ------------------------------------------------------------
  (setq *erarq-draw-texts*   T)
  (setq *erarq-draw-tables*  T)
  (setq *erarq-create-polys* T)

  ;; ------------------------------------------------------------
  ;; grilla
  ;; ------------------------------------------------------------
  (setq *erarq-grid-dx*   100.0)
  (setq *erarq-grid-dy*   100.0)
  (setq *erarq-grid-mode* "E")

  ;; ------------------------------------------------------------
  ;; documentación general
  ;; ------------------------------------------------------------
  (setq *erarq-draw_distances* nil) ; compatibilidad si existía vieja
  (setq *erarq-draw-distances* T)
  (setq *erarq-draw-angles*    T)
  (setq *erarq-draw-area*      T)
  (setq *erarq-draw-perim*     T)

  ;; ------------------------------------------------------------
  ;; documentación parcela
  ;; ------------------------------------------------------------
  (setq *erarq-doc-vertices-parcel* T)
  (setq *erarq-doc-rumbos-parcel*   T)

  ;; ------------------------------------------------------------
  ;; documentación lotes
  ;; ------------------------------------------------------------
  (setq *erarq-doc-number-lots*   T)
  (setq *erarq-doc-vertices-lots* T)
  (setq *erarq-doc-rumbos-lots*   T)

  ;; ------------------------------------------------------------
  ;; tabla técnica
  ;; ------------------------------------------------------------
  (setq *erarq-table-type*        "Mixta")
  (setq *erarq-table-title*       "DATOS TECNICOS")
  (setq *erarq-coord-title*       "WGS 84")
  (setq *erarq-include-eastnorth* T)
  (setq *erarq-include-summary*   T)

  (erarq:apply-text-profile)
)

(defun erarq:cfg-normalize ()
  (if (or (null *erarq-project*) (= *erarq-project* ""))
    (setq *erarq-project* "Proyecto Urbano")
  )

  (if (or (null *erarq-parcel-name*) (= *erarq-parcel-name* ""))
    (setq *erarq-parcel-name* "Parcela 01")
  )

  (if (or (null *erarq-lot-prefix*) (= *erarq-lot-prefix* ""))
    (setq *erarq-lot-prefix* "L")
  )

  (if (or (null *erarq-vertex-prefix*) (= *erarq-vertex-prefix* ""))
    (setq *erarq-vertex-prefix* "V")
  )

  (if (or (null *erarq-start-number*) (< *erarq-start-number* 1))
    (setq *erarq-start-number* 1)
  )

  (if (or (null *erarq-dec-coord*) (< *erarq-dec-coord* 0))
    (setq *erarq-dec-coord* 3)
  )

  (if (or (null *erarq-dec-area*) (< *erarq-dec-area* 0))
    (setq *erarq-dec-area* 2)
  )

  (if (or (null *erarq-dec-dist*) (< *erarq-dec-dist* 0))
    (setq *erarq-dec-dist* 2)
  )

  (if (or (null *erarq-dec-ang*) (< *erarq-dec-ang* 0))
    (setq *erarq-dec-ang* 0)
  )

  (if (or (null *erarq-layer*) (= *erarq-layer* ""))
    (setq *erarq-layer* "ERARQ")
  )

  (if (or (null *erarq-grid-dx*) (<= *erarq-grid-dx* 0.0))
    (setq *erarq-grid-dx* 100.0)
  )

  (if (or (null *erarq-grid-dy*) (<= *erarq-grid-dy* 0.0))
    (setq *erarq-grid-dy* *erarq-grid-dx*)
  )

  (if (not (member *erarq-grid-mode* '("E" "I")))
    (setq *erarq-grid-mode* "E")
  )

  (setq *erarq-draw-texts*          (erarq:cfg-bool *erarq-draw-texts*))
  (setq *erarq-draw-tables*         (erarq:cfg-bool *erarq-draw-tables*))
  (setq *erarq-create-polys*        (erarq:cfg-bool *erarq-create-polys*))
  (setq *erarq-draw-distances*      (erarq:cfg-bool *erarq-draw-distances*))
  (setq *erarq-draw-angles*         (erarq:cfg-bool *erarq-draw-angles*))
  (setq *erarq-draw-area*           (erarq:cfg-bool *erarq-draw-area*))
  (setq *erarq-draw-perim*          (erarq:cfg-bool *erarq-draw-perim*))
  (setq *erarq-doc-vertices-parcel* (erarq:cfg-bool *erarq-doc-vertices-parcel*))
  (setq *erarq-doc-rumbos-parcel*   (erarq:cfg-bool *erarq-doc-rumbos-parcel*))
  (setq *erarq-doc-number-lots*     (erarq:cfg-bool *erarq-doc-number-lots*))
  (setq *erarq-doc-vertices-lots*   (erarq:cfg-bool *erarq-doc-vertices-lots*))
  (setq *erarq-doc-rumbos-lots*     (erarq:cfg-bool *erarq-doc-rumbos-lots*))
  (setq *erarq-include-eastnorth*   (erarq:cfg-bool *erarq-include-eastnorth*))
  (setq *erarq-include-summary*     (erarq:cfg-bool *erarq-include-summary*))
  (setq *erarq-auto-text-scale*     (erarq:cfg-bool *erarq-auto-text-scale*))

  (if (not (erarq:sheet-size-valid-p *erarq-sheet-size*))
    (setq *erarq-sheet-size* "A3")
  )

  (if (not (erarq:profile-valid-p *erarq-print-profile*))
    (setq *erarq-print-profile* "Normal")
  )

  (if (not (erarq:table-type-valid-p *erarq-table-type*))
    (setq *erarq-table-type* "Mixta")
  )

  (if (or (null *erarq-table-title*) (= *erarq-table-title* ""))
    (setq *erarq-table-title* "DATOS TECNICOS")
  )

  (if (or (null *erarq-coord-title*) (= *erarq-coord-title* ""))
    (setq *erarq-coord-title* "WGS 84")
  )

  (if (or (null *erarq-plot-style*) (= *erarq-plot-style* ""))
    (setq *erarq-plot-style* "ERARQ_PRESENTACION.ctb")
  )

  (if *erarq-auto-text-scale*
    (erarq:apply-text-profile)
    (progn
      (if (or (null *erarq-text-height*) (<= *erarq-text-height* 0.0))
        (setq *erarq-text-height* 2.50)
      )
      (if (or (null *erarq-small-text-height*) (<= *erarq-small-text-height* 0.0))
        (setq *erarq-small-text-height* (* *erarq-text-height* 0.75))
      )
      (if (or (null *erarq-title-text-height*) (<= *erarq-title-text-height* 0.0))
        (setq *erarq-title-text-height* (* *erarq-text-height* 1.20))
      )
    )
  )
)

(erarq:cfg-defaults)
(erarq:cfg-normalize)

(princ)