.global init

.eqv GPIO_ENABLE_REG, 0x60004020

.eqv GPIO_OUT_REG, 0x60004004 
.eqv GPIO_OUT_W1TS_REG, 0x60004008
.eqv GPIO_OUT_W1TC_REG, 0x6000400C

.eqv GPIO_IN_REG, 0x6000403C

.eqv IO_MUX_GPIO4_REG, 0x60009014   # Thiết lập chức năng chân GPIO4
.eqv IO_MUX_GPIO5_REG, 0x60009018   # Thiết lập chức năng chân GPIO5
.eqv IO_MUX_GPIO6_REG, 0x6000901C   # Thiết lập chức năng chân GPIO6
.eqv IO_MUX_GPIO7_REG, 0x60009020   # Thiết lập chức năng chân GPIO7

.eqv GPIO0, 0x01
.eqv GPIO1, 0x02
.eqv GPIO2, 0x04
.eqv GPIO3, 0x08
.eqv GPIO4, 0x10
.eqv GPIO5, 0x20
.eqv GPIO6, 0x40
.eqv GPIO7, 0x80

.eqv GPIO8, 0x100
.eqv GPIO9, 0x200
.eqv GPIO20, 0x100000
.eqv GPIO21, 0x200000

.data
  digits: .word 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90

.text
init:
  # Thiết lập các giá trị mặc định
  li s0, 1  # Mode
  li s1, 0  # Mode 1: Trạng thái LED1
  li s2, 1  # Mode 2: LED bật đầu tiên
  li s3, 0  # Mode3, 4: Số hiện đầu tiên
  la s4, digits

  # Thiết lập chức năng các chân GPIO4, GPIO5, GPIO6, GPIO7
  # Mặc định các chân này được sử dụng cho giao thức SPI
  # Cần chuyển chức năng sang GPIO

  li a2, 0x1000           

  li a1, IO_MUX_GPIO4_REG
  sw a2, 0(a1)

  li a1, IO_MUX_GPIO5_REG
  sw a2, 0(a1)

  li a1, IO_MUX_GPIO6_REG
  sw a2, 0(a1)

  li a1, IO_MUX_GPIO7_REG
  sw a2, 0(a1)

  # Thiết lập GPIO0-7 là output
  li a1, GPIO_ENABLE_REG    # Thiết lập GPIO0 là chân output
  li a2, 0xFF
  sw a2, 0(a1)            

main_loop:

  li a1, GPIO_IN_REG    # Đọc trạng thái các chân GPIO
  lw a2, 0(a1)

  li a3, GPIO8
  and a4, a2, a3       # Kiểm tra GPIO8
  beq a4, zero, PB1_pressed   # Nếu GPIO8 = 0
  
  li a3, GPIO9
  and a4, a2, a3       # Kiểm tra GPIO9
  beq a4, zero, PB2_pressed   # Nếu GPIO9 = 0

  li a3, GPIO20
  and a4, a2, a3       # Kiểm tra GPIO20
  beq a4, zero, PB3_pressed   # Nếu GPIO20 = 0

  li a3, GPIO21
  and a4, a2, a3       # Kiểm tra GPIO21
  beq a4, zero, PB4_pressed   # Nếu GPIO21 = 0

  j check_mode

PB1_pressed:
  li s0, 1
  j check_mode

PB2_pressed:
  li s0, 2
  j check_mode

PB3_pressed:
  li s0, 3
  j check_mode

PB4_pressed:
  li s0, 4
  j check_mode

check_mode:  
  li t0, 1
  beq s0, t0, mode_1
  li t0, 2
  beq s0, t0, mode_2
  li t0, 3
  beq s0, t0, mode_3
  li t0, 4
  beq s0, t0, mode_4
  
  j next

mode_1:
  addi a2, s1, 0
  call fun_update_leds

  xori s1, s1, 1
  j next

mode_2:
  addi a2, s2, 0
  call fun_update_leds

  slli s2, s2, 1
  li t2, 0x100
  bne s2, t2, next
  li s2, 1
  j next

mode_3:
  sll t3, s3, 2           # Xác định địa chỉ phần tử cần truy nhập
  add t3, t3, s4
  lw a2, 0(t3)
  call fun_update_leds

  addi s3, s3, 1          # Chuyển sang chữ số tiếp theo
  li  t3, 10
  blt s3, t3, next
  xor s3, s3, s3
  j next

mode_4:
  j next

next:
  j main_loop               # Loop

# Chương trình con cập nhật giá trị GPIO0-7
# Tham số:
# a2 - giá trị cập nhật

fun_update_leds:
  addi sp, sp, -12
  sw ra, 0(sp)
  sw a0, 4(sp)
  sw a1, 8(sp)

  li a1, GPIO_OUT_REG
  sw a2, 0(a1) 

  li a0, 10000000
  call fun_delay

  lw a1, 8(sp)
  lw a0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 12
  ret

# Chương trình con delay, chờ một khoảng thời gian
# Tham số:
# a0 - số vòng lặp
fun_delay:
  addi sp, sp, -8
  sw ra, 0(sp)
  sw t0, 4(sp)

  mv t0, a0
loop_delay:
  addi t0, t0, -1            
  bne t0, zero, loop_delay

  lw t0, 4(sp)
  lw ra, 0(sp)
  addi sp, sp, 8
  ret