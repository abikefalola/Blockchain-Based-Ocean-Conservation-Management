;; Species Monitoring Contract
;; Tracks marine life populations and conservation status

(define-data-var admin principal tx-sender)

;; Species data structure
(define-map species
  { species-id: uint }
  {
    name: (string-utf8 100),
    scientific-name: (string-utf8 100),
    conservation-status: (string-utf8 20),
    habitat: (string-utf8 100),
    last-updated: uint
  }
)

;; Population records
(define-map population-records
  { species-id: uint, record-id: uint }
  {
    area-id: uint,
    population-count: uint,
    observation-date: uint,
    observer: principal,
    notes: (string-utf8 200)
  }
)

(define-data-var next-species-id uint u1)
(define-data-var next-record-id uint u1)

;; Register a new species
(define-public (register-species
                (name (string-utf8 100))
                (scientific-name (string-utf8 100))
                (conservation-status (string-utf8 20))
                (habitat (string-utf8 100)))
  (let ((species-id (var-get next-species-id)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set species
        { species-id: species-id }
        {
          name: name,
          scientific-name: scientific-name,
          conservation-status: conservation-status,
          habitat: habitat,
          last-updated: block-height
        }
      )
      (var-set next-species-id (+ species-id u1))
      (ok species-id)
    )
  )
)

;; Record population observation
(define-public (record-population
                (species-id uint)
                (area-id uint)
                (population-count uint)
                (notes (string-utf8 200)))
  (let ((record-id (var-get next-record-id)))
    (begin
      (asserts! (is-some (map-get? species { species-id: species-id })) (err u404))
      (map-set population-records
        { species-id: species-id, record-id: record-id }
        {
          area-id: area-id,
          population-count: population-count,
          observation-date: block-height,
          observer: tx-sender,
          notes: notes
        }
      )
      (map-set species
        { species-id: species-id }
        (merge (unwrap-panic (map-get? species { species-id: species-id }))
               { last-updated: block-height })
      )
      (var-set next-record-id (+ record-id u1))
      (ok record-id)
    )
  )
)

;; Update species conservation status
(define-public (update-conservation-status
                (species-id uint)
                (conservation-status (string-utf8 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? species { species-id: species-id })) (err u404))
    (map-set species
      { species-id: species-id }
      (merge (unwrap-panic (map-get? species { species-id: species-id }))
             {
               conservation-status: conservation-status,
               last-updated: block-height
             })
    )
    (ok true)
  )
)

;; Get species details
(define-read-only (get-species-details (species-id uint))
  (map-get? species { species-id: species-id })
)

;; Get population record
(define-read-only (get-population-record (species-id uint) (record-id uint))
  (map-get? population-records { species-id: species-id, record-id: record-id })
)
