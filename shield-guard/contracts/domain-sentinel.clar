;; ShieldGuard Protocol - Anti-Phishing Smart Contract
;; Contract: domain-sentinel
;; Purpose: Protect users from phishing attacks by maintaining a decentralized 
;; registry of verified domains and suspicious URLs

;; Contract owner and admin controls
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-DOMAIN-EXISTS (err u101))
(define-constant ERR-DOMAIN-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-INSUFFICIENT-STAKE (err u104))
(define-constant ERR-INVALID-INPUT (err u105))
(define-constant ERR-INVALID-DOMAIN (err u106))

;; Minimum stake required for domain verification (10 STX)
(define-constant MIN-STAKE u10000000)

;; Domain verification status
(define-constant STATUS-PENDING u0)
(define-constant STATUS-VERIFIED u1)
(define-constant STATUS-SUSPICIOUS u2)
(define-constant STATUS-BLACKLISTED u3)

;; Data maps for storing domain information
(define-map verified-domains
  { domain: (string-ascii 256) }
  {
    owner: principal,
    status: uint,
    stake-amount: uint,
    verification-date: uint,
    reputation-score: uint,
    reports-count: uint
  }
)

;; Track user reports against suspicious domains
(define-map user-reports
  { reporter: principal, domain: (string-ascii 256) }
  {
    report-date: uint,
    evidence-hash: (string-ascii 64),
    reward-claimed: bool
  }
)

;; Store authorized verifiers who can validate domains
(define-map authorized-verifiers
  { verifier: principal }
  { authorized: bool, reputation: uint }
)

;; Input validation helper functions
(define-private (validate-domain-format (domain (string-ascii 256)))
  (let ((domain-len (len domain)))
    (and 
      (> domain-len u0)
      (< domain-len u257)
      (not (is-eq (element-at domain u0) (some " ")))
      (not (is-eq (element-at domain (- domain-len u1)) (some " ")))
    )
  )
)

(define-private (validate-evidence-format (evidence-hash (string-ascii 64)))
  (let ((hash-len (len evidence-hash)))
    (and 
      (is-eq hash-len u64)
      (> hash-len u0)
    )
  )
)

;; Track total stakes and rewards pool
(define-data-var total-stake-pool uint u0)
(define-data-var reward-pool uint u0)
(define-public (register-domain (domain (string-ascii 256)) (evidence-hash (string-ascii 64)))
  (let ((stake-amount (stx-get-balance tx-sender)))
    (asserts! (>= stake-amount MIN-STAKE) ERR-INSUFFICIENT-STAKE)
    (asserts! (is-none (map-get? verified-domains { domain: domain })) ERR-DOMAIN-EXISTS)
    
    ;; Transfer stake to contract
    (try! (stx-transfer? MIN-STAKE tx-sender (as-contract tx-sender)))
    
    ;; Register domain with pending status
    (map-set verified-domains
      { domain: domain }
      {
        owner: tx-sender,
        status: STATUS-PENDING,
        stake-amount: MIN-STAKE,
        verification-date: block-height,
        reputation-score: u50,
        reports-count: u0
      }
    )
    
    ;; Update total stake pool
    (var-set total-stake-pool (+ (var-get total-stake-pool) MIN-STAKE))
    
    (ok true)
  )
)

;; Function for authorized verifiers to verify domains
(define-public (verify-domain (domain (string-ascii 256)) (new-status uint))
  (let ((verifier-data (map-get? authorized-verifiers { verifier: tx-sender }))
        (domain-data (map-get? verified-domains { domain: domain })))
    
    ;; Input validation
    (asserts! (validate-domain-format domain) ERR-INVALID-DOMAIN)
    (asserts! (is-some verifier-data) ERR-NOT-AUTHORIZED)
    (asserts! (get authorized (unwrap! verifier-data ERR-NOT-AUTHORIZED)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some domain-data) ERR-DOMAIN-NOT-FOUND)
    (asserts! (<= new-status STATUS-BLACKLISTED) ERR-INVALID-STATUS)
    
    (let ((current-data (unwrap! domain-data ERR-DOMAIN-NOT-FOUND)))
      ;; Update domain status and reputation
      (map-set verified-domains
        { domain: domain }
        (merge current-data {
          status: new-status,
          reputation-score: (if (is-eq new-status STATUS-VERIFIED) u100 u0),
          verification-date: block-height
        })
      )
    )
    
    (ok true)
  )
)

