(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))
(define-constant err-invalid-referrer (err u103))
(define-constant err-self-referral (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-already-verified (err u106))
(define-constant err-not-verified (err u107))
(define-constant err-invalid-level (err u108))

(define-data-var base-reward uint u1000000)
(define-data-var level-two-reward uint u500000)
(define-data-var level-three-reward uint u250000)
(define-data-var contract-balance uint u0)

(define-map users
  principal
  {
    referrer: (optional principal),
    is-verified: bool,
    total-referrals: uint,
    total-earned: uint,
    registration-height: uint
  }
)

(define-map referral-tree
  principal
  {
    level-one: (list 100 principal),
    level-two: (list 100 principal),
    level-three: (list 100 principal)
  }
)

(define-map pending-rewards
  principal
  uint
)

(define-public (register (referrer (optional principal)))
  (let
    (
      (sender tx-sender)
    )
    (asserts! (is-none (map-get? users sender)) err-already-registered)
    (asserts! 
      (or 
        (is-none referrer)
        (and 
          (is-some referrer)
          (not (is-eq (unwrap-panic referrer) sender))
        )
      )
      err-self-referral
    )
    (match referrer
      ref-principal
        (begin
          (asserts! (is-some (map-get? users ref-principal)) err-invalid-referrer)
          (map-set users sender {
            referrer: (some ref-principal),
            is-verified: false,
            total-referrals: u0,
            total-earned: u0,
            registration-height: block-height
          })
          (ok true)
        )
      (begin
        (map-set users sender {
          referrer: none,
          is-verified: false,
          total-referrals: u0,
          total-earned: u0,
          registration-height: block-height
        })
        (ok true)
      )
    )
  )
)

(define-public (verify-user (user principal))
  (let
    (
      (user-data (unwrap! (map-get? users user) err-not-registered))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get is-verified user-data)) err-already-verified)
    (map-set users user (merge user-data { is-verified: true }))
    (match (get referrer user-data)
      referrer-principal
        (try! (process-referral-rewards user referrer-principal))
      true
    )
    (ok true)
  )
)

(define-private (process-referral-rewards (new-user principal) (referrer principal))
  (let
    (
      (level-one-reward (var-get base-reward))
      (referrer-data (unwrap! (map-get? users referrer) err-not-registered))
    )
    (try! (add-to-tree referrer new-user u1))
    (try! (distribute-reward referrer level-one-reward))
    (map-set users referrer 
      (merge referrer-data 
        { 
          total-referrals: (+ (get total-referrals referrer-data) u1),
          total-earned: (+ (get total-earned referrer-data) level-one-reward)
        }
      )
    )
    (match (get referrer referrer-data)
      level-two-ref
        (begin
          (try! (add-to-tree level-two-ref new-user u2))
          (try! (distribute-reward level-two-ref (var-get level-two-reward)))
          (let
            (
              (level-two-data (unwrap! (map-get? users level-two-ref) err-not-registered))
            )
            (map-set users level-two-ref
              (merge level-two-data
                { total-earned: (+ (get total-earned level-two-data) (var-get level-two-reward)) }
              )
            )
            (match (get referrer level-two-data)
              level-three-ref
                (begin
                  (try! (add-to-tree level-three-ref new-user u3))
                  (try! (distribute-reward level-three-ref (var-get level-three-reward)))
                  (let
                    (
                      (level-three-data (unwrap! (map-get? users level-three-ref) err-not-registered))
                    )
                    (map-set users level-three-ref
                      (merge level-three-data
                        { total-earned: (+ (get total-earned level-three-data) (var-get level-three-reward)) }
                      )
                    )
                    (ok true)
                  )
                )
              (ok true)
            )
          )
        )
      (ok true)
    )
  )
)

(define-private (add-to-tree (referrer principal) (new-user principal) (level uint))
  (let
    (
      (tree-data (default-to 
        { level-one: (list), level-two: (list), level-three: (list) }
        (map-get? referral-tree referrer)
      ))
    )
    (begin
      (if (is-eq level u1)
        (map-set referral-tree referrer
          (merge tree-data { level-one: (unwrap! (as-max-len? (append (get level-one tree-data) new-user) u100) err-invalid-level) })
        )
        (if (is-eq level u2)
          (map-set referral-tree referrer
            (merge tree-data { level-two: (unwrap! (as-max-len? (append (get level-two tree-data) new-user) u100) err-invalid-level) })
          )
          (map-set referral-tree referrer
            (merge tree-data { level-three: (unwrap! (as-max-len? (append (get level-three tree-data) new-user) u100) err-invalid-level) })
          )
        )
      )
      (ok true)
    )
  )
)

(define-private (distribute-reward (recipient principal) (amount uint))
  (let
    (
      (current-pending (default-to u0 (map-get? pending-rewards recipient)))
    )
    (map-set pending-rewards recipient (+ current-pending amount))
    (ok true)
  )
)

(define-public (claim-rewards)
  (let
    (
      (sender tx-sender)
      (user-data (unwrap! (map-get? users sender) err-not-registered))
      (pending-amount (default-to u0 (map-get? pending-rewards sender)))
    )
    (asserts! (get is-verified user-data) err-not-verified)
    (asserts! (> pending-amount u0) err-insufficient-balance)
    (asserts! (>= (var-get contract-balance) pending-amount) err-insufficient-balance)
    (try! (as-contract (stx-transfer? pending-amount tx-sender sender)))
    (var-set contract-balance (- (var-get contract-balance) pending-amount))
    (map-delete pending-rewards sender)
    (ok pending-amount)
  )
)

(define-public (fund-contract (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok true)
  )
)

(define-public (set-base-reward (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set base-reward new-reward)
    (ok true)
  )
)

(define-public (set-level-two-reward (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set level-two-reward new-reward)
    (ok true)
  )
)

(define-public (set-level-three-reward (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set level-three-reward new-reward)
    (ok true)
  )
)

(define-read-only (get-user-info (user principal))
  (ok (map-get? users user))
)

(define-read-only (get-referral-tree (user principal))
  (ok (map-get? referral-tree user))
)

(define-read-only (get-pending-rewards (user principal))
  (ok (default-to u0 (map-get? pending-rewards user)))
)

(define-read-only (get-contract-balance)
  (ok (var-get contract-balance))
)

(define-read-only (get-reward-rates)
  (ok {
    base: (var-get base-reward),
    level-two: (var-get level-two-reward),
    level-three: (var-get level-three-reward)
  })
)