(vl-load-com)

; ============================================================
; UTILIDADES BASICAS
; ============================================================

(defun erarq:grid-v+ (a b)
  (list (+ (car a) (car b))
        (+ (cadr a) (cadr b))
        0.0)
)

(defun erarq:grid-v- (a b)
  (list (- (car a) (car b))
        (- (cadr a) (cadr b))
        0.0)
)

(defun erarq:grid-mid (p1 p2)
  (list (/ (+ (car p1) (car p2)) 2.0)
        (/ (+ (cadr p1) (cadr p2)) 2.0)
        0.0)
)

(defun erarq:grid-pt (x y)
  (list x y 0.0)
)

(defun erarq:grid-min (a b)
  (if (< a b) a b)
)

(defun erarq:grid-max (a b)
  (if (> a b) a b)
)

(defun erarq:grid-round-int (n)
  (fix (+ n (if (>= n 0.0) 0.5 -0.5)))
)

(defun erarq:grid-floor-step (v step / q)
  (setq q (/ v step))
  (if (>= q 0.0)
    (* step (fix q))
    (* step (1- (fix q)))
  )
)

(defun erarq:grid-ceil-step (v step / q f)
  (setq q (/ v step))
  (setq f (fix q))
  (if (= q f)
    (* step f)
    (if (> q 0.0)
      (* step (1+ f))
      (* step f)
    )
  )
)

(defun erarq:grid-format-int (n / s len)
  (setq s (itoa (abs (erarq:grid-round-int n))))
  (setq len (strlen s))

  (setq s
    (cond
      ((<= len 3) s)
      ((= len 4) (strcat (substr s 1 1) " " (substr s 2)))
      ((= len 5) (strcat (substr s 1 2) " " (substr s 3)))
      ((= len 6) (strcat (substr s 1 3) " " (substr s 4)))
      ((= len 7) (strcat (substr s 1 1) " " (substr s 2 3) " " (substr s 5)))
      ((= len 8) (strcat (substr s 1 2) " " (substr s 3 3) " " (substr s 6)))
      ((= len 9) (strcat (substr s 1 3) " " (substr s 4 3) " " (substr s 7)))
      ((= len 10) (strcat (substr s 1 1) " " (substr s 2 3) " " (substr s 5 3) " " (substr s 8)))
      (T s)
    )
  )

  (if (< n 0.0)
    (strcat "-" s)
    s
  )
)

(defun erarq:grid-multiple-p (value step / q)
  (if (and step (> step 0.0))
    (progn
      (setq q (/ value step))
      (< (abs (- q (float (erarq:grid-round-int q)))) 1e-8)
    )
    nil
  )
)

(defun erarq:grid-snap-rect (p1 p2 dx dy / x1 y1 x2 y2)
  (setq x1 (erarq:grid-floor-step (erarq:grid-min (car p1) (car p2)) dx))
  (setq y1 (erarq:grid-floor-step (erarq:grid-min (cadr p1) (cadr p2)) dy))
  (setq x2 (erarq:grid-ceil-step  (erarq:grid-max (car p1) (car p2)) dx))
  (setq y2 (erarq:grid-ceil-step  (erarq:grid-max (cadr p1) (cadr p2)) dy))

  (if (= x1 x2) (setq x2 (+ x2 dx)))
  (if (= y1 y2) (setq y2 (+ y2 dy)))

  (list (list x1 y1 0.0) (list x2 y2 0.0))
)

(defun erarq:grid-normalize-rect (p1 p2 / x1 y1 x2 y2)
  (setq x1 (erarq:grid-min (car p1) (car p2)))
  (setq y1 (erarq:grid-min (cadr p1) (cadr p2)))
  (setq x2 (erarq:grid-max (car p1) (car p2)))
  (setq y2 (erarq:grid-max (cadr p1) (cadr p2)))
  (list (list x1 y1 0.0) (list x2 y2 0.0))
)

(defun erarq:grid-first-inside-step (v step)
  (erarq:grid-ceil-step v step)
)

