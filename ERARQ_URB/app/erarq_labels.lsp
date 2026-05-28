(vl-load-com)

; ============================================================
; APOYO
; ============================================================

(defun erarq:set-object-layer-safe (obj lay)
  (if (and obj lay (/= lay ""))
    (progn
      (erarq:layer-ensure-safe lay)
      (vla-put-Layer obj lay)
    )
  )
)

(defun erarq:lot-label-text (n)
  (strcat *erarq-lot-prefix* (itoa n))
)

(defun erarq:vertex-text (n)
  (strcat *erarq-vertex-prefix* (itoa n))
)

(defun erarq:lot-vertex-text (lotN vertN)
  (strcat
    *erarq-lot-prefix* (itoa lotN)
    "-"
    *erarq-vertex-prefix* (itoa vertN)
  )
)

; ============================================================
; VERTICES DE PARCELA SOBRE OBJETO
; ============================================================

(defun erarq:label-vertices-on-object (obj / pts i p off lay)
  (if obj
    (progn
      (erarq:ensure-base-layers)
      (erarq:set-object-layer-safe obj (erarq:layer-parcela))

      (setq pts (erarq:get-vertices obj))
      (setq off (* *erarq-text-height* 1.2))
      (setq i   1)
      (setq lay (erarq:layer-parcela-vert))

      (foreach p pts
        (erarq:draw-text
          (list (+ (car p) off) (+ (cadr p) off) 0.0)
          (erarq:vertex-text i)
          *erarq-text-height*
          lay
        )
        (setq i (1+ i))
      )
    )
  )
)

(defun erarq:label-vertices (/ obj)
  (setq obj (erarq:get-lwpoly-object))
  (if obj
    (progn
      (erarq:label-vertices-on-object obj)
      (if (and (boundp '*erarq-msg-silent*) *erarq-msg-silent*)
        nil
        (if (erarq:fn-exists-p 'erarq:msg)
          (erarq:msg "Vertices de parcela etiquetados correctamente.")
        )
      )
    )
  )
)

; ============================================================
; NUMERACION DE LOTES SOBRE LISTA
; ============================================================

(defun erarq:number-lots-on-list (objs / n pts c polyLay txtLay)
  (if objs
    (progn
      (setq n *erarq-start-number*)

      (foreach o objs
        (erarq:ensure-lot-layers n)

        (setq polyLay (erarq:layer-lote n))
        (setq txtLay  (erarq:layer-lote-txt n))

        (erarq:set-object-layer-safe o polyLay)

        (setq pts (erarq:get-vertices o))
        (setq c   (erarq:polygon-centroid pts))

        (erarq:draw-text
          c
          (erarq:lot-label-text n)
          *erarq-text-height*
          txtLay
        )

        (setq n (1+ n))
      )
    )
  )
)

(defun erarq:number-lots (/ objs)
  (setq objs (erarq:get-selected-lot-objects-in-order))
  (if objs
    (progn
      (erarq:number-lots-on-list objs)
      (if (and (boundp '*erarq-msg-silent*) *erarq-msg-silent*)
        nil
        (if (erarq:fn-exists-p 'erarq:msg)
          (erarq:msg "Lotes numerados en el orden exacto de seleccion.")
        )
      )
    )
  )
)

; ============================================================
; VERTICES POR LOTE SOBRE LISTA
; ============================================================

(defun erarq:label-lot-vertices-on-list (objs / n pts i p off lay)
  (if objs
    (progn
      (setq n *erarq-start-number*)
      (setq off (* *erarq-text-height* 1.0))

      (foreach o objs
        (erarq:ensure-lot-layers n)
        (erarq:set-object-layer-safe o (erarq:layer-lote n))

        (setq pts (erarq:get-vertices o))
        (setq i   1)
        (setq lay (erarq:layer-lote-vert n))

        (foreach p pts
          (erarq:draw-text
            (list (+ (car p) off) (+ (cadr p) off) 0.0)
            (erarq:lot-vertex-text n i)
            *erarq-text-height*
            lay
          )
          (setq i (1+ i))
        )

        (setq n (1+ n))
      )
    )
  )
)

(defun erarq:label-lot-vertices (/ objs)
  (setq objs (erarq:get-selected-lot-objects-in-order))
  (if objs
    (progn
      (erarq:label-lot-vertices-on-list objs)
      (if (and (boundp '*erarq-msg-silent*) *erarq-msg-silent*)
        nil
        (if (erarq:fn-exists-p 'erarq:msg)
          (erarq:msg "Vertices por lote etiquetados en el orden exacto de seleccion.")
        )
      )
    )
  )
)

; ============================================================
; COMANDOS
; ============================================================

(defun erarq:vertices-command ()
  (erarq:start-undo)
  (erarq:label-vertices)
  (erarq:end-undo)
  (princ)
)

(defun erarq:number-lots-command ()
  (erarq:start-undo)
  (erarq:number-lots)
  (erarq:end-undo)
  (princ)
)

(defun erarq:lot-vertices-command ()
  (erarq:start-undo)
  (erarq:label-lot-vertices)
  (erarq:end-undo)
  (princ)
)

(princ)