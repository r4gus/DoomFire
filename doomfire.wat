(module
    ;; PRNG
    (import "env" "rand" (func $rand (result f64)))

    ;; Canvas size = $width * $height
    (global $width i32 (i32.const 320))
    (global $height i32 (i32.const 168))

    ;; Memory
    (memory (export "mem") 5)
    (global $fire_pixels i32 (i32.const 0))
    (global $canvas (export "canvas") i32 (i32.const 53_760))
    (global $color_pallet i32 (i32.const 268_800))
    
    ;; Color pallet (37 rgba colors) ranging from:
    ;;   0: #070707ff -> black
    ;; to
    ;;   36: #ffffffff -> white
    (data (i32.const 268_800)
    "\07\07\07\FF\1F\07\07\FF\2F\0F\07\FF\47\0F\07\FF\57\17\07\FF\67\1F\07\FF"
    "\77\1F\07\FF\8F\27\07\FF\9F\2F\07\FF\AF\3F\07\FF\BF\47\07\FF\C7\47\07\FF"
    "\DF\4F\07\FF\DF\57\07\FF\DF\57\07\FF\D7\5F\07\FF\D7\5F\07\FF\D7\67\0F\FF"
    "\CF\6F\0F\FF\CF\77\0F\FF\CF\7F\0F\FF\CF\87\17\FF\C7\87\17\FF\C7\8F\17\FF"
    "\C7\97\1F\FF\BF\9F\1F\FF\BF\9F\1F\FF\BF\A7\27\FF\BF\A7\27\FF\BF\AF\2F\FF"
    "\B7\AF\2F\FF\B7\B7\2F\FF\B7\B7\37\FF\CF\CF\6F\FF\DF\DF\9F\FF\EF\EF\C7\FF"
    "\FF\FF\FF\FF")
    
    ;; Load a 4 byte RGBA color from memory.
    ;; idx - A index between [0, 37) where 0 means black and 36 means white.
    (func $get_color (param $idx i32) (result i64)
        (i64.load 
          (i32.add 
            (global.get $color_pallet)
            (i32.mul (i32.const 4) (local.get $idx))))
    )
    
    ;; Draw the pixel at position $idx on the canvas.
    (func $set_color (param $idx i32) (param $color i64)
        (i64.store
          (i32.add
            (global.get $canvas)
            (i32.mul (i32.const 4) (local.get $idx)))
          (local.get $color))
    )

    (func $init
        (local $offset i32)
        (local $i i32)
        
        (local.set $offset (i32.mul (global.get $width) 
                (i32.sub (global.get $height) (i32.const 1))))

        ;; $i = 0
        (local.set $i (i32.const 0))
        
        ;; Set bottom row to white
        (loop $loop ;; while i < $width
          (i32.store8 offset=0 (i32.add (local.get $offset) (local.get $i))
                      (i32.const 36))
            
          (br_if $loop (i32.lt_u 
            (local.tee $i (i32.add (local.get $i) (i32.const 1)))
            (global.get $width)))
        )     
    )

    (func $do_fire 
        (local $i i32)
        (local $j i32)
        (local $from i32)
        (local $to i32)
        (local $r i32)

        (local.set $i (i32.const 0))

        (loop $outer

            (local.set $j (i32.const 1))
            (loop $inner
                ;; $from = $j * $width + $i
                (local.set $from 
                    (i32.add (i32.mul (local.get $j) (global.get $width))
                             (local.get $i)))
                
                ;; Get random value in [0, 3)
                (local.set $r
                    (i32.and (i32.const 3)
                             (i32.trunc_u/f64
                               (f64.mul (call $rand) (f64.const 3)))))

                ;; $to = $from - $width - $r + 1
                (local.set $to 
                    (i32.add
                        (i32.sub 
                          (i32.sub (local.get $from) (global.get $width))
                          (local.get $r))
                        (i32.const 1)))
                
                ;; fire_pixels[$to] = fire_pixels[$from] - ($r & 1)
                (i32.store8 offset=0 (local.get $to) 
                    (i32.sub
                        (i32.load8_u offset=0 (local.get $from))
                        (i32.and (local.get $r) (i32.const 3))))
    
                ;; $j < $height
                (br_if $inner (i32.lt_u
                    (local.tee $j (i32.add (local.get $j) (i32.const 1)))
                    (global.get $height)))
            )
            
            ;; $i < $width
            (br_if $outer (i32.lt_u
                (local.tee $i (i32.add (local.get $i) (i32.const 1)))
                (global.get $width)))
        )
    )

    (func (export "run")
        (local $i i32)
        (local $ceil i32)
        
        (local.set $i (i32.const 0))
        (local.set $ceil (i32.mul (global.get $width) (global.get $height)))

        (call $do_fire)

        ;; Update canvas 
        (loop $update_loop ;; while $i < $width * $height
            ;; $set_color( $i, $get_color( $i ) )
            (call $set_color (local.get $i) 
                  (call $get_color (i32.load8_u offset=0 (local.get $i))))

            (br_if $update_loop (i32.lt_u
                   (local.tee $i (i32.add (local.get $i) (i32.const 1)))
                   (local.get $ceil)))
        )
    )
    
    (start $init) 
)