(defun erarq:grid-last-inside-step (v step)
  (erarq:grid-floor-step v step)
)

; ============================================================
; CAPAS DE GRILLA
; ============================================================

(defun erarq:grid-layer-minor ()
  (if (erarq:fn-exists-p 'erarq:layer-grid-minor)
    (erarq:layer-grid-minor)
    (if (erarq:fn-exists-p 'erarq:layer-grid)
      (erarq:layer-grid)
      "ERARQ_GRID"
    )
  )
)

(defun erarq:grid-layer-major ()
  (if (erarq:fn-exists-p 'erarq:layer-grid-major)
    (erarq:layer-grid-major)
    (erarq:grid-layer-minor)
  )
)

(defun erarq:grid-layer-master ()
  (if (erarq:fn-exists-p 'erarq:layer-grid-master)
    (erarq:layer-grid-master)
    (erarq:grid-layer-major)
  )
)

(defun erarq:grid-layer-border ()
  (if (erarq:fn-exists-p 'erarq:layer-grid-border)
    (erarq:layer-grid-border)
    (erarq:grid-layer-master)
  )
)

(defun erarq:grid-layer-txt ()
  (if (erarq:fn-exists-p 'erarq:layer-grid-txt)
    (erarq:layer-grid-txt)
    "ERARQ_GRID_TXT"
  )
)

(defun erarq:grid-line-layer (coord step / step5 step10)
  (setq step5  (* step 5.0))
  (setq step10 (* step 10.0))

  (cond
    ((erarq:grid-multiple-p coord step10) (erarq:grid-layer-master))
    ((erarq:grid-multiple-p coord step5)  (erarq:grid-layer-major))
    (T                                    (erarq:grid-layer-minor))
  )
)

; ============================================================
; ESTILO
; ============================================================

(defun erarq:grid-ensure-textstyle ()
  (if (null (tblsearch "STYLE" "GRID"))
    (command "_.STYLE" "GRID" "ROMAND" 0 1 0 "N" "N" "N")
  )
  (setvar "TEXTSTYLE" "GRID")
)

(defun erarq:grid-ensure-layers ()
  (if (erarq:fn-exists-p 'erarq:ensure-base-layers)
    (erarq:ensure-base-layers)
    (progn
      (if (erarq:fn-exists-p 'erarq:layer-setup)
        (progn
          (erarq:layer-setup (erarq:grid-layer-minor)  8 "Continuous" 13)
          (erarq:layer-setup (erarq:grid-layer-major)  8 "Continuous" 18)
          (erarq:layer-setup (erarq:grid-layer-master) 7 "Continuous" 25)
          (erarq:layer-setup (erarq:grid-layer-border) 7 "Continuous" 35)
          (erarq:layer-setup (erarq:grid-layer-txt)    9 "Continuous" 13)
        )
      )
    )
  )
)

; ============================================================
; DIBUJO BASICO
; ============================================================

(defun erarq:grid-draw-line (p1 p2 lay)
  (entmakex
    (list
      '(0 . "LINE")
      (cons 8 lay)
      (cons 10 p1)
      (cons 11 p2)
    )
  )
)

(defun erarq:grid-draw-text (pt txt hgt rot just lay)
  (entmakex
    (list
      '(0 . "TEXT")
      (cons 8 lay)
      (cons 10 pt)
      (cons 11 pt)
      (cons 40 hgt)
      (cons 1 txt)
      (cons 50 rot)
      (cons 7 "GRID")
      (cons 72
        (cond
          ((= just "L") 0)
          ((= just "C") 1)
          ((= just "R") 2)
          ((= just "TL") 0)
          ((= just "TR") 2)
          ((= just "ML") 0)
          ((= just "MR") 2)
          (T 0)
        )
      )
      (cons 73
        (cond
          ((= just "TL") 3)
          ((= just "TR") 3)
          ((= just "ML") 2)
          ((= just "MR") 2)
          (T 0)
        )
      )
    )
  )
)

; ============================================================
; BOUNDING BOX
; ============================================================

(defun erarq:grid-ss-bbox (ss / i en obj pmin pmax a b minx miny maxx maxy)
  (if (and ss (> (sslength ss) 0))
    (progn
      (setq i 0)
      (repeat (sslength ss)
        (setq en (ssname ss i))
        (setq obj (vlax-ename->vla-object en))
        (vla-getboundingbox obj 'a 'b)
        (setq pmin (vlax-safearray->list a))
        (setq pmax (vlax-safearray->list b))

        (if (= i 0)
          (progn
            (setq minx (car pmin))
            (setq miny (cadr pmin))
            (setq maxx (car pmax))
            (setq maxy (cadr pmax))
          )
          (progn
            (setq minx (min minx (car pmin)))
            (setq miny (min miny (cadr pmin)))
            (setq maxx (max maxx (car pmax)))
            (setq maxy (max maxy (cadr pmax)))
          )
        )
        (setq i (1+ i))
      )
      (list (list minx miny 0.0) (list maxx maxy 0.0))
    )
  )
)

(defun erarq:grid-rect-from-bbox (bbox dx dy / pmin pmax minx miny maxx maxy x1 y1 x2 y2)
  (setq pmin (car bbox))
  (setq pmax (cadr bbox))

  (setq minx (car pmin))
  (setq miny (cadr pmin))
  (setq maxx (car pmax))
  (setq maxy (cadr pmax))

  (setq x1 (erarq:grid-floor-step minx dx))
  (setq y1 (erarq:grid-floor-step miny dy))
  (setq x2 (erarq:grid-ceil-step  maxx dx))
  (setq y2 (erarq:grid-ceil-step  maxy dy))

  (if (= x1 x2) (setq x2 (+ x2 dx)))
  (if (= y1 y2) (setq y2 (+ y2 dy)))

  (list (list x1 y1 0.0) (list x2 y2 0.0))
)

; ============================================================
; RECTANGULO / GRILLA
; ============================================================

(defun erarq:grid-draw-rectangle (p1 p2 lay / x1 y1 x2 y2 a b c d)
  (setq x1 (erarq:grid-min (car p1) (car p2)))
  (setq y1 (erarq:grid-min (cadr p1) (cadr p2)))
  (setq x2 (erarq:grid-max (car p1) (car p2)))
  (setq y2 (erarq:grid-max (cadr p1) (cadr p2)))

  (setq a (erarq:grid-pt x1 y1))
  (setq b (erarq:grid-pt x2 y1))
  (setq c (erarq:grid-pt x2 y2))
  (setq d (erarq:grid-pt x1 y2))

  (erarq:grid-draw-line a b lay)
  (erarq:grid-draw-line b c lay)
  (erarq:grid-draw-line c d lay)
  (erarq:grid-draw-line d a lay)
)

(defun erarq:grid-draw-grid-lines (p1 p2 dx dy / x1 y1 x2 y2 x y lay xs ys)
  (setq x1 (erarq:grid-min (car p1) (car p2)))
  (setq y1 (erarq:grid-min (cadr p1) (cadr p2)))
  (setq x2 (erarq:grid-max (car p1) (car p2)))
  (setq y2 (erarq:grid-max (cadr p1) (cadr p2)))

  ;; verticales solo dentro del rectángulo
  (setq xs (erarq:grid-first-inside-step x1 dx))
  (setq x xs)
  (while (<= x (+ x2 1e-8))
    (setq lay (erarq:grid-line-layer x dx))
    (erarq:grid-draw-line
      (erarq:grid-pt x y1)
      (erarq:grid-pt x y2)
      lay
    )
    (setq x (+ x dx))
  )

  ;; horizontales solo dentro del rectángulo
  (setq ys (erarq:grid-first-inside-step y1 dy))
  (setq y ys)
  (while (<= y (+ y2 1e-8))
    (setq lay (erarq:grid-line-layer y dy))
    (erarq:grid-draw-line
      (erarq:grid-pt x1 y)
      (erarq:grid-pt x2 y)
      lay
    )
    (setq y (+ y dy))
  )
)

; ============================================================
; TEXTOS E/N
; ============================================================

(defun erarq:grid-draw-east-labels (p1 p2 dx hgt mode lay / x1 y1 x2 y2 x xs txt off justB justT ptB ptT)
  (setq x1 (erarq:grid-min (car p1) (car p2)))
  (setq y1 (erarq:grid-min (cadr p1) (cadr p2)))
  (setq x2 (erarq:grid-max (car p1) (car p2)))
  (setq y2 (erarq:grid-max (cadr p1) (cadr p2)))

  (setq off (* hgt 0.8))
  (setq x (erarq:grid-first-inside-step x1 dx))

  (while (<= x (+ x2 1e-8))
    (setq xs (erarq:grid-round-int x))
    (setq txt (strcat "E " (erarq:grid-format-int xs)))

    (if (= mode "E")
      (progn
        (setq ptB (erarq:grid-pt x (- y1 off)))
        (setq ptT (erarq:grid-pt x (+ y2 off)))
        (setq justB "MR")
        (setq justT "ML")
      )
      (progn
        (setq ptB (erarq:grid-pt (+ x off) (+ y1 off)))
        (setq ptT (erarq:grid-pt (+ x off) (- y2 off)))
        (setq justB "TL")
        (setq justT "TR")
      )
    )

    (erarq:grid-draw-text ptB txt hgt (/ pi 2.0) justB lay)
    (erarq:grid-draw-text ptT txt hgt (/ pi 2.0) justT lay)

    (setq x (+ x dx))
  )
)

(defun erarq:grid-draw-north-labels (p1 p2 dy hgt mode lay / x1 y1 x2 y2 y ys txt off justL justR ptL ptR)
  (setq x1 (erarq:grid-min (car p1) (car p2)))
  (setq y1 (erarq:grid-min (cadr p1) (cadr p2)))
  (setq x2 (erarq:grid-max (car p1) (car p2)))
  (setq y2 (erarq:grid-max (cadr p1) (cadr p2)))

  (setq off (* hgt 0.8))
  (setq y (erarq:grid-first-inside-step y1 dy))

  (while (<= y (+ y2 1e-8))
    (setq ys (erarq:grid-round-int y))
    (setq txt (strcat "N " (erarq:grid-format-int ys)))

    (if (= mode "E")
      (progn
        (setq ptL (erarq:grid-pt (- x1 off) y))
        (setq ptR (erarq:grid-pt (+ x2 off) y))
        (setq justL "MR")
        (setq justR "ML")
      )
      (progn
        (setq ptL (erarq:grid-pt (+ x1 off) (+ y off)))
        (setq ptR (erarq:grid-pt (- x2 off) (+ y off)))
        (setq justL "L")
        (setq justR "R")
      )
    )

    (erarq:grid-draw-text ptL txt hgt 0.0 justL lay)
    (erarq:grid-draw-text ptR txt hgt 0.0 justR lay)

    (setq y (+ y dy))
  )
)

; ============================================================
; CONFIG ACTIVA
; ============================================================

(defun erarq:grid-current-dx ()
  (if (and (boundp '*erarq-grid-dx*) *erarq-grid-dx* (> *erarq-grid-dx* 0.0))
    *erarq-grid-dx*
    10.0
  )
)

(defun erarq:grid-current-dy ()
  (if (and (boundp '*erarq-grid-dy*) *erarq-grid-dy* (> *erarq-grid-dy* 0.0))
    *erarq-grid-dy*
    (erarq:grid-current-dx)
  )
)

(defun erarq:grid-current-mode ()
  (if (and (boundp '*erarq-grid-mode*)
           (member *erarq-grid-mode* '("E" "I")))
    *erarq-grid-mode*
    "E"
  )
)

(defun erarq:grid-current-hgt ()
  (if (and (boundp '*erarq-text-height*) *erarq-text-height* (> *erarq-text-height* 0.0))
    *erarq-text-height*
    2.5
  )
)

; ============================================================
; DIBUJO COMUN
; ============================================================

(defun erarq:grid-draw-common (p1 p2 dx dy mode hgt snapRectP / oldsty rect sp1 sp2)
  (setq oldsty (getvar "TEXTSTYLE"))

  (setq rect
    (if snapRectP
      (erarq:grid-snap-rect p1 p2 dx dy)
      (erarq:grid-normalize-rect p1 p2)
    )
  )

  (setq sp1 (car rect))
  (setq sp2 (cadr rect))

  (erarq:grid-ensure-layers)
  (erarq:grid-ensure-textstyle)

  ;; marco exacto del rectángulo a usar
  (erarq:grid-draw-rectangle sp1 sp2 (erarq:grid-layer-border))

  ;; líneas internas recortadas al marco
  (erarq:grid-draw-grid-lines sp1 sp2 dx dy)

  ;; etiquetas solo para líneas realmente dibujadas
  (erarq:grid-draw-east-labels sp1 sp2 dx hgt mode (erarq:grid-layer-txt))
  (erarq:grid-draw-north-labels sp1 sp2 dy hgt mode (erarq:grid-layer-txt))

  (setvar "TEXTSTYLE" oldsty)
)

; ============================================================
; COMANDOS
; ============================================================

(defun erarq:grid-command (/ oldcmdecho oldos oldlay p1 p2 dx dy mode hgt)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setq oldos      (getvar "OSMODE"))
  (setq oldlay     (getvar "CLAYER"))

  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)

  (setq dx   (erarq:grid-current-dx))
  (setq dy   (erarq:grid-current-dy))
  (setq mode (erarq:grid-current-mode))
  (setq hgt  (erarq:grid-current-hgt))

  (setq p1 (getpoint "\nIngrese esquina inferior izquierda del rectangulo de grilla: "))
  (if p1
    (progn
      (setq p2 (getcorner p1 "\nIngrese esquina superior derecha del rectangulo de grilla: "))
      (if p2
        (progn
          ;; NIL = no expandir, respetar exactamente el rectángulo elegido
          (erarq:grid-draw-common p1 p2 dx dy mode hgt nil)
          (prompt "\nGrilla creada correctamente dentro del rectangulo seleccionado.")
        )
      )
    )
  )

  (setvar "CLAYER" oldlay)
  (setvar "OSMODE" oldos)
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)

(defun erarq:grid-auto-command (/ oldcmdecho oldos oldlay ss bbox rect p1 p2 dx dy mode hgt)
  (setq oldcmdecho (getvar "CMDECHO"))
  (setq oldos      (getvar "OSMODE"))
  (setq oldlay     (getvar "CLAYER"))

  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)

  (setq dx   (erarq:grid-current-dx))
  (setq dy   (erarq:grid-current-dy))
  (setq mode (erarq:grid-current-mode))
  (setq hgt  (erarq:grid-current-hgt))

  (prompt "\nSeleccione el poligono o dibujo para adaptar la grilla.")
  (setq ss (ssget))

  (if ss
    (progn
      (setq bbox (erarq:grid-ss-bbox ss))
      (if bbox
        (progn
          (setq rect (erarq:grid-rect-from-bbox bbox dx dy))
          (setq p1 (car rect))
          (setq p2 (cadr rect))

          ;; T = sí ajustar al paso en automático
          (erarq:grid-draw-common p1 p2 dx dy mode hgt t)
          (prompt "\nGrilla automatica creada con redondeo limpio al paso configurado.")
        )
        (prompt "\nNo fue posible calcular el rectangulo de la seleccion.")
      )
    )
    (prompt "\nNo se seleccionaron objetos.")
  )

  (setvar "CLAYER" oldlay)
  (setvar "OSMODE" oldos)
  (setvar "CMDECHO" oldcmdecho)
  (princ)
)

(defun c:ERARQ_GRID ()
  (erarq:grid-command)
)

(defun c:ERARQ_GRID_AUTO ()
  (erarq:grid-auto-command)
)

(princ)