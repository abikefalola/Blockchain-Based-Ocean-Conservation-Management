;; Marine Area Verification Contract
;; Validates and manages protected marine zones

(define-data-var admin principal tx-sender)

;; Marine Protected Area data structure
(define-map protected-areas
  { area-id: uint }
  {
    name: (string-utf8 100),
    coordinates: (string-utf8 500),
    size-sq-km: uint,
    protection-level: uint,
    creation-date: uint,
    last-verified: uint,
    is-active: bool
  }
)

;; Area verification records
(define-map area-verifications
  { area-id: uint, verification-id: uint }
  {
    verifier: principal,
    timestamp: uint,
    status: (string-utf8 20),
    notes: (string-utf8 200)
  }
)

(define-data-var next-area-id uint u1)
(define-data-var next-verification-id uint u1)

;; Register a new marine protected area
(define-public (register-protected-area
                (name (string-utf8 100))
                (coordinates (string-utf8 500))
                (size-sq-km uint)
                (protection-level uint))
  (let ((area-id (var-get next-area-id)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403))
      (map-set protected-areas
        { area-id: area-id }
        {
          name: name,
          coordinates: coordinates,
          size-sq-km: size-sq-km,
          protection-level: protection-level,
          creation-date: block-height,
          last-verified: u0,
          is-active: true
        }
      )
      (var-set next-area-id (+ area-id u1))
      (ok area-id)
    )
  )
)

;; Verify a marine protected area
(define-public (verify-area (area-id uint) (status (string-utf8 20)) (notes (string-utf8 200)))
  (let ((verification-id (var-get next-verification-id)))
    (begin
      (asserts! (is-some (map-get? protected-areas { area-id: area-id })) (err u404))
      (map-set area-verifications
        { area-id: area-id, verification-id: verification-id }
        {
          verifier: tx-sender,
          timestamp: block-height,
          status: status,
          notes: notes
        }
      )
      (map-set protected-areas
        { area-id: area-id }
        (merge (unwrap-panic (map-get? protected-areas { area-id: area-id }))
               { last-verified: block-height })
      )
      (var-set next-verification-id (+ verification-id u1))
      (ok verification-id)
    )
  )
)

;; Get area details
(define-read-only (get-area-details (area-id uint))
  (map-get? protected-areas { area-id: area-id })
)

;; Get verification details
(define-read-only (get-verification-details (area-id uint) (verification-id uint))
  (map-get? area-verifications { area-id: area-id, verification-id: verification-id })
)

;; Update area status (active/inactive)
(define-public (update-area-status (area-id uint) (is-active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? protected-areas { area-id: area-id })) (err u404))
    (map-set protected-areas
      { area-id: area-id }
      (merge (unwrap-panic (map-get? protected-areas { area-id: area-id }))
             { is-active: is-active })
    )
    (ok true)
  )
)
