(vl-load-com)

; ============================================================
; UTILIDADES VECTORIALES
; ============================================================

(defun erarq:clamp (v a b)
  (max a (min b v))
)

(defun erarq:vec-add (a b)
  (list
    (+ (car a) (car b))
    (+ (cadr a) (cadr b))
    0.0
  )
)

(defun erarq:vec-sub (a b)
  (list
    (- (car a) (car b))
    (- (cadr a) (cadr b))
    0.0
  )
)

(defun erarq:vec-scale (v s)
  (list
    (* (car v) s)
    (* (cadr v) s)
    0.0
  )
)

(defun erarq:vec-dot (a b)
  (+ (* (car a) (car b))
     (* (cadr a) (cadr b)))
)

(defun erarq:vec-len (v)
  (sqrt
    (+ (* (car v) (car v))
       (* (cadr v) (cadr v)))
  )
)

(defun erarq:vec-unit (v / l)
  (setq l (erarq:vec-len v))
  (if (> l 1e-12)
    (list (/ (car v) l) (/ (cadr v) l) 0.0)
    '(0.0 0.0 0.0)
  )
)

(defun erarq:vec-perp-left (v)
  (list
    (- (cadr v))
    (car v)
    0.0
  )
)

(defun erarq:midpoint (p1 p2)
  (list
    (/ (+ (car p1) (car p2)) 2.0)
    (/ (+ (cadr p1) (cadr p2)) 2.0)
    0.0
  )
)

(defun erarq:polar-pt (p ang dist)
  (list
    (+ (car p) (* dist (cos ang)))
    (+ (cadr p) (* dist (sin ang)))
    0.0
  )
)

(defun erarq:acos-safe (x / v)
  (setq v (erarq:clamp x -1.0 1.0))
  (atan (sqrt (max 0.0 (- 1.0 (* v v)))) v)
)

; ============================================================
; ANGULOS
; ============================================================

(defun erarq:ang-norm (a)
  (while (< a 0.0)
    (setq a (+ a (* 2.0 pi)))
  )
  (while (>= a (* 2.0 pi))
    (setq a (- a (* 2.0 pi)))
  )
  a
)

(defun erarq:angle-diff-ccw (a1 a2 / d)
  (setq d (- (erarq:ang-norm a2) (erarq:ang-norm a1)))
  (while (< d 0.0)
    (setq d (+ d (* 2.0 pi)))
  )
  (while (>= d (* 2.0 pi))
    (setq d (- d (* 2.0 pi)))
  )
  d
)

(defun erarq:angle-mid-ccw (a1 a2 / d)
  (setq d (erarq:angle-diff-ccw a1 a2))
  (erarq:ang-norm (+ a1 (/ d 2.0)))
)

(defun erarq:angle-readable (rot)
  (setq rot (erarq:ang-norm rot))
  (if (and (> rot (/ pi 2.0)) (< rot (* 1.5 pi)))
    (setq rot (+ rot pi))
  )
  (erarq:ang-norm rot)
)

; ============================================================
; APOYO GEOMETRICO
; ============================================================

(defun erarq:side-normal-outward (p1 p2 ctr / mid edge n testpt)
  (setq mid    (erarq:midpoint p1 p2))
  (setq edge   (erarq:vec-sub p2 p1))
  (setq n      (erarq:vec-unit (erarq:vec-perp-left edge)))
  (setq testpt (erarq:vec-add mid (erarq:vec-scale n 1.0)))

  (if (< (distance testpt ctr) (distance mid ctr))
    (setq n (erarq:vec-scale n -1.0))
  )
  n
)

(defun erarq:side-normal-inward (p1 p2 ctr)
  (erarq:vec-scale (erarq:side-normal-outward p1 p2 ctr) -1.0)
)

(defun erarq:side-text-point (p1 p2 ctr offAlong offNormal outwardP / mid dir n)
  (setq mid (erarq:midpoint p1 p2))
  (setq dir (erarq:vec-unit (erarq:vec-sub p2 p1)))
  (setq n
    (if outwardP
      (erarq:side-normal-outward p1 p2 ctr)
      (erarq:side-normal-inward p1 p2 ctr)
    )
  )

  (erarq:vec-add
    (erarq:vec-add mid (erarq:vec-scale dir offAlong))
    (erarq:vec-scale n offNormal)
  )
)

