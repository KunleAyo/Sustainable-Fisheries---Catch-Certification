;; Sustainable Fisheries & Catch Certification Smart Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-data (err u104))
(define-constant err-quota-exceeded (err u105))
(define-constant err-expired (err u106))

(define-map boats
  { boat-id: (string-ascii 64) }
  {
    owner: principal,
    vessel-name: (string-ascii 128),
    license-number: (string-ascii 64),
    iot-device-id: (string-ascii 64),
    verified: bool,
    registration-height: uint
  }
)

(define-map species-quotas
  { species-code: (string-ascii 32), boat-id: (string-ascii 64) }
  {
    annual-quota: uint,
    used-quota: uint,
    season-start: uint,
    season-end: uint
  }
)

(define-map catch-records
  { catch-id: (string-ascii 64) }
  {
    boat-id: (string-ascii 64),
    species-code: (string-ascii 32),
    weight: uint,
    location-lat: int,
    location-lon: int,
    timestamp: uint,
    iot-verified: bool,
    qr-code: (string-ascii 128),
    verified: bool
  }
)

(define-map qr-code-registry
  { qr-code: (string-ascii 128) }
  {
    catch-id: (string-ascii 64),
    expiry-block: uint,
    consumer-verified: bool
  }
)

(define-map authorized-verifiers
  { verifier: principal }
  { active: bool }
)

(define-data-var next-catch-id uint u1)

(define-public (register-boat (boat-id (string-ascii 64)) 
                             (vessel-name (string-ascii 128))
                             (license-number (string-ascii 64))
                             (iot-device-id (string-ascii 64)))
  (let ((existing-boat (map-get? boats { boat-id: boat-id })))
    (asserts! (is-none existing-boat) err-already-exists)
    (ok (map-set boats
      { boat-id: boat-id }
      {
        owner: tx-sender,
        vessel-name: vessel-name,
        license-number: license-number,
        iot-device-id: iot-device-id,
        verified: false,
        registration-height: burn-block-height
      }
    ))
  )
)

