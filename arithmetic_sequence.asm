global arithmetic_sequence

section .text

; get r = A1 - A0
; - handle overflow
; - handle sign
; check r and k sign
; - if r < 0 inverse to positive
; - if k < 0 inverse to positive
; multiply r * k
; - 
; if r * k < 0 inverse to positive
; add A0 + r*k
;

get_r_loop:
  mov r9, [rdi + 8 * r11] ; take A0 i block
  mov rax, [rsi + 8 * r11] ; take A1 i block

  sbb rax, r9 
  mov qword [rdx + 8 * r11], rax ; place A1 - A0 to Ak
  
  inc r11
  dec r10

  jnz get_r_loop
  
  ; if overflow, then substract CF and r15(high bits) 
  sbb r15, 0
  clc
  ret
  
; calculates A1 - A0 and handle overflow scenario
get_r:
  mov r10 , rcx ; iterates n to 0
  xor r11, r11 ; iterates 0 to n

  ; if A1 - A0 is overflowing 64n, i need to expand r15,
  ; and save sign bit, and then store overflow bits
  dec r10
  mov r9, [rdi + 8 * r10]
  mov r15, [rsi + 8 * r10]
  
  sar r9, 63
  sar r15, 63 
  sub r15, r9
  
  inc r10

  clc ; reset carry flag
  jmp get_r_loop
  
invert_k_sign:
  not r8
  inc r8
  ret

r_change_sign_loop:
  mov rax, [rdx + 8 * r11]
  not rax
  adc rax, 0
  mov qword [rdx + 8 * r11], rax

  inc r11
  dec r10

  jnz r_change_sign_loop
  
  ; change sign of high bits
  not r15
  not r13

  adc r15, 0
  adc r13, 0
  ret 

; inverts r sign 
r_change_sign:
  mov r10, rcx
  xor r11, r11
  stc ; set carry flag

  jmp r_change_sign_loop

check_k_sign:
  test r8, r8
  js invert_k_sign
  ret

check_r_sign:
  test r15, r15

  ; jump if r is negative 
  js r_change_sign 
  
  ret  


multiply_k_and_r_loop:
  mov rax, [r9 + 8 * r11] ; r block
 
  mul r8 ; after mul: rax - low bits, rdx - high bits of multiplication

  add r12, rax ; add acc + low bits + CF(prev rdx + CF)
  adc rdx, 0 ; save CF(acc + low bits)
  mov [r9 + 8 * r11], r12 ; save low bits + acc to [Ak]

  mov r12, rdx ; move high bits to acc
  
  inc r11
  dec r10 

  jnz multiply_k_and_r_loop
  
  mov r12, rdx ; save high bits of multiplication

  mov rax, r15
  mul r8
  mov r15, rax
  mov r13, rdx
  
  add r15, r12 ; TODO: is CF possible?? 
  adc r13, 0

  mov rdx, r9 ; rdx - *Ak 

  ret

multiply_k_and_r:
  mov r9, rdx ; r9 - *Ak

  xor r12, r12 ; accumualtor
  mov r10, rcx ; iterator from n to 0
  xor r11, r11 ; iterator from 0 to n

  clc ; reset CF

  jmp multiply_k_and_r_loop

check_result_sign:
  cmp r14, 0
  jne r_change_sign
  ret

add_A0_and_result_loop:
  mov rax, [rdi + 8 * r11] ; A0 
  mov r9, [rdx + 8 * r11]  ; Ak

  adc r9, rax
  mov qword [rdx + 8 * r11], r9 

  inc r11
  dec r10

  jnz add_A0_and_result_loop
  setc r9b ; set carry flag 
  sar rax, 63
  shr r9b, 1
  adc r15, rax
  adc r13, rax

  ret

add_A0_and_result:
  mov r10, rcx
  xor r11, r11

  clc ; reset CF flag 
  
  jmp add_A0_and_result_loop

; args: rdi - *A0, rsi - *A1, rdx - *Ak, rcx - n, r8 - k 
; output: rax - uint128.low, rdx - uint128.hi, starsze bity Ak
arithmetic_sequence:
  push r12
  push r15
  push r14 ; stores r * k sign flag
  push r13 ; the highest bits
  
  xor r13, r13
  xor r15, r15

  call get_r

  mov r14, r15
  xor r14, r8
  shr r14, 63 

  call check_r_sign
  call check_k_sign
  call multiply_k_and_r
  call check_result_sign
  call add_A0_and_result
  
  mov rax, r15
  mov rdx, r13

  ; adc rdx, 0

  pop r13
  pop r14
  pop r15
  pop r12

  ret