(defun erarq:angle-side-facing-centroid-p (p a1 a2 ctr / amid testpt)
  (setq amid   (erarq:angle-mid-ccw a1 a2))
  (setq testpt (erarq:polar-pt p amid 1.0))
  (< (distance testpt ctr) (distance p ctr))
)

(defun erarq:choose-internal-arc-angles (pPrev p pNext ctr / aPrev aNext)
  (setq aPrev (erarq:ang-norm (angle p pPrev)))
  (setq aNext (erarq:ang-norm (angle p pNext)))

  (if (erarq:angle-side-facing-centroid-p p aPrev aNext ctr)
    (list aPrev aNext)
    (list aNext aPrev)
  )
)

(defun erarq:internal-angle-deg-directed (pPrev p pNext ctr / aa a1 a2)
  (setq aa (erarq:choose-internal-arc-angles pPrev p pNext ctr))
  (setq a1 (car aa))
  (setq a2 (cadr aa))
  (* 180.0 (/ (erarq:angle-diff-ccw a1 a2) pi))
)

(defun erarq:internal-angle-text-point (pPrev p pNext ctr fac / aa a1 a2 amid)
  (setq aa   (erarq:choose-internal-arc-angles pPrev p pNext ctr))
  (setq a1   (car aa))
  (setq a2   (cadr aa))
  (setq amid (erarq:angle-mid-ccw a1 a2))
  (erarq:polar-pt p amid fac)
)

(defun erarq:internal-angle-text-rotation (pPrev p pNext ctr / aa a1 a2 amid rot)
  (setq aa   (erarq:choose-internal-arc-angles pPrev p pNext ctr))
  (setq a1   (car aa))
  (setq a2   (cadr aa))
  (setq amid (erarq:angle-mid-ccw a1 a2))
  (setq rot (- amid (/ pi 2.0)))
  (erarq:angle-readable rot)
)

(defun erarq:draw-angle-arc-internal (pPrev p pNext ctr rad lay / aa a1 a2)
  (setq aa (erarq:choose-internal-arc-angles pPrev p pNext ctr))
  (setq a1 (car aa))
  (setq a2 (cadr aa))

  (entmakex
    (list
      '(0 . "ARC")
      '(100 . "AcDbEntity")
      (cons 8 lay)
      '(100 . "AcDbCircle")
      (cons 10 (list (car p) (cadr p) 0.0))
      (cons 40 rad)
      '(100 . "AcDbArc")
      (cons 50 a1)
      (cons 51 a2)
    )
  )
)

(defun erarq:azimuth-deg (p1 p2)
  (erarq:rad->deg (erarq:azimuth-rad p1 p2))
)

; ============================================================
; DIBUJO DE TEXTO AUXILIAR
; ============================================================

(defun erarq:draw-text-rot (pt txt hgt rot lay)
  (erarq:layer-ensure-safe lay)
  (entmakex
    (list
      '(0 . "TEXT")
      '(100 . "AcDbEntity")
      (cons 8 lay)
      '(100 . "AcDbText")
      (cons 10 pt)
      (cons 11 pt)
      (cons 40 hgt)
      (cons 1 txt)
      (cons 7 "Standard")
      (cons 50 rot)
      (cons 72 1)
      (cons 73 2)
    )
  )
)

(defun erarq:draw-mtext-center (pt width txt hgt lay)
  (erarq:layer-ensure-safe lay)
  (entmakex
    (list
      '(0 . "MTEXT")
      '(100 . "AcDbEntity")
      (cons 8 lay)
      '(100 . "AcDbMText")
      (cons 10 pt)
      (cons 40 hgt)
      (cons 41 width)
      (cons 71 5)
      (cons 1 txt)
      (cons 7 "Standard")
    )
  )
)

; ============================================================
; APOYO OBJETO
; ============================================================

(defun erarq:set-object-layer (obj lay)
  (if (and obj lay (/= lay ""))
    (progn
      (erarq:layer-ensure-safe lay)
      (vla-put-Layer obj lay)
    )
  )
)

