;; IDTracker Smart Contract
;; Enables transparent tracking of ID status and verifications

(define-trait id-tracking-trait
  (
    (register-id (uint uint) (response bool uint))
    (update-id-status (uint uint) (response bool uint))
    (get-id-history (uint) (response (list 10 {status: uint, timestamp: uint}) uint))
    (add-verification (uint uint principal) (response bool uint))
    (verify-check (uint uint) (response bool uint))
  )
)

;; Define ID status constants
(define-constant STATUS_CREATED u1)
(define-constant STATUS_ACTIVE u2)
(define-constant STATUS_PENDING_REVIEW u3)
(define-constant STATUS_VERIFIED u4)

;; Define verification type constants
(define-constant CHECK_IDENTITY u1)
(define-constant CHECK_DOCUMENTS u2)
(define-constant CHECK_BACKGROUND u3)
(define-constant CHECK_BIOMETRIC u4)

;; Error constants
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_INVALID_ID (err u2))
(define-constant ERR_STATUS_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_STATUS (err u4))
(define-constant ERR_INVALID_CHECK (err u5))
(define-constant ERR_CHECK_EXISTS (err u6))

;; Contract owner
(define-data-var system-admin principal tx-sender)

;; ID tracking map
(define-map id-data 
  {tracking-id: uint} 
  {
    issuer: principal,
    current-status: uint,
    history: (list 10 {status: uint, timestamp: uint})
  }
)

;; Verification tracking map
(define-map id-verifications
  {tracking-id: uint, check-type: uint}
  {
    verifier: principal,
    timestamp: uint,
    valid: bool
  }
)

;; Approved verifiers
(define-map authorized-verifiers
  {verifier: principal, check-type: uint}
  {authorized: bool}
)

;; Only system admin can perform certain actions
(define-read-only (is-system-admin (sender principal))
  (is-eq sender (var-get system-admin))
)

;; Validate status
(define-private (is-valid-status (status uint))
  (or 
    (is-eq status STATUS_CREATED)
    (is-eq status STATUS_ACTIVE)
    (is-eq status STATUS_PENDING_REVIEW)
    (is-eq status STATUS_VERIFIED)
  )
)

;; Validate verification type
(define-private (is-valid-check-type (check-type uint))
  (or
    (is-eq check-type CHECK_IDENTITY)
    (is-eq check-type CHECK_DOCUMENTS)
    (is-eq check-type CHECK_BACKGROUND)
    (is-eq check-type CHECK_BIOMETRIC)
  )
)

;; Validate tracking ID
(define-private (is-valid-tracking-id (tracking-id uint))
  (and (> tracking-id u0) (<= tracking-id u1000000))
)

;; Check if sender is authorized verifier
(define-private (is-authorized-verifier (verifier principal) (check-type uint))
  (default-to 
    false
    (get authorized (map-get? authorized-verifiers {verifier: verifier, check-type: check-type}))
  )
)

;; Register a new ID
(define-public (register-id (tracking-id uint) (initial-status uint))
  (begin
    (asserts! (is-valid-tracking-id tracking-id) ERR_INVALID_ID)
    (asserts! (is-valid-status initial-status) ERR_INVALID_STATUS)
    (asserts! (or (is-system-admin tx-sender) (is-eq initial-status STATUS_CREATED)) ERR_NOT_AUTHORIZED)
    
    (map-set id-data 
      {tracking-id: tracking-id}
      {
        issuer: tx-sender,
        current-status: initial-status,
        history: (list {status: initial-status, timestamp: block-height})
      }
    )
    (ok true)
  )
)

;; Update ID status
(define-public (update-id-status (tracking-id uint) (new-status uint))
  (let 
    (
      (id (unwrap! (map-get? id-data {tracking-id: tracking-id}) ERR_INVALID_ID))
    )
    (asserts! (is-valid-tracking-id tracking-id) ERR_INVALID_ID)
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    (asserts! 
      (or 
        (is-system-admin tx-sender)
        (is-eq (get issuer id) tx-sender)
      ) 
      ERR_NOT_AUTHORIZED
    )
    
    (map-set id-data 
      {tracking-id: tracking-id}
      (merge id 
        {
          current-status: new-status,
          history: (unwrap-panic 
            (as-max-len? 
              (append (get history id) {status: new-status, timestamp: block-height}) 
              u10
            )
          )
        }
      )
    )
    (ok true)
  )
)

;; Add authorized verifier
(define-public (add-authorized-verifier (verifier principal) (check-type uint))
  (begin
    (asserts! (is-system-admin tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-valid-check-type check-type) ERR_INVALID_CHECK)
    
    (map-set authorized-verifiers
      {verifier: verifier, check-type: check-type}
      {authorized: true}
    )
    (ok true)
  )
)

;; Add verification check
(define-public (add-verification (tracking-id uint) (check-type uint))
  (begin
    (asserts! (is-valid-tracking-id tracking-id) ERR_INVALID_ID)
    (asserts! (is-valid-check-type check-type) ERR_INVALID_CHECK)
    (asserts! (is-authorized-verifier tx-sender check-type) ERR_NOT_AUTHORIZED)
    
    (asserts! 
      (is-none 
        (map-get? id-verifications {tracking-id: tracking-id, check-type: check-type})
      )
      ERR_CHECK_EXISTS
    )
    
    (map-set id-verifications
      {tracking-id: tracking-id, check-type: check-type}
      {
        verifier: tx-sender,
        timestamp: block-height,
        valid: true
      }
    )
    (ok true)
  )
)

;; Verify ID check
(define-read-only (verify-check (tracking-id uint) (check-type uint))
  (let
    (
      (verification (unwrap! 
        (map-get? id-verifications {tracking-id: tracking-id, check-type: check-type})
        ERR_INVALID_CHECK
      ))
    )
    (ok (get valid verification))
  )
)

