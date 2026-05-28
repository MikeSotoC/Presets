(vl-load-com)

; ============================================================
; MENSAJES / FORMATO
; ============================================================

(defun erarq:msg (txt)
  (if (not (and (boundp '*erarq-msg-silent*) *erarq-msg-silent*))
    (prompt (strcat "\n" txt))
  )
)

(defun erarq:alert (txt)
  (alert txt)
)

(defun erarq:num->str (val dec)
  (rtos (float val) 2 dec)
)

(defun erarq:int->str (n)
  (itoa n)
)

(defun erarq:pt3d (p)
  (list (car p) (cadr p) 0.0)
)

(defun erarq:bool->tile (v)
  (if v "1" "0")
)

(defun erarq:tile->bool (v)
  (= v "1")
)

; ============================================================
; DOCUMENTO / MODELSPACE / UNDO
; ============================================================

(defun erarq:get-doc ()
  (vla-get-ActiveDocument (vlax-get-acad-object))
)

(defun erarq:get-ms ()
  (vla-get-ModelSpace (erarq:get-doc))
)

(defun erarq:start-undo ()
  (vl-catch-all-apply 'vla-StartUndoMark (list (erarq:get-doc)))
)

(defun erarq:end-undo ()
  (vl-catch-all-apply 'vla-EndUndoMark (list (erarq:get-doc)))
)

; ============================================================
; CAPAS - RESPALDO
; Usa erarq_layers.lsp si ya esta cargado
; ============================================================

(defun erarq:layer-ensure-fallback (lay / doc layers)
  (setq doc (erarq:get-doc))
  (setq layers (vla-get-Layers doc))
  (if (not (tblsearch "LAYER" lay))
    (vla-add layers lay)
  )
  lay
)

(defun erarq:layer-ensure-safe (lay)
  (if (and lay (/= lay ""))
    (progn
      (if (and (erarq:fn-exists-p 'erarq:layer-ensure)
               (not (eq 'erarq:layer-ensure-safe 'erarq:layer-ensure)))
        (erarq:layer-ensure lay)
        (erarq:layer-ensure-fallback lay)
      )
    )
  )
  lay
)

; ============================================================
; DIBUJO BASICO
; ============================================================

(defun erarq:draw-line (p1 p2 lay)
  (erarq:layer-ensure-safe lay)
  (entmakex
    (list
      '(0 . "LINE")
      (cons 8 lay)
      (cons 10 (erarq:pt3d p1))
      (cons 11 (erarq:pt3d p2))
    )
  )
)

(defun erarq:draw-text (pt txt hgt lay)
  (erarq:layer-ensure-safe lay)
  (entmakex
    (list
      '(0 . "TEXT")
      '(100 . "AcDbEntity")
      (cons 8 lay)
      '(100 . "AcDbText")
      (cons 10 (erarq:pt3d pt))
      (cons 11 (erarq:pt3d pt))
      (cons 40 hgt)
      (cons 1 txt)
      (cons 7 "Standard")
      (cons 50 0.0)
      (cons 72 0)
      (cons 73 0)
    )
  )
)

(defun erarq:draw-polyline (pts lay closed / data)
  (erarq:layer-ensure-safe lay)
  (setq data
    (append
      (list
        '(0 . "LWPOLYLINE")
        '(100 . "AcDbEntity")
        (cons 8 lay)
        '(100 . "AcDbPolyline")
        (cons 90 (length pts))
        (cons 70 (if closed 1 0))
      )
      (apply 'append
        (mapcar
          '(lambda (p)
             (list
               (cons 10 (list (car p) (cadr p)))
               (cons 42 0.0)
             )
           )
          pts
        )
      )
    )
  )
  (entmakex data)
)

; ============================================================
; SELECCION DE POLILINEAS
; ============================================================

(defun erarq:get-lwpoly-entity (/ ent ed)
  (setq ent (car (entsel "\nSeleccione una polilinea cerrada: ")))
  (cond
    ((null ent) nil)
    ((/= (cdr (assoc 0 (entget ent))) "LWPOLYLINE")
      (erarq:msg "La entidad seleccionada no es una LWPOLYLINE.")
      nil
    )
    ((/= (logand 1 (cdr (assoc 70 (entget ent)))) 1)
      (erarq:msg "La polilinea debe estar cerrada.")
      nil
    )
    (T ent)
  )
)

(defun erarq:get-lwpoly-object (/ ent)
  (if (setq ent (erarq:get-lwpoly-entity))
    (vlax-ename->vla-object ent)
  )
)

(defun erarq:ssget-closed-lwpolys (/ ss i e ed lst)
  (prompt "\nSeleccione polilineas cerradas: ")
  (setq ss (ssget '((0 . "LWPOLYLINE"))))
  (if ss
    (progn
      (setq i 0)
      (setq lst '())
      (repeat (sslength ss)
        (setq e (ssname ss i))
        (setq ed (entget e))
        (if (= (logand 1 (cdr (assoc 70 ed))) 1)
          (setq lst (cons (vlax-ename->vla-object e) lst))
        )
        (setq i (1+ i))
      )
      (reverse lst)
    )
  )
)

; ============================================================
; SELECCION ORDENADA DE LOTES
; ============================================================

(defun erarq:is-closed-lwpoly-object-p (obj / en ed)
  (if obj
    (progn
      (setq en (vlax-vla-object->ename obj))
      (setq ed (entget en))
      (and
        (= (cdr (assoc 0 ed)) "LWPOLYLINE")
        (= 1 (logand 1 (cdr (assoc 70 ed))))
      )
    )
    nil
  )
)

(defun erarq:get-selected-lot-objects-in-order (/ ref en obj out done)
  (setq out '())
  (setq done nil)

  (prompt
    "\nSeleccione los lotes UNO POR UNO en el orden deseado. Presione ENTER para terminar."
  )

  (while (not done)
    (setq ref (entsel "\nSeleccione lote: "))

    (cond
      ((null ref)
        (setq done T)
      )
      (T
        (setq en  (car ref))
        (setq obj (vlax-ename->vla-object en))

        (if (erarq:is-closed-lwpoly-object-p obj)
          (setq out (append out (list obj)))
          (prompt "\nDebe seleccionar una LWPOLYLINE cerrada.")
        )
      )
    )
  )

  (if out out nil)
)

; ============================================================
; GEOMETRIA DE OBJETOS
; ============================================================

(defun erarq:get-vertices (obj / coords lst)
  (setq coords
    (vlax-safearray->list
      (vlax-variant-value (vla-get-Coordinates obj))
    )
  )
  (setq lst '())
  (while coords
    (setq lst (append lst (list (list (car coords) (cadr coords) 0.0))))
    (setq coords (cddr coords))
  )
  lst
)

(defun erarq:obj-area (obj)
  (vla-get-Area obj)
)

(defun erarq:obj-perimeter (obj)
  (vla-get-Length obj)
)

(defun erarq:avg-centroid (pts / sx sy n p)
  (setq sx 0.0)
  (setq sy 0.0)
  (setq n 0)

  (foreach p pts
    (setq sx (+ sx (car p)))
    (setq sy (+ sy (cadr p)))
    (setq n (1+ n))
  )

  (if (> n 0)
    (list (/ sx n) (/ sy n) 0.0)
    '(0.0 0.0 0.0)
  )
)

(defun erarq:polygon-centroid (pts / n i p1 p2 x1 y1 x2 y2 cross a cx cy)
  (setq n (length pts))

  (if (< n 3)
    (erarq:avg-centroid pts)
    (progn
      (setq i 0)
      (setq a 0.0)
      (setq cx 0.0)
      (setq cy 0.0)

      (repeat n
        (setq p1 (nth i pts))
        (setq p2 (nth (if (= i (1- n)) 0 (1+ i)) pts))

        (setq x1 (car p1))
        (setq y1 (cadr p1))
        (setq x2 (car p2))
        (setq y2 (cadr p2))

        (setq cross (- (* x1 y2) (* x2 y1)))
        (setq a (+ a cross))
        (setq cx (+ cx (* (+ x1 x2) cross)))
        (setq cy (+ cy (* (+ y1 y2) cross)))

        (setq i (1+ i))
      )

      (if (equal a 0.0 1e-12)
        (erarq:avg-centroid pts)
        (progn
          (setq a (/ a 2.0))
          (list (/ cx (* 6.0 a)) (/ cy (* 6.0 a)) 0.0)
        )
      )
    )
  )
)

(defun erarq:sort-objects-by-grid (objs / enriched o pts cen)
  (setq enriched '())

  (foreach o objs
    (setq pts (erarq:get-vertices o))
    (setq cen (erarq:polygon-centroid pts))
    (setq enriched
      (cons
        (list (cadr cen) (car cen) o)
        enriched
      )
    )
  )

  (setq enriched
    (vl-sort
      enriched
      '(lambda (a b)
         (if (> (abs (- (car a) (car b))) 1e-8)
           (> (car a) (car b))
           (< (cadr a) (cadr b))
         )
       )
    )
  )

  (mapcar
    '(lambda (item) (nth 2 item))
    enriched
  )
)

(princ)