(vl-load-com)

(defun erarq:export-coordinates-csv (/ obj pts area per path f i p)
  (if (setq obj (erarq:get-lwpoly-object))
    (progn
      (setq pts  (erarq:get-vertices obj))
      (setq area (erarq:obj-area obj))
      (setq per  (erarq:obj-perimeter obj))

      (setq path
        (getfiled
          "Guardar coordenadas CSV"
          (strcat *erarq-parcel-name* "_coordenadas.csv")
          "csv"
          1
        )
      )

      (if path
        (progn
          (setq f (open path "w"))
          (write-line (strcat "PROYECTO," *erarq-project*) f)
          (write-line (strcat "PARCELA," *erarq-parcel-name*) f)
          (write-line (strcat "VERTICES," (itoa (length pts))) f)
          (write-line (strcat "AREA_M2," (erarq:num->str area *erarq-dec-area*)) f)
          (write-line (strcat "PERIMETRO_ML," (erarq:num->str per *erarq-dec-dist*)) f)
          (write-line "" f)
          (write-line "ID,X,Y" f)

          (setq i 1)
          (foreach p pts
            (write-line
              (strcat
                "V" (itoa i) ","
                (erarq:num->str (car p) *erarq-dec-coord*) ","
                (erarq:num->str (cadr p) *erarq-dec-coord*)
              )
              f
            )
            (setq i (1+ i))
          )

          (close f)
          (erarq:msg (strcat "CSV exportado: " path))
        )
      )
    )
  )
)

(defun erarq:export-areas-csv (/ objs sorted path f n area per)
  (setq objs (erarq:ssget-closed-lwpolys))
  (if objs
    (progn
      (setq sorted (erarq:sort-objects-by-grid objs))
      (setq path
        (getfiled
          "Guardar áreas CSV"
          (strcat *erarq-project* "_areas.csv")
          "csv"
          1
        )
      )

      (if path
        (progn
          (setq f (open path "w"))
          (write-line (strcat "PROYECTO," *erarq-project*) f)
          (write-line "LOTE,AREA_M2,PERIMETRO_ML" f)

          (setq n *erarq-start-number*)
          (foreach o sorted
            (setq area (erarq:obj-area o))
            (setq per  (erarq:obj-perimeter o))
            (write-line
              (strcat
                *erarq-lot-prefix* (itoa n) ","
                (erarq:num->str area *erarq-dec-area*) ","
                (erarq:num->str per *erarq-dec-dist*)
              )
              f
            )
            (setq n (1+ n))
          )

          (close f)
          (erarq:msg (strcat "CSV exportado: " path))
        )
      )
    )
  )
)

(defun erarq:export-coords-command ()
  (erarq:export-coordinates-csv)
  (princ)
)

(defun erarq:export-areas-command ()
  (erarq:export-areas-csv)
  (princ)
)