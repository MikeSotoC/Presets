(vl-load-com)

; ============================================================
; UTILIDADES BASICAS
; ============================================================

(defun erarq:last-elem (lst)
  (if (and lst (> (length lst) 0))
    (nth (1- (length lst)) lst)
  )
)

(defun erarq:v+ (a b)
  (list (+ (car a) (car b))
        (+ (cadr a) (cadr b))
        0.0)
)

(defun erarq:v- (a b)
  (list (- (car a) (car b))
        (- (cadr a) (cadr b))
        0.0)
)

(defun erarq:v* (v s)
  (list (* (car v) s)
        (* (cadr v) s)
        0.0)
)

(defun erarq:dot (a b)
  (+ (* (car a) (car b))
     (* (cadr a) (cadr b)))
)

(defun erarq:len (v)
  (sqrt (+ (* (car v) (car v))
           (* (cadr v) (cadr v))))
)

(defun erarq:unit (v / l)
  (setq l (erarq:len v))
  (if (> l 1e-14)
    (list (/ (car v) l)
          (/ (cadr v) l)
          0.0)
    '(0.0 0.0 0.0)
  )
)

(defun erarq:perp (v)
  (list (- (cadr v)) (car v) 0.0)
)

(defun erarq:minl (lst)
  (if lst (car (vl-sort lst '<)))
)

(defun erarq:maxl (lst)
  (if lst (car (vl-sort lst '>)))
)

(defun erarq:unique-sort (lst tol / sorted out x lastx)
  (setq sorted (vl-sort lst '<))
  (setq out nil)
  (foreach x sorted
    (if (null out)
      (setq out (list x))
      (progn
        (setq lastx (erarq:last-elem out))
        (if (> (abs (- x lastx)) tol)
          (setq out (append out (list x)))
        )
      )
    )
  )
  out
)

; ============================================================
; APOYO POLIGONOS
; ============================================================

(defun erarq:close-pts (pts / lastpt)
  (if pts
    (progn
      (setq lastpt (erarq:last-elem pts))
      (if (not (equal (car pts) lastpt 1e-9))
        (append pts (list (car pts)))
        pts
      )
    )
  )
)

(defun erarq:open-pts (pts / lastpt)
  (if (and pts (> (length pts) 1))
    (progn
      (setq lastpt (erarq:last-elem pts))
      (if (equal (car pts) lastpt 1e-9)
        (reverse (cdr (reverse pts)))
        pts
      )
    )
    pts
  )
)

(defun erarq:dedupe-near-pts (pts tol / out p)
  (setq out '())
  (foreach p pts
    (if (or (null out)
            (not (equal p (erarq:last-elem out) tol)))
      (setq out (append out (list p)))
    )
  )
  out
)

(defun erarq:get-ename-closed-lwpoly (/ ent ed)
  (setq ent (car (entsel "\nSeleccione una LWPOLYLINE cerrada: ")))
  (cond
    ((null ent) nil)
    ((/= (cdr (assoc 0 (entget ent))) "LWPOLYLINE")
      (prompt "\nDebe seleccionar una LWPOLYLINE.")
      nil
    )
    ((/= 1 (logand 1 (cdr (assoc 70 (entget ent)))))
      (prompt "\nLa polilinea debe estar cerrada.")
      nil
    )
    (T ent)
  )
)

(defun erarq:get-lwpoly-pts-ename (ename / ed pts rec)
  (setq ed (entget ename))
  (setq pts '())
  (if (= (cdr (assoc 0 ed)) "LWPOLYLINE")
    (progn
      (foreach rec ed
        (if (= (car rec) 10)
          (setq pts
            (append pts
              (list
                (list
                  (car (cdr rec))
                  (cadr (cdr rec))
                  0.0
                )
              )
            )
          )
        )
      )
    )
  )
  pts
)

(defun erarq:make-closed-lwpoly (pts lay / clean data)
  (setq clean (erarq:open-pts pts))
  (setq clean (erarq:dedupe-near-pts clean 1e-8))

  (if (and clean (> (length clean) 2))
    (progn
      (setq data
        (append
          (list
            '(0 . "LWPOLYLINE")
            '(100 . "AcDbEntity")
            (cons 8 lay)
            '(100 . "AcDbPolyline")
            (cons 90 (length clean))
            '(70 . 1)
          )
          (apply 'append
            (mapcar
              '(lambda (p)
                 (list (cons 10 (list (car p) (cadr p))))
               )
              clean
            )
          )
        )
      )
      (entmakex data)
    )
  )
)

(defun erarq:poly-area-signed (pts / lst i p q a)
  (setq lst (erarq:close-pts pts))
  (setq i 0)
  (setq a 0.0)
  (while (< i (1- (length lst)))
    (setq p (nth i lst))
    (setq q (nth (1+ i) lst))
    (setq a
      (+ a
         (- (* (car p) (cadr q))
            (* (car q) (cadr p)))
      )
    )
    (setq i (1+ i))
  )
  (/ a 2.0)
)

(defun erarq:poly-area (pts)
  (abs (erarq:poly-area-signed pts))
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

(defun erarq:poly-centroid (pts / lst i p q cross a cx cy)
  (setq lst (erarq:close-pts pts))
  (setq i 0)
  (setq a 0.0)
  (setq cx 0.0)
  (setq cy 0.0)

  (while (< i (1- (length lst)))
    (setq p (nth i lst))
    (setq q (nth (1+ i) lst))
    (setq cross (- (* (car p) (cadr q))
                   (* (car q) (cadr p))))
    (setq a (+ a cross))
    (setq cx (+ cx (* (+ (car p) (car q)) cross)))
    (setq cy (+ cy (* (+ (cadr p) (cadr q)) cross)))
    (setq i (1+ i))
  )

  (if (equal a 0.0 1e-12)
    (erarq:avg-centroid pts)
    (list (/ cx (* 3.0 a))
          (/ cy (* 3.0 a))
          0.0)
  )
)

; ============================================================
; INTERSECCION / CLIP
; ============================================================

(defun erarq:segment-line-intersection (a b s perp / fa fb ab tt)
  (setq fa (- (erarq:dot perp a) s))
  (setq fb (- (erarq:dot perp b) s))
  (cond
    ((and (< (abs fa) 1e-12) (< (abs fb) 1e-12)) nil)
    ((< (abs fa) 1e-12) a)
    ((< (abs fb) 1e-12) b)
    ((< (* fa fb) 0.0)
      (setq ab (erarq:v- b a))
      (setq tt (/ fa (- fa fb)))
      (erarq:v+ a (erarq:v* ab tt))
    )
    (T nil)
  )
)

(defun erarq:inside-left-p (p perp s tol)
  (<= (erarq:dot perp p) (+ s tol))
)

(defun erarq:inside-right-p (p perp s tol)
  (>= (erarq:dot perp p) (- s tol))
)

(defun erarq:clip-poly-left-of-line (pts perp s / tol input output i a b ina inb ip)
  (setq tol 1e-12)
  (setq input (erarq:close-pts pts))
  (setq output '())
  (setq i 0)

  (while (< i (1- (length input)))
    (setq a (nth i input))
    (setq b (nth (1+ i) input))
    (setq ina (erarq:inside-left-p a perp s tol))
    (setq inb (erarq:inside-left-p b perp s tol))

    (cond
      ((and ina inb)
        (setq output (append output (list b)))
      )
      ((and ina (not inb))
        (setq ip (erarq:segment-line-intersection a b s perp))
        (if ip
          (setq output (append output (list ip)))
        )
      )
      ((and (not ina) inb)
        (setq ip (erarq:segment-line-intersection a b s perp))
        (if ip
          (setq output (append output (list ip b)))
          (setq output (append output (list b)))
        )
      )
    )
    (setq i (1+ i))
  )

  (if (> (length output) 2)
    (erarq:close-pts (erarq:dedupe-near-pts output 1e-8))
    nil
  )
)

(defun erarq:clip-poly-right-of-line (pts perp s / tol input output i a b ina inb ip)
  (setq tol 1e-12)
  (setq input (erarq:close-pts pts))
  (setq output '())
  (setq i 0)

  (while (< i (1- (length input)))
    (setq a (nth i input))
    (setq b (nth (1+ i) input))
    (setq ina (erarq:inside-right-p a perp s tol))
    (setq inb (erarq:inside-right-p b perp s tol))

    (cond
      ((and ina inb)
        (setq output (append output (list b)))
      )
      ((and ina (not inb))
        (setq ip (erarq:segment-line-intersection a b s perp))
        (if ip
          (setq output (append output (list ip)))
        )
      )
      ((and (not ina) inb)
        (setq ip (erarq:segment-line-intersection a b s perp))
        (if ip
          (setq output (append output (list ip b)))
          (setq output (append output (list b)))
        )
      )
    )
    (setq i (1+ i))
  )

  (if (> (length output) 2)
    (erarq:close-pts (erarq:dedupe-near-pts output 1e-8))
    nil
  )
)

(defun erarq:area-left-of-line (pts perp s / clipped)
  (setq clipped (erarq:clip-poly-left-of-line pts perp s))
  (if clipped
    (erarq:poly-area clipped)
    0.0
  )
)

(defun erarq:offset-range (pts perp / vals p)
  (setq vals '())
  (foreach p pts
    (setq vals (cons (erarq:dot perp p) vals))
  )
  (list (erarq:minl vals) (erarq:maxl vals))
)

(defun erarq:find-s-by-area-bisection (pts perp targetArea smin smax areaTol maxIter / lo hi mid amid iter)
  (setq lo smin)
  (setq hi smax)
  (setq iter 0)

  (while (< iter maxIter)
    (setq mid (/ (+ lo hi) 2.0))
    (setq amid (erarq:area-left-of-line pts perp mid))

    (if (<= (abs (- amid targetArea)) areaTol)
      (setq iter maxIter)
      (if (< amid targetArea)
        (setq lo mid)
        (setq hi mid)
      )
    )
    (setq iter (1+ iter))
  )

  (/ (+ lo hi) 2.0)
)

; ============================================================
; ETIQUETADO / REGISTRO
; ============================================================

(defun erarq:label-new-lot (pts idx / c txt)
  (if *erarq-draw-texts*
    (progn
      (erarq:ensure-lot-layers idx)
      (setq c (erarq:poly-centroid pts))
      (setq txt (strcat *erarq-lot-prefix* (itoa idx)))

      (entmakex
        (list
          '(0 . "TEXT")
          (cons 8 (erarq:layer-lote-txt idx))
          (cons 10 c)
          (cons 11 c)
          (cons 40 *erarq-text-height*)
          (cons 1 txt)
          (cons 7 "Standard")
          (cons 72 1)
          (cons 73 2)
        )
      )
    )
  )
)

(defun erarq:store-last-created-lots (enames)
  (setq *erarq-last-created-lot-enames* enames)
)

(defun erarq:get-last-created-lot-objects (/ out en)
  (setq out '())
  (if (and (boundp '*erarq-last-created-lot-enames*) *erarq-last-created-lot-enames*)
    (foreach en *erarq-last-created-lot-enames*
      (if (and en (entget en))
        (setq out (append out (list (vlax-ename->vla-object en))))
      )
    )
  )
  out
)

; ============================================================
; CREACION DE LOTES IGUALES
; ============================================================

(defun erarq:create-equal-lots-polys (pts n / current rem lot areaPoly eachArea p1 p2 dir perp rg smin smax areaTol maxIter k s e idx created en)
  (setq areaPoly (erarq:poly-area pts))
  (setq eachArea (/ areaPoly n))
  (setq current (erarq:close-pts pts))
  (setq created '())

  (prompt (strcat "\nArea total = " (rtos areaPoly 2 8)))
  (prompt (strcat "\nArea objetivo por lote = " (rtos eachArea 2 8)))

  (setq p1 (getpoint "\nPrimer punto de la direccion de corte: "))
  (if (null p1)
    nil
    (progn
      (setq p2 (getpoint p1 "\nSegundo punto de la direccion de corte: "))
      (if (null p2)
        nil
        (progn
          (setq dir (erarq:unit (erarq:v- p2 p1)))

          (if (< (erarq:len dir) 1e-12)
            (prompt "\nDireccion invalida.")
            (progn
              (setq perp (erarq:perp dir))

              (setq areaTol (getreal "\nTolerancia de area <0.000001>: "))
              (if (or (null areaTol) (<= areaTol 0.0))
                (setq areaTol 0.000001)
              )

              (setq maxIter (getint "\nMaximo de iteraciones <80>: "))
              (if (or (null maxIter) (< maxIter 10))
                (setq maxIter 80)
              )

              (setq k 0)
              (while (< k (1- n))
                (setq rg   (erarq:offset-range current perp))
                (setq smin (car rg))
                (setq smax (cadr rg))

                (setq s
                  (erarq:find-s-by-area-bisection
                    current
                    perp
                    eachArea
                    smin
                    smax
                    areaTol
                    maxIter
                  )
                )

                (setq lot (erarq:clip-poly-left-of-line current perp s))
                (setq rem (erarq:clip-poly-right-of-line current perp s))
                (setq idx (+ *erarq-start-number* k))

                (if (and lot rem)
                  (progn
                    (erarq:ensure-lot-layers idx)

                    (setq en (erarq:make-closed-lwpoly lot (erarq:layer-lote idx)))
                    (if en
                      (setq created (append created (list en)))
                    )

                    (setq e (erarq:poly-area lot))
                    (erarq:label-new-lot lot idx)

                    (prompt
                      (strcat
                        "\nLote "
                        (itoa idx)
                        " | Area = "
                        (rtos e 2 8)
                        " | Capa = "
                        (erarq:layer-lote idx)
                      )
                    )

                    (setq current rem)
                  )
                  (progn
                    (prompt "\nNo fue posible generar un corte valido.")
                    (setq k (1- n))
                    (setq current nil)
                  )
                )

                (setq k (1+ k))
              )

              (if current
                (progn
                  (setq idx (+ *erarq-start-number* (1- n)))
                  (erarq:ensure-lot-layers idx)

                  (setq en (erarq:make-closed-lwpoly current (erarq:layer-lote idx)))
                  (if en
                    (setq created (append created (list en)))
                  )

                  (setq e (erarq:poly-area current))
                  (erarq:label-new-lot current idx)

                  (prompt
                    (strcat
                      "\nLote "
                      (itoa idx)
                      " | Area = "
                      (rtos e 2 8)
                      " | Capa = "
                      (erarq:layer-lote idx)
                    )
                  )

                  (erarq:store-last-created-lots created)

                  (alert
                    (strcat
                      "Division completada.\n\n"
                      "Lotes generados: " (itoa n) "\n"
                      "Area total original: " (rtos areaPoly 2 *erarq-dec-area*) " m2\n"
                      "Area objetivo por lote: " (rtos eachArea 2 *erarq-dec-area*) " m2\n\n"
                      "Cada lote fue creado en su propia capa dinamica."
                    )
                  )

                  created
                )
              )
            )
          )
        )
      )
    )
  )
)

; ============================================================
; DIVISION POR AREA
; ============================================================

(defun erarq:division-por-area (pts areaObjetivo / areaPoly nreal n)
  (setq areaPoly (erarq:poly-area pts))

  (if (or (null areaObjetivo) (<= areaObjetivo 0.0))
    (prompt "\nArea objetivo invalida.")
    (progn
      (setq nreal (/ areaPoly areaObjetivo))
      (setq n (fix nreal))

      (if (< n 2)
        (alert
          (strcat
            "El area objetivo es demasiado grande para generar al menos 2 lotes.\n\n"
            "Area total: " (rtos areaPoly 2 *erarq-dec-area*) " m2"
          )
        )
        (progn
          (alert
            (strcat
              "Area total: " (rtos areaPoly 2 *erarq-dec-area*) " m2\n"
              "Area objetivo de referencia: " (rtos areaObjetivo 2 *erarq-dec-area*) " m2\n"
              "Se generaran " (itoa n) " lotes iguales."
            )
          )
          (erarq:create-equal-lots-polys pts n)
        )
      )
    )
  )
)

; ============================================================
; DIVISION BASE
; ============================================================

(defun erarq:division-exacta-base (/ ent pts mode n area)
  (setq ent (erarq:get-ename-closed-lwpoly))

  (if ent
    (progn
      (setq pts (erarq:get-lwpoly-pts-ename ent))

      (if (< (length pts) 3)
        (prompt "\nPoligono invalido.")
        (progn
          (initget "PorNumero PorArea")
          (setq mode (getkword "\nModo de division [PorNumero/PorArea] <PorNumero>: "))
          (if (null mode) (setq mode "PorNumero"))

          (cond
            ((= mode "PorNumero")
              (setq n (getint "\nNumero de lotes: "))
              (if (and n (> n 1))
                (erarq:create-equal-lots-polys pts n)
                (prompt "\nDebe indicar un numero mayor o igual a 2.")
              )
            )
            ((= mode "PorArea")
              (setq area (getreal "\nArea objetivo por lote: "))
              (if (and area (> area 0.0))
                (erarq:division-por-area pts area)
                (prompt "\nDebe indicar un area valida.")
              )
            )
          )
        )
      )
    )
  )
)

; ============================================================
; COMANDO
; ============================================================

(defun erarq:division-command ()
  (erarq:ensure-base-layers)
  (erarq:division-exacta-base)
  (princ)
)

(princ)