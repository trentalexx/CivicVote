
;; title: CivicVote - Municipal and Local Government Voting System
;; version: 1.0.0
;; summary: A decentralized voting system for municipal and local government elections
;; description: Smart contract that enables secure, transparent voting for local elections
;;              with support for multiple simultaneous elections, candidate management,
;;              and real-time result tracking.

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_ELECTION_NOT_FOUND (err u2))
(define-constant ERR_ELECTION_NOT_ACTIVE (err u3))
(define-constant ERR_ALREADY_VOTED (err u4))
(define-constant ERR_CANDIDATE_NOT_FOUND (err u5))
(define-constant ERR_ELECTION_ALREADY_ENDED (err u6))
(define-constant ERR_ELECTION_ALREADY_STARTED (err u7))
(define-constant ERR_INVALID_PARAMETERS (err u8))

;; data vars
;;
(define-data-var next-election-id uint u1)

;; data maps
;;
;; Election data structure
(define-map elections uint {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    start-block: uint,
    end-block: uint,
    is-active: bool,
    total-votes: uint
})

;; Candidate data for each election
(define-map candidates {election-id: uint, candidate-id: uint} {
    name: (string-ascii 50),
    description: (string-ascii 200),
    vote-count: uint
})

;; Track candidate count per election
(define-map election-candidate-count uint uint)

;; Track votes to prevent double voting
(define-map votes {election-id: uint, voter: principal} {
    candidate-id: uint,
    block-height: uint
})

;; Track if a voter has voted in an election
(define-map voter-participated {election-id: uint, voter: principal} bool)

;; public functions
;;

;; Create a new election
(define-public (create-election (title (string-ascii 100)) 
                              (description (string-ascii 500))
                              (duration-blocks uint))
    (let ((election-id (var-get next-election-id))
          (start-block (+ block-height u1))
          (end-block (+ block-height duration-blocks)))
        (asserts! (> (len title) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> duration-blocks u0) ERR_INVALID_PARAMETERS)
        
        ;; Create the election
        (map-set elections election-id {
            title: title,
            description: description,
            creator: tx-sender,
            start-block: start-block,
            end-block: end-block,
            is-active: true,
            total-votes: u0
        })
        
        ;; Initialize candidate count
        (map-set election-candidate-count election-id u0)
        
        ;; Increment election ID for next election
        (var-set next-election-id (+ election-id u1))
        
        (ok election-id)))

;; Add a candidate to an election
(define-public (add-candidate (election-id uint) 
                             (name (string-ascii 50)) 
                             (description (string-ascii 200)))
    (let ((election-opt (map-get? elections election-id))
          (candidate-count (default-to u0 (map-get? election-candidate-count election-id))))
        (asserts! (is-some election-opt) ERR_ELECTION_NOT_FOUND)
        (asserts! (> (len name) u0) ERR_INVALID_PARAMETERS)
        
        (let ((election (unwrap-panic election-opt)))
            ;; Only election creator can add candidates
            (asserts! (is-eq tx-sender (get creator election)) ERR_UNAUTHORIZED)
            ;; Can only add candidates before election starts
            (asserts! (< block-height (get start-block election)) ERR_ELECTION_ALREADY_STARTED)
            
            ;; Add the candidate
            (map-set candidates {election-id: election-id, candidate-id: candidate-count} {
                name: name,
                description: description,
                vote-count: u0
            })
            
            ;; Increment candidate count
            (map-set election-candidate-count election-id (+ candidate-count u1))
            
            (ok candidate-count))))

;; Cast a vote for a candidate in an election
(define-public (cast-vote (election-id uint) (candidate-id uint))
    (let ((election-opt (map-get? elections election-id)))
        (asserts! (is-some election-opt) ERR_ELECTION_NOT_FOUND)
        
        (let ((election (unwrap-panic election-opt))
              (candidate-opt (map-get? candidates {election-id: election-id, candidate-id: candidate-id}))
              (has-voted (default-to false (map-get? voter-participated {election-id: election-id, voter: tx-sender}))))
            
            ;; Verify election is active and within voting period
            (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
            (asserts! (>= block-height (get start-block election)) ERR_ELECTION_NOT_ACTIVE)
            (asserts! (<= block-height (get end-block election)) ERR_ELECTION_ALREADY_ENDED)
            
            ;; Verify candidate exists
            (asserts! (is-some candidate-opt) ERR_CANDIDATE_NOT_FOUND)
            
            ;; Verify voter hasn't already voted
            (asserts! (not has-voted) ERR_ALREADY_VOTED)
            
            (let ((candidate (unwrap-panic candidate-opt)))
                ;; Record the vote
                (map-set votes {election-id: election-id, voter: tx-sender} {
                    candidate-id: candidate-id,
                    block-height: block-height
                })
                
                ;; Mark voter as participated
                (map-set voter-participated {election-id: election-id, voter: tx-sender} true)
                
                ;; Update candidate vote count
                (map-set candidates {election-id: election-id, candidate-id: candidate-id} 
                    (merge candidate {vote-count: (+ (get vote-count candidate) u1)}))
                
                ;; Update total votes in election
                (map-set elections election-id 
                    (merge election {total-votes: (+ (get total-votes election) u1)}))
                
                (ok true)))))

;; End an election (only creator can end early, otherwise ends automatically)
(define-public (end-election (election-id uint))
    (let ((election-opt (map-get? elections election-id)))
        (asserts! (is-some election-opt) ERR_ELECTION_NOT_FOUND)
        
        (let ((election (unwrap-panic election-opt)))
            ;; Only creator can end election early, or anyone after end-block
            (asserts! (or (is-eq tx-sender (get creator election))
                         (> block-height (get end-block election))) ERR_UNAUTHORIZED)
            
            ;; Election must be active
            (asserts! (get is-active election) ERR_ELECTION_ALREADY_ENDED)
            
            ;; Mark election as inactive
            (map-set elections election-id 
                (merge election {is-active: false}))
            
            (ok true))))

;; read only functions
;;

;; Get election details
(define-read-only (get-election (election-id uint))
    (map-get? elections election-id))

;; Get candidate details
(define-read-only (get-candidate (election-id uint) (candidate-id uint))
    (map-get? candidates {election-id: election-id, candidate-id: candidate-id}))

;; Get vote details for a voter in an election
(define-read-only (get-vote (election-id uint) (voter principal))
    (map-get? votes {election-id: election-id, voter: voter}))

;; Check if a voter has participated in an election
(define-read-only (has-voter-participated (election-id uint) (voter principal))
    (default-to false (map-get? voter-participated {election-id: election-id, voter: voter})))

;; Get candidate count for an election
(define-read-only (get-candidate-count (election-id uint))
    (default-to u0 (map-get? election-candidate-count election-id)))

;; Get next election ID
(define-read-only (get-next-election-id)
    (var-get next-election-id))

;; Check if an election is currently active and accepting votes
(define-read-only (is-election-active (election-id uint))
    (match (map-get? elections election-id)
        election (and (get is-active election)
                     (>= block-height (get start-block election))
                     (<= block-height (get end-block election)))
        false))

;; Get election results (list of candidates with vote counts)
(define-read-only (get-election-results (election-id uint))
    (map-get? elections election-id))

;; Get current block height for reference
(define-read-only (get-current-block)
    block-height)

;; private functions
;;

