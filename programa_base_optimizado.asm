.data
    vector_x: .word 1, 2, 3, 4, 5, 6, 7, 8
    vector_y: .space 32
    const_a:  .word 3
    const_b:  .word 5
    tamano:   .word 8

.text
.globl main
main:
    # --- Inicialización de punteros y constantes ---
    la $s0, vector_x          # $s0 = puntero actual a X[i]
    la $s1, vector_y          # $s1 = puntero actual a Y[i]
    lw $t0, const_a           # $t0 = A = 3
    lw $t1, const_b           # $t1 = B = 5
    lw $t2, tamano            # $t2 = 8 (número de elementos)

    # Pre-calculamos el límite FUERA del loop (evita cálculo repetido)
    sll $t2, $t2, 2           # $t2 = 8 * 4 = 32 bytes
    addu $s2, $s0, $t2        # $s2 = &X[8] = dirección de parada

    # LOOP UNROLLING: procesamos 2 elementos por iteración
    # Ventaja: las instrucciones del elemento i+1 llenan los huecos
    #          de dependencia del elemento i, eliminando stalls.
    # Requisito: el vector debe tener número par de elementos (aquí 8, OK).
loop:
    # === CARGA DE X[i] y X[i+1] ===
    lw $t6, 0($s0)            # $t6 = X[i]
    lw $t3, 4($s0)            # $t3 = X[i+1]  ← ocupa el Load-Use slot de $t6

    # === MULTIPLICACIÓN ===
    mul $t7, $t6, $t0         # $t7 = X[i] * A      | $t6 ya disponible (2 ciclos pasaron)
    mul $t4, $t3, $t0         # $t4 = X[i+1] * A    | llena el RAW slot de mul→addu de i

    # === SUMA CON B ===
    addu $t8, $t7, $t1        # $t8 = X[i]*A + B
    addu $t5, $t4, $t1        # $t5 = X[i+1]*A + B  | llena el RAW slot de mul→addu de i+1

    # === ALMACENAMIENTO ===
    sw $t8, 0($s1)            # Y[i]   = $t8
    sw $t5, 4($s1)            # Y[i+1] = $t5

    # === AVANCE DE PUNTEROS (2 elementos = 8 bytes) ===
    addiu $s0, $s0, 8         # X += 2 posiciones
    addiu $s1, $s1, 8         # Y += 2 posiciones

    # === CONDICIÓN DE SALIDA ===
    bne $s0, $s2, loop        # Si no llegamos al límite, repetir

fin:
    li $v0, 10
    syscall