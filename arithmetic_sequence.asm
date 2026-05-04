global arithmetic_sequence

section .text

init_krok_loop:
  ; get blocks of A0 and A1
  mov r10, [rdi + 8 * rax] ; block A0
  mov r11, [rsi + 8 * rax] ; block A1
  ; substract them
  sbb r11, r10 ; A1 - A0

  ; add result to krok[block]
  mov qword [rdx + 8 * rax], r11 
  ; loop things
  inc rax
  dec r9

  jnz init_krok_loop
 
  adc r13, 0
  sar r11, 63 ; reset r11, but save sign
  add r13, r11 ; r13 will save if A1 - A0 is overflowing

  ret

init_krok: 
  xor rax, rax ; iterator from 0 to n
  mov r9, rcx ; r9 - iterator from n to 0

  clc ; reset CF flag 
  jmp init_krok_loop

multiply_end:
  mov rdx, rbp
  ret

multiply_loop: 
  mov rax, [rbp + r11 * 8] ; krok block

  ; rax - low bits, rdx - high bits
  mul r8
  
  add r12, rax ; add acc to low bits
  adc rdx, 0
  mov [rbp + r11 * 8], r12 ; save low bits + acc to [Ak]
  
  mov r12, rdx ; move high bits to acc
  
  inc r11
  dec r10
  jnz multiply_loop

  jmp multiply_end

multiply:
  mov rbp, rdx ; rsp - *Ak
  
  xor r12, r12 ; accumualtor
  mov r10, rcx ; iterator from n to 0
  xor r11, r11 ; iterator from 0 to n

  jmp multiply_loop

big_int_change_sign_loop:
  mov rax, [rbp + 8 * r11]
  not rax
  adc rax, 0
  mov qword [rbp + 8 * r11], rax

  inc r11
  dec r10

  jnz big_int_change_sign_loop
  
  ; invert r12 - high bits 
  not r12
  adc r12, 0 ; TODO: what if after comand CF = 1?

  ret
  
; rbp - pointer to big int  
big_int_change_sign:
  mov r10, rcx
  xor r11, r11
  stc ; set carry flag

  jmp big_int_change_sign_loop
 
  
check_krok:
  mov r10, rcx;
  dec r10 ; r10 = n - 1
  mov rbx, [rdx + 8 * r10]
  test rbx, rbx

  ; if high bit is == 0, then rax == 0
  mov rbp, rdx
  js big_int_change_sign 
  
  ret  

; chnage sign of 64bit number 
; args: r9
; output: edits r9
change_sign:
  not r8
  inc r8
  ret

check_k:
  test r8, r8
  js change_sign

  ret
  
check_krok_sign: 
  mov rbp, rdx
  cmp rbx, 0
  jne big_int_change_sign
  ret

add_two_big_numbers_loop:
  mov rbp, [rdi + 8 * r11]
  mov rbx, [rdx + 8 * r11]

  adc rbx, rbp
  mov qword [rdx + 8 * r11], rbx 

  inc r11
  dec r10

  jnz add_two_big_numbers_loop
  ret

add_two_big_numbers:
  mov r10, rcx
  xor r11, r11
  clc ; reset CF flag 
  jmp add_two_big_numbers_loop

; args: rdi - *A0, rsi - *A1, rdx - *Ak, rcx - n, r8 - k 
; output: rax - uint128.low, rdx - uint128.hi, starsze bity Ak
arithmetic_sequence:
  push rbx
  push rbp
  push r12
  push r13

  xor r12, r12
  xor r13, r13
  call init_krok ; init r = A1 - A0 
  ; TODO: what if A1 - A0 is overflow 

  ; --- now i have 64n low bits in *Ak and 64 high bits in r13 

  ; check is krok < 0
  ; save in RBX original high krok blok
  call check_krok

  ; save in RBX SF of k * krok 
  xor rbx, r8
  shr rbx, 63

  ; check is k < 0
  call check_k

  call multiply ; k * r
 
  ; if RNX_SF == 1 change sign   
  ; maybe i can add this to multiply_end but there are pop that 
  call check_krok_sign
  
  mov r13, rcx
  dec r13
  mov r13, [rdi + 8 * r13]
  sar r13, 63
  
  call add_two_big_numbers

  mov rax, r12
  adc rax, r13 

  ; krok = A1 - A0 
  ; check is k < 0 and krok < 0
  ; - if (k < 0 and krok < 0) or (k > 0 and krok > 0), is negative bit = 0
  ; - if(k > 0 and krok < 0) or (k < 0 or krok > 0) is negative bit = 1
  ; -- negative bit = xor (last bit k), (last bit krok)
  ; - if k < 0, abs(k)
  ; - if krok < 0, abs(krok)
  ; result = multiply k and krok
  ; check is negative bit
  ; - if(negative == 1) (inverse result) + 1
  ; A0 + result
  
  ; output
  cqo
  
  pop r13
  pop r12
  pop rbp
  pop rbx
  ret