;; Function to report suspicious domains
(define-public (report-suspicious-domain (domain (string-ascii 256)) (evidence-hash (string-ascii 64)))
  (let ((existing-report (map-get? user-reports { reporter: tx-sender, domain: domain })))
    ;; Input validation
    (asserts! (validate-domain-format domain) ERR-INVALID-DOMAIN)
    (asserts! (validate-evidence-format evidence-hash) ERR-INVALID-INPUT)
    (asserts! (is-none existing-report) ERR-DOMAIN-EXISTS)
    
    ;; Create new report
    (map-set user-reports
      { reporter: tx-sender, domain: domain }
      {
        report-date: block-height,
        evidence-hash: evidence-hash,
        reward-claimed: false
      }
    )
    
    ;; Update report count for domain if it exists
    (match (map-get? verified-domains { domain: domain })
      domain-data (map-set verified-domains
                    { domain: domain }
                    (merge domain-data { reports-count: (+ (get reports-count domain-data) u1) }))
      true
    )
    
    (ok true)
  )
)

;; Check if a domain is safe to visit
(define-read-only (is-domain-safe (domain (string-ascii 256)))
  (if (validate-domain-format domain)
    (match (map-get? verified-domains { domain: domain })
      domain-data 
        (let ((status (get status domain-data))
              (reputation (get reputation-score domain-data))
              (reports (get reports-count domain-data)))
          {
            safe: (and (is-eq status STATUS-VERIFIED) (> reputation u70) (< reports u3)),
            status: status,
            reputation: reputation,
            reports: reports
          }
        )
      { safe: false, status: u999, reputation: u0, reports: u0 }
    )
    { safe: false, status: u998, reputation: u0, reports: u0 }
  )
)

;; Get domain information
(define-read-only (get-domain-info (domain (string-ascii 256)))
  (if (validate-domain-format domain)
    (map-get? verified-domains { domain: domain })
    none
  )
)

;; Admin function to add authorized verifiers
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; Additional validation to ensure verifier is not contract owner
    (asserts! (not (is-eq verifier CONTRACT-OWNER)) ERR-INVALID-INPUT)
    (map-set authorized-verifiers
      { verifier: verifier }
      { authorized: true, reputation: u100 }
    )
    (ok true)
  )
)

;; Admin function to remove verifiers
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq verifier CONTRACT-OWNER)) ERR-INVALID-INPUT)
    (map-set authorized-verifiers
      { verifier: verifier }
      { authorized: false, reputation: u0 }
    )
    (ok true)
  )
)

;; Function to claim rewards for successful reports
(define-public (claim-report-reward (domain (string-ascii 256)))
  (let ((report-data (map-get? user-reports { reporter: tx-sender, domain: domain }))
        (domain-data (map-get? verified-domains { domain: domain })))
    
    ;; Input validation
    (asserts! (validate-domain-format domain) ERR-INVALID-DOMAIN)
    (asserts! (is-some report-data) ERR-DOMAIN-NOT-FOUND)
    (asserts! (is-some domain-data) ERR-DOMAIN-NOT-FOUND)
    
    (let ((report (unwrap! report-data ERR-DOMAIN-NOT-FOUND))
          (domain-info (unwrap! domain-data ERR-DOMAIN-NOT-FOUND)))
      
      (asserts! (not (get reward-claimed report)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status domain-info) STATUS-BLACKLISTED) ERR-INVALID-STATUS)
      
      ;; Calculate reward (5% of stake)
      (let ((reward-amount (/ (get stake-amount domain-info) u20)))
        ;; Transfer reward to reporter
        (try! (as-contract (stx-transfer? reward-amount tx-sender tx-sender)))
        
        ;; Mark reward as claimed
        (map-set user-reports
          { reporter: tx-sender, domain: domain }
          (merge report { reward-claimed: true })
        )
      )
    )
    
    (ok true)
  )
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-stake: (var-get total-stake-pool),
    reward-pool: (var-get reward-pool),
    contract-balance: (stx-get-balance (as-contract tx-sender))
  }
)