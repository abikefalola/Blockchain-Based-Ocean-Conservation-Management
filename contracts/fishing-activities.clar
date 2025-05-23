;; Fishing Activity Contract
;; Records and manages commercial fishing operations

(define-data-var admin principal tx-sender)

;; Fishing vessel registration
(define-map fishing-vessels
  { vessel-id: uint }
  {
    name: (string-utf8 100),
    owner: principal,
    registration-number: (string-utf8 50),
    vessel-type: (string-utf8 50),
    max-capacity: uint,
    registration-date: uint,
    is-active: bool
  }
)

;; Fishing activity records
(define-map fishing-activities
  { activity-id: uint }
  {
    vessel-id: uint,
    area-id: uint,
    start-date: uint,
    end-date: uint,
    catch-type: (string-utf8 100),
    catch-amount-kg: uint,
    is-authorized: bool,
    notes: (string-utf8 200)
  }
)

(define-data-var next-vessel-id uint u1)
(define-data-var next-activity-id uint u1)

;; Register a new fishing vessel
(define-public (register-vessel
                (name (string-utf8 100))
                (registration-number (string-utf8 50))
                (vessel-type (string-utf8 50))
                (max-capacity uint))
  (let ((vessel-id (var-get next-vessel-id)))
    (begin
      (map-set fishing-vessels
        { vessel-id: vessel-id }
        {
          name: name,
          owner: tx-sender,
          registration-number: registration-number,
          vessel-type: vessel-type,
          max-capacity: max-capacity,
          registration-date: block-height,
          is-active: true
        }
      )
      (var-set next-vessel-id (+ vessel-id u1))
      (ok vessel-id)
    )
  )
)

;; Record fishing activity
(define-public (record-fishing-activity
                (vessel-id uint)
                (area-id uint)
                (start-date uint)
                (end-date uint)
                (catch-type (string-utf8 100))
                (catch-amount-kg uint)
                (notes (string-utf8 200)))
  (let ((activity-id (var-get next-activity-id))
        (vessel-info (unwrap! (map-get? fishing-vessels { vessel-id: vessel-id }) (err u404))))
    (begin
      (asserts! (is-eq tx-sender (get owner vessel-info)) (err u403))
      (asserts! (get is-active vessel-info) (err u403))
      (map-set fishing-activities
        { activity-id: activity-id }
        {
          vessel-id: vessel-id,
          area-id: area-id,
          start-date: start-date,
          end-date: end-date,
          catch-type: catch-type,
          catch-amount-kg: catch-amount-kg,
          is-authorized: false,
          notes: notes
        }
      )
      (var-set next-activity-id (+ activity-id u1))
      (ok activity-id)
    )
  )
)

;; Authorize fishing activity
(define-public (authorize-activity (activity-id uint) (is-authorized bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? fishing-activities { activity-id: activity-id })) (err u404))
    (map-set fishing-activities
      { activity-id: activity-id }
      (merge (unwrap-panic (map-get? fishing-activities { activity-id: activity-id }))
             { is-authorized: is-authorized })
    )
    (ok true)
  )
)

;; Get vessel details
(define-read-only (get-vessel-details (vessel-id uint))
  (map-get? fishing-vessels { vessel-id: vessel-id })
)

;; Get fishing activity details
(define-read-only (get-activity-details (activity-id uint))
  (map-get? fishing-activities { activity-id: activity-id })
)

;; Update vessel status
(define-public (update-vessel-status (vessel-id uint) (is-active bool))
  (let ((vessel-info (unwrap! (map-get? fishing-vessels { vessel-id: vessel-id }) (err u404))))
    (begin
      (asserts! (or (is-eq tx-sender (get owner vessel-info))
                   (is-eq tx-sender (var-get admin)))
               (err u403))
      (map-set fishing-vessels
        { vessel-id: vessel-id }
        (merge vessel-info { is-active: is-active })
      )
      (ok true)
    )
  )
)