(defun erarq:draw-distances-on-object (obj lay / pts ctr i p1 p2 pt txt rot)
  (if obj
    (progn
      (setq pts (erarq:get-vertices obj))
      (setq ctr (erarq:polygon-centroid pts))
      (setq i   0)

      (while (< i (length pts))
        (setq p1 (nth i pts))
        (setq p2 (nth (if (= i (1- (length pts))) 0 (1+ i)) pts))

        (setq pt
          (erarq:side-text-point
            p1 p2 ctr
            0.0
            (* *erarq-small-text-height* 1.20)
            T
          )
        )

        (setq txt (erarq:num->str (distance p1 p2) *erarq-dec-dist*))
        (setq rot (erarq:angle-readable (angle p1 p2)))

        (erarq:draw-text-rot pt txt *erarq-small-text-height* rot lay)
        (setq i (1+ i))
      )
    )
  )
)

(defun erarq:draw-rumbos-on-object (obj lay / pts ctr i p1 p2 pt rumbo az rot)
  (if obj
    (progn
      (setq pts (erarq:get-vertices obj))
      (setq ctr (erarq:polygon-centroid pts))
      (setq i   0)

      (while (< i (length pts))
        (setq p1 (nth i pts))
        (setq p2 (nth (if (= i (1- (length pts))) 0 (1+ i)) pts))

        (setq pt
          (erarq:side-text-point
            p1 p2 ctr
            0.0
            (* *erarq-small-text-height* 2.30)
            T
          )
        )

        (setq az    (erarq:azimuth-deg p1 p2))
        (setq rumbo (erarq:azimuth-to-rumbo az))
        (setq rot   (erarq:angle-readable (angle p1 p2)))

        (erarq:draw-text-rot pt rumbo *erarq-small-text-height* rot lay)
        (setq i (1+ i))
      )
    )
  )
)

(defun erarq:draw-angles-on-object (obj lay / pts ctr i pPrev p pNext txtPt ang arcRad txtFac rot)
  (if obj
    (progn
      (setq pts (erarq:get-vertices obj))
      (setq ctr (erarq:polygon-centroid pts))
      (setq i   0)

      (setq arcRad (* *erarq-small-text-height* 1.40))
      (setq txtFac (* *erarq-small-text-height* 2.40))

      (while (< i (length pts))
        (setq pPrev (nth (if (= i 0) (1- (length pts)) (1- i)) pts))
        (setq p     (nth i pts))
        (setq pNext (nth (if (= i (1- (length pts))) 0 (1+ i)) pts))

        (setq ang   (erarq:internal-angle-deg-directed pPrev p pNext ctr))
        (setq txtPt (erarq:internal-angle-text-point pPrev p pNext ctr txtFac))
        (setq rot   (erarq:internal-angle-text-rotation pPrev p pNext ctr))

        (erarq:draw-angle-arc-internal pPrev p pNext ctr arcRad lay)

        (erarq:draw-text-rot
          txtPt
          (erarq:deg->dms-str ang)
          *erarq-small-text-height*
          rot
          lay
        )

        (setq i (1+ i))
      )
    )
  )
)

(defun erarq:draw-area-perim-on-object (obj lotName lay / pts ctr area per txt)
  (if obj
    (progn
      (setq pts  (erarq:get-vertices obj))
      (setq ctr  (erarq:polygon-centroid pts))
      (setq area (erarq:obj-area obj))
      (setq per  (erarq:obj-perimeter obj))

      (setq txt lotName)

      (if *erarq-draw-area*
        (setq txt
          (strcat txt "\\P" "Area: " (erarq:num->str area *erarq-dec-area*) " m2")
        )
      )

      (if *erarq-draw-perim*
        (setq txt
          (strcat txt "\\P" "Perimetro: " (erarq:num->str per *erarq-dec-dist*) " m")
        )
      )

      (erarq:draw-mtext-center
        ctr
        (* *erarq-text-height* 25.0)
        txt
        *erarq-text-height*
        lay
      )
    )
  )
)

; ============================================================
; DOCUMENTACION DE PARCELA
; ============================================================

