(vl-load-com)

; ============================================================
; COMPATIBILIDAD / AYUDAS
; ============================================================

(defun erarq:fn-exists-p (sym)
  (and sym
       (= (type sym) 'SYM)
       (not
         (vl-catch-all-error-p
           (vl-catch-all-apply 'eval (list sym))
         )
       )
       (member (type (eval sym)) '(SUBR USUBR EXRXSUBR))
  )
)

(defun erarq:tbl-ensure-layer-call (lay)
  (cond
    ((and lay (erarq:fn-exists-p 'erarq:layer-ensure))
      (erarq:layer-ensure lay)
    )
    ((and lay (erarq:fn-exists-p 'erarq:layer-ensure))
      (erarq:layer-ensure lay)
    )
    (T nil)
  )
)

(defun erarq:tbl-draw-line (p1 p2 lay)
  (erarq:tbl-ensure-layer-call lay)
  (entmakex
    (list
      '(0 . "LINE")
      (cons 8 lay)
      (cons 10 p1)
      (cons 11 p2)
    )
  )
)

(defun erarq:table-current-small-h ()
  (if (and (boundp '*erarq-table-small-h*) *erarq-table-small-h* (> *erarq-table-small-h* 0.0))
    *erarq-table-small-h*
    *erarq-small-text-height*
  )
)

(defun erarq:table-current-title-h ()
  (if (and (boundp '*erarq-table-title-h*) *erarq-table-title-h* (> *erarq-table-title-h* 0.0))
    *erarq-table-title-h*
    *erarq-title-text-height*
  )
)

(defun erarq:table-scale-factor (n)
  (cond
    ((<= n 12) 1.00)
    ((<= n 18) 0.95)
    ((<= n 25) 0.90)
    ((<= n 35) 0.84)
    ((<= n 50) 0.76)
    (T         0.68)
  )
)

(defun erarq:table-apply-scale (n / sf tf)
  (setq sf (erarq:table-scale-factor n))
  (setq tf (+ 0.15 (* sf 0.85))) ; el titulo reduce menos
  (setq *erarq-table-small-h* (* *erarq-small-text-height* sf))
  (setq *erarq-table-title-h* (* *erarq-title-text-height* tf))
)

(defun erarq:text-line-count (txt / pos start count)
  (setq count 1)
  (setq start 0)
  (if (null txt)
    (setq txt "")
  )
  (while (setq pos (vl-string-search "\\P" txt start))
    (setq count (1+ count))
    (setq start (+ pos 2))
  )
  count
)

; ============================================================
; BASICAS
; ============================================================

(defun erarq:sum-list (lst / s)
  (setq s 0.0)
  (foreach n lst
    (setq s (+ s n))
  )
  s
)

(defun erarq:segment-distance (p1 p2)
  (distance p1 p2)
)

(defun erarq:azimuth-rad (p1 p2 / dx dy ang)
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (setq ang (atan dy dx))
  (if (< ang 0.0)
    (+ ang (* 2.0 pi))
    ang
  )
)

(defun erarq:rad->deg (a)
  (* 180.0 (/ a pi))
)

(defun erarq:deg->dms-str (ang / dd m mm s ss)
  (setq dd (fix ang))
  (setq m (* (- ang dd) 60.0))
  (setq mm (fix m))
  (setq s (* (- m mm) 60.0))
  (setq ss (fix (+ s 0.5)))

  (if (= ss 60)
    (progn
      (setq ss 0)
      (setq mm (1+ mm))
    )
  )

  (if (= mm 60)
    (progn
      (setq mm 0)
      (setq dd (1+ dd))
    )
  )

  (strcat (itoa dd) "°" (itoa mm) "'" (itoa ss) "\"")
)

(defun erarq:azimuth-to-rumbo (angDeg / a beta)
  (setq a angDeg)
  (cond
    ((and (>= a 0.0) (< a 90.0))
      (setq beta a)
      (strcat "N " (erarq:deg->dms-str beta) " E")
    )
    ((and (>= a 90.0) (< a 180.0))
      (setq beta (- 180.0 a))
      (strcat "S " (erarq:deg->dms-str beta) " E")
    )
    ((and (>= a 180.0) (< a 270.0))
      (setq beta (- a 180.0))
      (strcat "S " (erarq:deg->dms-str beta) " W")
    )
    (T
      (setq beta (- 360.0 a))
      (strcat "N " (erarq:deg->dms-str beta) " W")
    )
  )
)

(defun erarq:polygon-area-hectares (a)
  (/ a 10000.0)
)

(defun erarq:vertex-label (n)
  (strcat *erarq-vertex-prefix* (itoa n))
)

(defun erarq:side-label (i n / a b)
  (setq a (erarq:vertex-label i))
  (setq b (erarq:vertex-label (if (= i n) 1 (1+ i))))
  (strcat a "-" b)
)

; ============================================================
; ANGULO INTERNO PARA TABLA
; ============================================================

(defun erarq:tbl-clamp (v a b)
  (max a (min b v))
)

(defun erarq:tbl-vsub (a b)
  (list (- (car a) (car b))
        (- (cadr a) (cadr b))
        0.0)
)

(defun erarq:tbl-vdot (a b)
  (+ (* (car a) (car b))
     (* (cadr a) (cadr b)))
)

(defun erarq:tbl-vlen (v)
  (sqrt (+ (* (car v) (car v))
           (* (cadr v) (cadr v))))
)

(defun erarq:tbl-vunit (v / l)
  (setq l (erarq:tbl-vlen v))
  (if (> l 1e-12)
    (list (/ (car v) l) (/ (cadr v) l) 0.0)
    '(0.0 0.0 0.0)
  )
)

(defun erarq:tbl-acos-safe (x / v)
  (setq v (erarq:tbl-clamp x -1.0 1.0))
  (atan (sqrt (max 0.0 (- 1.0 (* v v)))) v)
)

(defun erarq:internal-angle-deg-table (pPrev p pNext / v1 v2 c)
  (setq v1 (erarq:tbl-vunit (erarq:tbl-vsub pPrev p)))
  (setq v2 (erarq:tbl-vunit (erarq:tbl-vsub pNext p)))
  (setq c  (erarq:tbl-clamp (erarq:tbl-vdot v1 v2) -1.0 1.0))
  (* 180.0 (/ (erarq:tbl-acos-safe c) pi))
)

; ============================================================
; MTEXT / CELDAS / TITULOS
; ============================================================

(defun erarq:make-mtext (pt w txt lay att hgt / e)
  (erarq:tbl-ensure-layer-call lay)
  (setq e
    (entmakex
      (list
        '(0 . "MTEXT")
        '(100 . "AcDbEntity")
        (cons 8 lay)
        '(100 . "AcDbMText")
        (cons 10 pt)
        (cons 40 hgt)
        (cons 41 w)
        (cons 71 att)
        (cons 72 5)
        (cons 1 txt)
        (cons 7 "Standard")
      )
    )
  )
  e
)

(defun erarq:cell-center (x y w h)
  (list
    (+ x (/ w 2.0))
    (- y (/ h 2.0))
    0.0
  )
)

(defun erarq:draw-cell-text-center (x y w h txt lay / pt)
  (setq pt (erarq:cell-center x y w h))
  (erarq:make-mtext pt (* w 0.88) txt lay 5 (erarq:table-current-small-h))
)

(defun erarq:draw-cell-text-left (x y w h txt lay / pt)
  (setq pt
    (list
      (+ x (* (erarq:table-current-small-h) 0.40))
      (- y (/ h 2.0))
      0.0
    )
  )
  (erarq:make-mtext pt (* w 0.84) txt lay 4 (erarq:table-current-small-h))
)

(defun erarq:draw-table-title-block (ins totalw title1 title2 lay / x y h1 h2 titleH smallH n2 totalH)
  (setq x (car ins))
  (setq y (cadr ins))
  (setq titleH (erarq:table-current-title-h))
  (setq smallH (erarq:table-current-small-h))
  (setq n2 (erarq:text-line-count title2))

  (setq h1 (* titleH 1.70))
  (setq h2 (* smallH (+ 1.80 (* (1- n2) 1.30))))
  (setq totalH (+ h1 h2))

  ; marco
  (erarq:tbl-draw-line (list x y 0.0) (list (+ x totalw) y 0.0) lay)
  (erarq:tbl-draw-line (list (+ x totalw) y 0.0) (list (+ x totalw) (- y totalH) 0.0) lay)
  (erarq:tbl-draw-line (list (+ x totalw) (- y totalH) 0.0) (list x (- y totalH) 0.0) lay)
  (erarq:tbl-draw-line (list x (- y totalH) 0.0) (list x y 0.0) lay)

  ; separador
  (erarq:tbl-draw-line
    (list x (- y h1) 0.0)
    (list (+ x totalw) (- y h1) 0.0)
    lay
  )

  ; titulo principal
  (erarq:make-mtext
    (list (+ x (/ totalw 2.0)) (- y (/ h1 2.0)) 0.0)
    (* totalw 0.95)
    title1
    lay
    5
    titleH
  )

  ; subtitulo multilínea
  (erarq:make-mtext
    (list (+ x (/ totalw 2.0)) (- y h1 (/ h2 2.0)) 0.0)
    (* totalw 0.95)
    title2
    lay
    5
    (* smallH 1.02)
  )

  (- y totalH)
)

(defun erarq:draw-table-grid-pro (x y totalw totalrows rowh lay / bottom)
  (setq bottom (- y (* rowh totalrows)))

  (erarq:tbl-draw-line (list x y 0.0) (list (+ x totalw) y 0.0) lay)
  (erarq:tbl-draw-line (list (+ x totalw) y 0.0) (list (+ x totalw) bottom 0.0) lay)
  (erarq:tbl-draw-line (list (+ x totalw) bottom 0.0) (list x bottom 0.0) lay)
  (erarq:tbl-draw-line (list x bottom 0.0) (list x y 0.0) lay)
)

(defun erarq:draw-table-stable-pro (ins headers rows widths lay / x y rowh totalw totalrows r c colx cellw rowY)
  (setq x (car ins))
  (setq y (cadr ins))
  (setq rowh (* (erarq:table-current-small-h) 2.85))
  (setq totalw (erarq:sum-list widths))
  (setq totalrows (1+ (length rows)))

  (erarq:draw-table-grid-pro x y totalw totalrows rowh lay)

  ; horizontales
  (setq r 1)
  (repeat (1- totalrows)
    (erarq:tbl-draw-line
      (list x (- y (* rowh r)) 0.0)
      (list (+ x totalw) (- y (* rowh r)) 0.0)
      lay
    )
    (setq r (1+ r))
  )

  ; verticales
  (setq colx x)
  (setq c 0)
  (repeat (1- (length widths))
    (setq colx (+ colx (nth c widths)))
    (erarq:tbl-draw-line
      (list colx y 0.0)
      (list colx (- y (* rowh totalrows)) 0.0)
      lay
    )
    (setq c (1+ c))
  )

  ; encabezados
  (setq colx x)
  (setq c 0)
  (foreach h headers
    (setq cellw (nth c widths))
    (erarq:draw-cell-text-center colx y cellw rowh h lay)
    (setq colx (+ colx cellw))
    (setq c (1+ c))
  )

  ; datos
  (setq r 0)
  (foreach row rows
    (setq rowY (- y (* rowh (1+ r))))
    (setq colx x)
    (setq c 0)

    (foreach cell row
      (setq cellw (nth c widths))
      (erarq:draw-cell-text-center colx rowY cellw rowh cell lay)
      (setq colx (+ colx cellw))
      (setq c (1+ c))
    )

    (setq r (1+ r))
  )

  (list totalw rowh totalrows)
)

(defun erarq:draw-summary-block (pt area ha per lay / h lead w p1 p2 p3)
  (setq h    (erarq:table-current-small-h))
  (setq lead (* h 1.70))
  (setq w    (* h 22.0))

  (setq p1 pt)
  (setq p2 (list (car pt) (- (cadr pt) lead) 0.0))
  (setq p3 (list (car pt) (- (cadr pt) (* lead 2.0)) 0.0))

  (erarq:make-mtext
    p1 w
    (strcat "Area: " (erarq:num->str area *erarq-dec-area*) " m2")
    lay 1 h
  )

  (erarq:make-mtext
    p2 w
    (strcat "Hectareas: " (rtos ha 2 2) " ha")
    lay 1 h
  )

  (erarq:make-mtext
    p3 w
    (strcat "Perimetro: " (erarq:num->str per *erarq-dec-dist*) " m")
    lay 1 h
  )
)

; ============================================================
; ESPECIFICACION DE TABLAS
; ============================================================

(defun erarq:table-type-spec (/ h)
  (setq h (erarq:table-current-small-h))

  (cond
    ((= *erarq-table-type* "Simple")
      (if *erarq-include-eastnorth*
        (list
          '("VERTICE" "ESTE" "NORTE")
          (list
            (* h 6.3)
            (* h 13.0)
            (* h 13.0)
          )
        )
        (list
          '("VERTICE")
          (list
            (* h 6.5)
          )
        )
      )
    )

    ((= *erarq-table-type* "Rumbos")
      (if *erarq-include-eastnorth*
        (list
          '("VERTICE" "LADO" "DIST." "RUMBO" "ESTE" "NORTE")
          (list
            (* h 6.3)
            (* h 8.8)
            (* h 7.2)
            (* h 14.5)
            (* h 13.0)
            (* h 13.0)
          )
        )
        (list
          '("VERTICE" "LADO" "DIST." "RUMBO")
          (list
            (* h 6.3)
            (* h 8.8)
            (* h 7.2)
            (* h 14.5)
          )
        )
      )
    )

    ((= *erarq-table-type* "Angulos")
      (if *erarq-include-eastnorth*
        (list
          '("VERTICE" "LADO" "DIST." "ANGULO" "ESTE" "NORTE")
          (list
            (* h 6.3)
            (* h 8.8)
            (* h 7.2)
            (* h 12.0)
            (* h 13.0)
            (* h 13.0)
          )
        )
        (list
          '("VERTICE" "LADO" "DIST." "ANGULO")
          (list
            (* h 6.3)
            (* h 8.8)
            (* h 7.2)
            (* h 12.0)
          )
        )
      )
    )

    (T
      (if *erarq-include-eastnorth*
        (list
          '("VERTICE" "LADO" "DIST." "ANGULO" "RUMBO" "ESTE" "NORTE")
          (list
            (* h 6.3)
            (* h 8.8)
            (* h 7.2)
            (* h 12.0)
            (* h 14.5)
            (* h 13.0)
            (* h 13.0)
          )
        )
        (list
          '("VERTICE" "LADO" "DIST." "ANGULO" "RUMBO")
          (list
            (* h 6.3)
            (* h 8.8)
            (* h 7.2)
            (* h 12.0)
            (* h 14.5)
          )
        )
      )
    )
  )
)

(defun erarq:table-row-for-side (pts i n / pPrev p1 p2 dist azDeg angTxt rumboTxt)
  (setq pPrev (nth (if (= i 1) (1- n) (- i 2)) pts))
  (setq p1    (nth (1- i) pts))
  (setq p2    (nth (if (= i n) 0 i) pts))

  (setq dist     (erarq:segment-distance p1 p2))
  (setq azDeg    (erarq:rad->deg (erarq:azimuth-rad p1 p2)))
  (setq angTxt   (erarq:deg->dms-str (erarq:internal-angle-deg-table pPrev p1 p2)))
  (setq rumboTxt (erarq:azimuth-to-rumbo azDeg))

  (cond
    ((= *erarq-table-type* "Simple")
      (if *erarq-include-eastnorth*
        (list
          (erarq:vertex-label i)
          (erarq:num->str (car p1) *erarq-dec-coord*)
          (erarq:num->str (cadr p1) *erarq-dec-coord*)
        )
        (list
          (erarq:vertex-label i)
        )
      )
    )

    ((= *erarq-table-type* "Rumbos")
      (if *erarq-include-eastnorth*
        (list
          (erarq:vertex-label i)
          (erarq:side-label i n)
          (erarq:num->str dist *erarq-dec-dist*)
          rumboTxt
          (erarq:num->str (car p1) *erarq-dec-coord*)
          (erarq:num->str (cadr p1) *erarq-dec-coord*)
        )
        (list
          (erarq:vertex-label i)
          (erarq:side-label i n)
          (erarq:num->str dist *erarq-dec-dist*)
          rumboTxt
        )
      )
    )

    ((= *erarq-table-type* "Angulos")
      (if *erarq-include-eastnorth*
        (list
          (erarq:vertex-label i)
          (erarq:side-label i n)
          (erarq:num->str dist *erarq-dec-dist*)
          angTxt
          (erarq:num->str (car p1) *erarq-dec-coord*)
          (erarq:num->str (cadr p1) *erarq-dec-coord*)
        )
        (list
          (erarq:vertex-label i)
          (erarq:side-label i n)
          (erarq:num->str dist *erarq-dec-dist*)
          angTxt
        )
      )
    )

    (T
      (if *erarq-include-eastnorth*
        (list
          (erarq:vertex-label i)
          (erarq:side-label i n)
          (erarq:num->str dist *erarq-dec-dist*)
          angTxt
          rumboTxt
          (erarq:num->str (car p1) *erarq-dec-coord*)
          (erarq:num->str (cadr p1) *erarq-dec-coord*)
        )
        (list
          (erarq:vertex-label i)
          (erarq:side-label i n)
          (erarq:num->str dist *erarq-dec-dist*)
          angTxt
          rumboTxt
        )
      )
    )
  )
)

; ============================================================
; TABLA TECNICA / CONSTRUCCION
; ============================================================

(defun erarq:parcel-tech-table (/ obj pts n area per ha ins lay rows i spec headers widths gridY info rowh totalrows sumPt totalw oldSmall oldTitle)
  (if (setq obj (erarq:get-lwpoly-object))
    (progn
      (if (erarq:fn-exists-p 'erarq:ensure-base-layers)
        (erarq:ensure-base-layers)
      )

      (if (and (erarq:fn-exists-p 'erarq:layer-parcela) obj)
        (vla-put-Layer obj (erarq:layer-parcela))
      )

      (setq pts  (erarq:get-vertices obj))
      (setq n    (length pts))
      (setq area (erarq:obj-area obj))
      (setq per  (erarq:obj-perimeter obj))
      (setq ha   (erarq:polygon-area-hectares area))
      (setq lay  (erarq:layer-tablas-tec))
      (setq rows '())

      (setq oldSmall (if (boundp '*erarq-table-small-h*) *erarq-table-small-h* nil))
      (setq oldTitle (if (boundp '*erarq-table-title-h*) *erarq-table-title-h* nil))
      (erarq:table-apply-scale n)

      (setq i 1)
      (while (<= i n)
        (setq rows (append rows (list (erarq:table-row-for-side pts i n))))
        (setq i (1+ i))
      )

      (setq spec    (erarq:table-type-spec))
      (setq headers (car spec))
      (setq widths  (cadr spec))
      (setq totalw  (erarq:sum-list widths))

      (if *erarq-draw-tables*
        (progn
          (setq ins (getpoint "\nPunto de insercion para tabla tecnica: "))
          (if ins
            (progn
              (setq gridY
                (erarq:draw-table-title-block
                  ins
                  totalw
                  *erarq-table-title*
                  (strcat *erarq-parcel-name* "\\P" *erarq-coord-title*)
                  lay
                )
              )

              (setq info
                (erarq:draw-table-stable-pro
                  (list (car ins) gridY 0.0)
                  headers
                  rows
                  widths
                  lay
                )
              )

              (setq rowh      (nth 1 info))
              (setq totalrows (nth 2 info))

              (if *erarq-include-summary*
                (progn
                  (setq sumPt
                    (list
                      (car ins)
                      (- gridY (* rowh totalrows) (* (erarq:table-current-small-h) 2.4))
                      0.0
                    )
                  )
                  (erarq:draw-summary-block sumPt area ha per lay)
                )
              )
            )
          )
        )
      )

      (setq *erarq-table-small-h* oldSmall)
      (setq *erarq-table-title-h* oldTitle)
    )
  )
)

(defun erarq:table-construction ()
  (erarq:parcel-tech-table)
)

; ============================================================
; TABLA COORDENADAS
; ============================================================

(defun erarq:table-coordinates (/ obj pts ins rows i lay widths totalw gridY info rowh totalrows sumPt area per ha oldSmall oldTitle)
  (if (setq obj (erarq:get-lwpoly-object))
    (progn
      (if (erarq:fn-exists-p 'erarq:ensure-base-layers)
        (erarq:ensure-base-layers)
      )

      (setq pts (erarq:get-vertices obj))
      (setq rows '())
      (setq i 1)
      (setq lay (erarq:layer-tablas-coord))

      (setq oldSmall (if (boundp '*erarq-table-small-h*) *erarq-table-small-h* nil))
      (setq oldTitle (if (boundp '*erarq-table-title-h*) *erarq-table-title-h* nil))
      (erarq:table-apply-scale (length pts))

      (foreach p pts
        (setq rows
          (append rows
            (list
              (list
                (erarq:vertex-label i)
                (erarq:num->str (car p) *erarq-dec-coord*)
                (erarq:num->str (cadr p) *erarq-dec-coord*)
              )
            )
          )
        )
        (setq i (1+ i))
      )

      (setq widths
        (list
          (* (erarq:table-current-small-h) 6.3)
          (* (erarq:table-current-small-h) 13.0)
          (* (erarq:table-current-small-h) 13.0)
        )
      )
      (setq totalw (erarq:sum-list widths))

      (setq ins (getpoint "\nPunto de insercion para tabla de coordenadas: "))
      (if ins
        (progn
          (setq gridY
            (erarq:draw-table-title-block
              ins
              totalw
              "TABLA DE COORDENADAS"
              *erarq-parcel-name*
              lay
            )
          )

          (setq info
            (erarq:draw-table-stable-pro
              (list (car ins) gridY 0.0)
              '("VERTICE" "ESTE (X)" "NORTE (Y)")
              rows
              widths
              lay
            )
          )

          (if *erarq-include-summary*
            (progn
              (setq area (erarq:obj-area obj))
              (setq per  (erarq:obj-perimeter obj))
              (setq ha   (erarq:polygon-area-hectares area))
              (setq rowh      (nth 1 info))
              (setq totalrows (nth 2 info))
              (setq sumPt
                (list
                  (car ins)
                  (- gridY (* rowh totalrows) (* (erarq:table-current-small-h) 2.4))
                  0.0
                )
              )
              (erarq:draw-summary-block sumPt area ha per lay)
            )
          )
        )
      )

      (setq *erarq-table-small-h* oldSmall)
      (setq *erarq-table-title-h* oldTitle)
    )
  )
)

; ============================================================
; TABLA AREAS
; ============================================================

(defun erarq:table-areas (/ objs sorted ins rows n area per totalArea lay widths totalw gridY info oldSmall oldTitle cnt)
  (setq objs (erarq:ssget-closed-lwpolys))
  (if objs
    (progn
      (if (erarq:fn-exists-p 'erarq:ensure-base-layers)
        (erarq:ensure-base-layers)
      )

      (setq sorted (erarq:sort-objects-by-grid objs))
      (setq rows '())
      (setq n *erarq-start-number*)
      (setq totalArea 0.0)
      (setq lay (erarq:layer-tablas-area))

      (setq cnt (length sorted))
      (setq oldSmall (if (boundp '*erarq-table-small-h*) *erarq-table-small-h* nil))
      (setq oldTitle (if (boundp '*erarq-table-title-h*) *erarq-table-title-h* nil))
      (erarq:table-apply-scale (1+ cnt))

      (foreach o sorted
        (setq area (erarq:obj-area o))
        (setq per  (erarq:obj-perimeter o))
        (setq totalArea (+ totalArea area))

        (setq rows
          (append rows
            (list
              (list
                (strcat *erarq-lot-prefix* (itoa n))
                (erarq:num->str area *erarq-dec-area*)
                (erarq:num->str per *erarq-dec-dist*)
              )
            )
          )
        )
        (setq n (1+ n))
      )

      (setq rows
        (append rows
          (list
            (list
              "TOTAL"
              (erarq:num->str totalArea *erarq-dec-area*)
              "-"
            )
          )
        )
      )

      (setq widths
        (list
          (* (erarq:table-current-small-h) 7.5)
          (* (erarq:table-current-small-h) 12.0)
          (* (erarq:table-current-small-h) 13.0)
        )
      )
      (setq totalw (erarq:sum-list widths))

      (setq ins (getpoint "\nPunto de insercion para tabla de areas: "))
      (if ins
        (progn
          (setq gridY
            (erarq:draw-table-title-block
              ins
              totalw
              "TABLA DE AREAS"
              *erarq-project*
              lay
            )
          )

          (setq info
            (erarq:draw-table-stable-pro
              (list (car ins) gridY 0.0)
              '("LOTE" "AREA (m2)" "PERIMETRO (ml)")
              rows
              widths
              lay
            )
          )
        )
      )

      (setq *erarq-table-small-h* oldSmall)
      (setq *erarq-table-title-h* oldTitle)
    )
  )
)

(princ)