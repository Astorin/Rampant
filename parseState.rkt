(module AiState racket
        (provide (all-defined-out))

        (require math/statistics)

        (struct AiState (chunks
                         chunksLookup
                         minMaxes)
                #:transparent)

        (struct MinMax (min max)
                #:transparent)

        (struct ChunkRange (x
                            y
                            movement
                            base
                            player
                            resource
                            passable
                            tick
                            rating
                            nests
                            worms
                            rally
                            retreat
                            resourceGen
                            playerGen
                            deathGen
                            attackScore
                            settleScore
                            siegeScore
                            retreatScore
                            kamikazeScore
                            pollution
                            aNe
                            aRNe
                            squads
                            baseCreated
                            hives
                            traps
                            utility
                            vg)
                #:transparent)

        (struct Chunk (kamikazeScore
                       retreatScore
                       siegeScore
                       settleScore
                       attackScore
                       x
                       y
                       movement
                       base
                       player
                       resource
                       passable
                       tick
                       rating
                       nests
                       worms
                       rally
                       retreat
                       resourceGen
                       playerGen
                       deathGen
                       pollution
                       aNe
                       aRNe
                       squads
                       baseCreated
                       hives
                       traps
                       utility
                       vg)
                #:transparent)

        (require threading)

        (define (getFile filePath)
          (call-with-input-file filePath
            (lambda (port)
              (port->string port))))

        (define (stringToChunk str)
          (match-let (((list movement base player resource passable tick rating x y nest
                             worms rally retreat resourceGen playerGen deathGen pollution aNe aRNe squads
                             baseCreated hives traps utility vg) (string-split str ",")))
            (apply Chunk
                   (cons (+ (string->number base)
                            (* (string->number player) 100))
                         (cons (+ (- (string->number base))
                                  (string->number deathGen)
                                  (- (string->number playerGen))
                                  (- (* (string->number player) 100)))
                               (cons (+ (string->number resource)
                                        (string->number base)
                                        (* (string->number player) 100))
                                     (cons (+ (- (string->number deathGen))
                                              (string->number resource)
                                              (- (* (string->number player) 100)))
                                           (cons (+ (- (string->number deathGen))
                                                    (string->number base)
                                                    (* (string->number player) 100))
                                                 (map string->number
                                                      (list x y movement base player resource passable tick rating nest
                                                            worms rally retreat resourceGen playerGen deathGen pollution aNe
                                                            aRNe squads baseCreated hives traps utility vg))))))))))
        
        (define (chunk->string chunk)
          (string-append "x: " (~v (Chunk-x chunk)) "\n"
                         "y: " (~v (Chunk-y chunk)) "\n"
                         "m: " (~v (Chunk-movement chunk)) "\n"
                         "b: " (~v (Chunk-base chunk)) "\n"
                         "p: " (~v (Chunk-player chunk)) "\n"
                         "r: " (~v (Chunk-resource chunk)) "\n"
                         "pass: " (~v (Chunk-passable chunk)) "\n"
                         "tic: " (~v (Chunk-tick chunk)) "\n"
                         "rat: " (~v (Chunk-rating chunk)) "\n"
                         "ne: " (~v (Chunk-nests chunk)) "\n"
                         "wo: " (~v (Chunk-worms chunk)) "\n"
                         "rall: " (~v (Chunk-rally chunk)) "\n"
                         "retr: " (~v (Chunk-retreat chunk)) "\n"
                         "rGen: " (~v (Chunk-resourceGen chunk)) "\n"))

        (define (chunk->string2 chunk)
          (string-append "pGen: " (~v (Chunk-playerGen chunk)) "\n"
                         "dGen: " (~v (Chunk-deathGen chunk)) "\n"
                         "aSco: " (~v (Chunk-attackScore chunk)) "\n"
                         "sSco: " (~v (Chunk-settleScore chunk)) "\n"
                         "sSei: " (~v (Chunk-siegeScore chunk)) "\n"
                         "sRet: " (~v (Chunk-retreatScore chunk)) "\n"
                         "pol: " (~v (Chunk-pollution chunk)) "\n"
                         "aNe: " (~v (Chunk-aNe chunk)) "\n"
                         "aRNe: " (~v (Chunk-aRNe chunk)) "\n"
                         "sqs: " (~v (Chunk-squads chunk)) "\n"
                         "bC: " (~v (Chunk-baseCreated chunk)) "\n"
                         "H: " (~v (Chunk-hives chunk)) "\n"
                         "T: " (~v (Chunk-traps chunk)) "\n"
                         "U: " (~v (Chunk-utility chunk)) "\n"
                         "vg: " (~v (Chunk-vg chunk)) "\n"))

        (define (normalizeRange xs)
          (let* ((sDev (stddev xs))
                 (sMean (mean xs))
                 (target (* 2.5 sDev))
                 (cleanXs (filter (lambda (x)
                                    (<= (abs (- x sMean)) target))
                                  xs)))
            (MinMax (apply min cleanXs)
                    (apply max cleanXs))))

        (define (findChunkPropertiesMinMax chunks)
          (let ((xs (map Chunk-x chunks))
                (ys (map Chunk-y chunks))
                (movements (map Chunk-movement chunks))
                (bases (map Chunk-base chunks))
                (players (map Chunk-player chunks))
                (resources (map Chunk-resource chunks))
                (passables (map Chunk-passable chunks))
                (ticks (map Chunk-tick chunks))
                (ratings (map Chunk-rating chunks))
                (nests (map Chunk-nests chunks))
                (worms (map Chunk-worms chunks))
                (rallys (map Chunk-rally chunks))
                (retreats (map Chunk-retreat chunks))
                (rGens (map Chunk-resourceGen chunks))
                (pGens (map Chunk-playerGen chunks))
                (dGens (map Chunk-deathGen chunks))
                (aSco (map Chunk-attackScore chunks))
                (sSco (map Chunk-settleScore chunks))
                (sSei (map Chunk-siegeScore chunks))
                (sRet (map Chunk-retreatScore chunks))
                (sKam (map Chunk-kamikazeScore chunks))
                (pol (map Chunk-pollution chunks))
                (aNe (map Chunk-aNe chunks))
                (aRNe (map Chunk-aRNe chunks))
                (sqs (map Chunk-squads chunks))
                (bC (map Chunk-baseCreated chunks))
                (H (map Chunk-hives chunks))
                (T (map Chunk-traps chunks))
                (U (map Chunk-utility chunks))
                (vg (map Chunk-vg chunks)))

            (ChunkRange (MinMax (apply min xs) (apply max xs))
                        (MinMax (apply min ys) (apply max ys))
                        (normalizeRange movements)
                        (normalizeRange bases)
                        (normalizeRange players)
                        (normalizeRange resources)
                        (MinMax (apply min passables) (apply max passables))
                        (normalizeRange ticks)
                        (normalizeRange ratings)
                        (MinMax (apply min nests) (apply max nests))
                        (MinMax (apply min worms) (apply max worms))
                        (MinMax (apply min rallys) (apply max rallys))
                        (MinMax (apply min retreats) (apply max retreats))
                        (MinMax (apply min rGens) (apply max rGens))
                        (MinMax (apply min pGens) (apply max pGens))
                        (MinMax (apply min dGens) (apply max dGens))
                        (normalizeRange aSco)
                        (normalizeRange sSco)
                        (normalizeRange sSei)
                        (normalizeRange sRet)
                        (normalizeRange sKam)
                        (normalizeRange pol)
                        (MinMax (apply min aNe) (apply max aNe))
                        (MinMax (apply min aRNe) (apply max aRNe))
                        (MinMax (apply min sqs) (apply max sqs))
                        (MinMax (apply min bC) (apply max bC))
                        (MinMax (apply min H) (apply max H))
                        (MinMax (apply min T) (apply max T))
                        (MinMax (apply min U) (apply max U))
                        (MinMax (apply min vg) (apply max vg)))
            ))

        (define (readState filePath)
          (let* ((replayChunks (getFile filePath))
                 (chunks (map stringToChunk (string-split replayChunks "\n")))
                 (minMaxes (findChunkPropertiesMinMax chunks)))
            (AiState chunks
                     (apply hash
                            (apply append
                                   (map (lambda (chunk)
                                          (list (list (Chunk-x chunk)
                                                      (Chunk-y chunk))
                                                chunk))
                                        chunks)))
                     minMaxes)))

        (define (test)
          (AiState-minMaxes (readState "/data/games/factorio/script-output/rampantState.txt"))))