(defun erarq:parcel-doc-command (/ obj)
  (setq obj (erarq:get-lwpoly-object))
  (if obj
    (progn
      (erarq:start-undo)
      (erarq:ensure-base-layers)
      (erarq:set-object-layer obj (erarq:layer-parcela))

      (if *erarq-doc-vertices-parcel*
        (erarq:label-vertices-on-object obj)
      )

      (if *erarq-draw-distances*
        (erarq:draw-distances-on-object obj (erarq:layer-parcela-dist))
      )

      (if *erarq-draw-angles*
        (erarq:draw-angles-on-object obj (erarq:layer-parcela-ang))
      )

      (if *erarq-doc-rumbos-parcel*
        (erarq:draw-rumbos-on-object obj (erarq:layer-parcela-rumbo))
      )

      (if (or *erarq-draw-area* *erarq-draw-perim*)
        (erarq:draw-area-perim-on-object
          obj
          *erarq-parcel-name*
          (erarq:layer-parcela-txt)
        )
      )

      (erarq:end-undo)
    )
  )
  (princ)
)

; ============================================================
; DOCUMENTACION DE LOTES
; ============================================================

(defun erarq:draw-lot-distances (objs / n)
  (if (and *erarq-draw-distances* objs)
    (progn
      (setq n *erarq-start-number*)
      (foreach o objs
        (erarq:ensure-lot-layers n)
        (erarq:draw-distances-on-object o (erarq:layer-lote-dist n))
        (setq n (1+ n))
      )
    )
  )
)

(defun erarq:draw-lot-rumbos (objs / n)
  (if (and *erarq-doc-rumbos-lots* objs)
    (progn
      (setq n *erarq-start-number*)
      (foreach o objs
        (erarq:ensure-lot-layers n)
        (erarq:draw-rumbos-on-object o (erarq:layer-lote-rumbo n))
        (setq n (1+ n))
      )
    )
  )
)

(defun erarq:draw-lot-angles (objs / n)
  (if (and *erarq-draw-angles* objs)
    (progn
      (setq n *erarq-start-number*)
      (foreach o objs
        (erarq:ensure-lot-layers n)
        (erarq:draw-angles-on-object o (erarq:layer-lote-ang n))
        (setq n (1+ n))
      )
    )
  )
)

(defun erarq:draw-lot-area-perim (objs / n)
  (if objs
    (progn
      (setq n *erarq-start-number*)
      (foreach o objs
        (erarq:ensure-lot-layers n)
        (erarq:draw-area-perim-on-object
          o
          (strcat *erarq-lot-prefix* (itoa n))
          (erarq:layer-lote-area n)
        )
        (setq n (1+ n))
      )
    )
  )
)

(defun erarq:lots-doc-command (/ objs oldSilent r)
  (setq objs (erarq:get-selected-lot-objects-in-order))

  (if objs
    (progn
      (setq oldSilent (if (boundp '*erarq-msg-silent*) *erarq-msg-silent* nil))
      (setq *erarq-msg-silent* T)

      (setq r
        (vl-catch-all-apply
          '(lambda ()
             (erarq:start-undo)

             (if *erarq-doc-number-lots*
               (erarq:number-lots-on-list objs)
             )

             (if *erarq-doc-vertices-lots*
               (erarq:label-lot-vertices-on-list objs)
             )

             (if *erarq-draw-distances*
               (erarq:draw-lot-distances objs)
             )

             (if *erarq-draw-angles*
               (erarq:draw-lot-angles objs)
             )

             (if *erarq-doc-rumbos-lots*
               (erarq:draw-lot-rumbos objs)
             )

             (if (or *erarq-draw-area* *erarq-draw-perim*)
               (erarq:draw-lot-area-perim objs)
             )

             (erarq:end-undo)
           )
        )
      )

      (setq *erarq-msg-silent* oldSilent)

      (if (vl-catch-all-error-p r)
        (prompt
          (strcat
            "\nError documentando lotes: "
            (vl-catch-all-error-message r)
          )
        )
        (if (and (erarq:fn-exists-p 'erarq:msg) (not *erarq-msg-silent*))
          (erarq:msg "Lotes documentados con una sola seleccion y en el orden exacto de seleccion.")
        )
      )
    )
    (prompt "\nNo se seleccionaron lotes.")
  )

  (princ)
)

(princ)