(define-public (verify-boat (boat-id (string-ascii 64)))
  (let ((boat (unwrap! (map-get? boats { boat-id: boat-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set boats
      { boat-id: boat-id }
      (merge boat { verified: true })
    ))
  )
)

(define-public (set-species-quota (species-code (string-ascii 32))
                                 (boat-id (string-ascii 64))
                                 (annual-quota uint)
                                 (season-start uint)
                                 (season-end uint))
  (let ((boat (unwrap! (map-get? boats { boat-id: boat-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get verified boat) err-unauthorized)
    (ok (map-set species-quotas
      { species-code: species-code, boat-id: boat-id }
      {
        annual-quota: annual-quota,
        used-quota: u0,
        season-start: season-start,
        season-end: season-end
      }
    ))
  )
)

(define-public (record-catch (boat-id (string-ascii 64))
                           (species-code (string-ascii 32))
                           (weight uint)
                           (location-lat int)
                           (location-lon int)
                           (iot-device-id (string-ascii 64)))
  (let (
    (catch-id (int-to-ascii (var-get next-catch-id)))
    (boat (unwrap! (map-get? boats { boat-id: boat-id }) err-not-found))
    (quota-data (unwrap! (map-get? species-quotas { species-code: species-code, boat-id: boat-id }) err-not-found))
    (qr-code (concat (concat boat-id "-") catch-id))
  )
    (asserts! (is-eq (get owner boat) tx-sender) err-unauthorized)
    (asserts! (get verified boat) err-unauthorized)
    (asserts! (is-eq (get iot-device-id boat) iot-device-id) err-unauthorized)
    (asserts! (>= burn-block-height (get season-start quota-data)) err-invalid-data)
    (asserts! (<= burn-block-height (get season-end quota-data)) err-invalid-data)
    (asserts! (<= (+ (get used-quota quota-data) weight) (get annual-quota quota-data)) err-quota-exceeded)
    
    (map-set catch-records
      { catch-id: catch-id }
      {
        boat-id: boat-id,
        species-code: species-code,
        weight: weight,
        location-lat: location-lat,
        location-lon: location-lon,
        timestamp: burn-block-height,
        iot-verified: true,
        qr-code: qr-code,
        verified: false
      }
    )
    
    (map-set species-quotas
      { species-code: species-code, boat-id: boat-id }
      (merge quota-data { used-quota: (+ (get used-quota quota-data) weight) })
    )
    
    (map-set qr-code-registry
      { qr-code: qr-code }
      {
        catch-id: catch-id,
        expiry-block: (+ burn-block-height u8760),
        consumer-verified: false
      }
    )
    
    (var-set next-catch-id (+ (var-get next-catch-id) u1))
    (ok { catch-id: catch-id, qr-code: qr-code })
  )
)

(define-public (verify-catch (catch-id (string-ascii 64)))
  (let ((catch-data (unwrap! (map-get? catch-records { catch-id: catch-id }) err-not-found))
        (verifier (unwrap! (map-get? authorized-verifiers { verifier: tx-sender }) err-unauthorized)))
    (asserts! (get active verifier) err-unauthorized)
    (ok (map-set catch-records
      { catch-id: catch-id }
      (merge catch-data { verified: true })
    ))
  )
)

(define-public (verify-qr-code (qr-code (string-ascii 128)))
  (let ((qr-data (unwrap! (map-get? qr-code-registry { qr-code: qr-code }) err-not-found))
        (catch-data (unwrap! (map-get? catch-records { catch-id: (get catch-id qr-data) }) err-not-found)))
    (asserts! (<= burn-block-height (get expiry-block qr-data)) err-expired)
    (map-set qr-code-registry
      { qr-code: qr-code }
      (merge qr-data { consumer-verified: true })
    )
    (ok {
      catch-id: (get catch-id qr-data),
      boat-id: (get boat-id catch-data),
      species: (get species-code catch-data),
      weight: (get weight catch-data),
      timestamp: (get timestamp catch-data),
      verified: (get verified catch-data)
    })
  )
)

(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-verifiers { verifier: verifier } { active: true }))
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-verifiers { verifier: verifier } { active: false }))
  )
)

(define-public (update-quota (species-code (string-ascii 32))
                           (boat-id (string-ascii 64))
                           (new-quota uint))
  (let ((existing-quota (unwrap! (map-get? species-quotas { species-code: species-code, boat-id: boat-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set species-quotas
      { species-code: species-code, boat-id: boat-id }
      (merge existing-quota { annual-quota: new-quota })
    ))
  )
)

(define-public (update-iot-device (boat-id (string-ascii 64)) (new-iot-device-id (string-ascii 64)))
  (let ((boat (unwrap! (map-get? boats { boat-id: boat-id }) err-not-found)))
    (asserts! (is-eq (get owner boat) tx-sender) err-unauthorized)
    (asserts! (get verified boat) err-unauthorized)
    (ok (map-set boats { boat-id: boat-id } (merge boat { iot-device-id: new-iot-device-id })))
  )
)

(define-read-only (get-boat-info (boat-id (string-ascii 64)))
  (map-get? boats { boat-id: boat-id })
)

(define-read-only (get-catch-info (catch-id (string-ascii 64)))
  (map-get? catch-records { catch-id: catch-id })
)

(define-read-only (get-quota-info (species-code (string-ascii 32)) (boat-id (string-ascii 64)))
  (map-get? species-quotas { species-code: species-code, boat-id: boat-id })
)

(define-read-only (get-qr-info (qr-code (string-ascii 128)))
  (map-get? qr-code-registry { qr-code: qr-code })
)

(define-read-only (is-verifier (verifier principal))
  (match (map-get? authorized-verifiers { verifier: verifier })
    verifier-data (get active verifier-data)
    false
  )
)

(define-read-only (get-remaining-quota (species-code (string-ascii 32)) (boat-id (string-ascii 64)))
  (match (map-get? species-quotas { species-code: species-code, boat-id: boat-id })
    quota-data (ok (- (get annual-quota quota-data) (get used-quota quota-data)))
    err-not-found
  )
)

(define-read-only (is-catch-valid (catch-id (string-ascii 64)))
  (match (map-get? catch-records { catch-id: catch-id })
    catch-data (and (get iot-verified catch-data) (get verified catch-data))
    false
  )
)

(define-read-only (get-boat-catch-history (boat-id (string-ascii 64)))
  (ok boat-id)
)

(define-read-only (validate-supply-chain (qr-code (string-ascii 128)))
  (match (map-get? qr-code-registry { qr-code: qr-code })
    qr-data (match (map-get? catch-records { catch-id: (get catch-id qr-data) })
      catch-data (ok {
        valid: (and (get verified catch-data) (<= burn-block-height (get expiry-block qr-data))),
        catch-details: catch-data,
        qr-details: qr-data
      })
      err-not-found
    )
    err-not-found
  )
)

(define-map catch-reports
  { report-id: (string-ascii 64) }
  {
    reporter: principal,
    catch-id: (string-ascii 64),
    reason: (string-ascii 256),
    timestamp: uint,
    resolved: bool
  }
)

(define-data-var next-report-id uint u1)

(define-public (report-catch-issue (catch-id (string-ascii 64)) (reason (string-ascii 256)))
  (let ((report-id (int-to-ascii (var-get next-report-id))))
    (asserts! (is-some (map-get? catch-records { catch-id: catch-id })) err-not-found)
    (map-set catch-reports
      { report-id: report-id }
      {
        reporter: tx-sender,
        catch-id: catch-id,
        reason: reason,
        timestamp: burn-block-height,
        resolved: false
      }
    )
    (var-set next-report-id (+ (var-get next-report-id) u1))
    (ok report-id)
  )
)

(define-public (resolve-report (report-id (string-ascii 64)))
  (let ((report (unwrap! (map-get? catch-reports { report-id: report-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set catch-reports
      { report-id: report-id }
      (merge report { resolved: true })
    ))
  )
)

(define-read-only (get-report-info (report-id (string-ascii 64)))
  (map-get? catch-reports { report-id: report-id })
)
