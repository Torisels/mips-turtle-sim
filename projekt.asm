# Mips duzy projekt: 3.14
# Gustaw Daczkowski, grupa 108 

.eqv BMP_FILE_SIZE 90122
.eqv BYTES_PER_ROW 1800
.eqv X_DIM 599
.eqv Y_DIM 49
.eqv MAX_BIN_FILE_SIZE 256

.eqv INS_SET_POS 0x03
.eqv INS_SET_DIR 0x02
.eqv INS_MOVE 0x01
.eqv INS_SET_PEN 0x00

.eqv RS_POS_X 6
.eqv RS_POS_Y 2
.eqv RS_DIR 2
.eqv RS_MOVE 2
.eqv RS_SET_PEN_MODE 3
.eqv RS_SET_PEN_COLR 10

.eqv DIR_R 0x00
.eqv DIR_U 0x01
.eqv DIR_L 0x02
.eqv DIR_D 0x03

.eqv MASK_DIR 0x03
.eqv MASK_SET_PEN_UD 0x01
.eqv MASK_MOVE 0x03FF

.eqv COLR_BLACK 0x000000
.eqv COLR_RED   0xFF0000
.eqv COLR_GREEN 0x00FF00
.eqv COLR_BLUE  0x0000FF
.eqv COLR_YELL  0xFFFF00
.eqv COLR_CYAN 	0x00FFFF
.eqv COLR_PURPL 0xFF00FF
.eqv COLR_WHITE 0xFFFFFF

.eqv PEN_UP 0x00
.eqv PEN_DOWN 0x01

	  .data
	  .align 4
res:	  .space 2
image:	  .space BMP_FILE_SIZE
bin_file: .space MAX_BIN_FILE_SIZE



bin_name: 	.asciiz "input_2.bin"
bmp_input_name: .asciiz "source.bmp"
bmp_output_name:.asciiz "output_2.bmp"
file_error_b: 	.asciiz "Instruction file not found. Terminating!"
file_error_i: 	.asciiz "Input bmp file not found. Terminating!"
colors:     	.word COLR_BLACK, COLR_RED, COLR_GREEN, COLR_BLUE, COLR_YELL, COLR_CYAN, COLR_PURPL, COLR_WHITE	
	
	.text
main:
	jal 	read_bin_file
	jal 	read_bmp
	move 	$s1, $v1 	#store n of bytes from file in $s1 
	la 	$s0, bin_file
	add 	$s1, $s1, $s0 	#S1 will hold end of the bin file buffer - end of instruction set
	
	li 	$s2, PEN_UP	#pen is up by default
	li 	$s3, COLR_WHITE	#white is default for pen color
	
	li 	$s4, 0 		#X position
	li 	$s5, 0 		#Y position
	
	li 	$s6, 1 		#1: up| -1:down| 0: no move
	li 	$s7, 0		#1: right| -1: left| 0: no move
	
	
main_loop:
	lbu 	$t0, 0($s0) # t0 will hold instructions (16 bit)
	sll 	$t0, $t0, 8
	lbu  	$t1, 1($s0)
	or 	$t0, $t0, $t1
	and 	$t1, $t0, 0x0003 #t1 holds only type of instruction
	
	# first we need to decode instruction type:
	beq	$t1, INS_SET_POS, set_pos #INS: SET_POSITION
	beq	$t1, INS_SET_DIR, set_dir #INS: SET_DIRECTION
	beq	$t1, INS_MOVE, move_by	  #INS: MOVE
	beq	$t1, INS_SET_PEN, set_pen #INS: SET_PEN
	
#CASE SET_POSITION=======================================================
set_pos:
	srl 	$s4, $t0, RS_POS_X	#store X pos in $S4 after right shift
	lbu	$t1, 2($s0)	 	#load raw Y pos to t1
	srl	$s5, $t1, RS_POS_Y	#shift right and store Y in s5
	add 	$s0, $s0, 4		#add 4 because SET_POS is 32bit instruction
	blt 	$s0, $s1, main_loop	#jump to another iteration
	j	exit			#or to exit if counter is finished
#CASE SET_DIRECTION======================================================
set_dir:
	srl	$t1, $t0, RS_DIR 	#shift right by two bits
	and	$t1, $t1, MASK_DIR 	#mask in order to get rid of unwanted bits and store into t1
	beq 	$t1, DIR_R, dir_right	#CASE DIR_RIGHT
	beq 	$t1, DIR_U, dir_up	#CASE DIR_UP
	beq 	$t1, DIR_L, dir_left	#CASE DIR_LEFT
	beq 	$t1, DIR_D, dir_down	#CASE DIR_DOWN
	j 	exit			#something went wrong
	
dir_right:
	li	$s6, 0			#NO MOVE in vertical direction
	li	$s7, 1			#1 - right
	add 	$s0, $s0, 2
	blt 	$s0, $s1, main_loop
	j	exit


dir_up:
	li	$s6, 1			#1 - UP
	li	$s7, 0			#0 NO MOVE in horizontal direction
	add 	$s0, $s0, 2
	blt 	$s0, $s1, main_loop
	j	exit

dir_left:
	li	$s6, 0			#NO MOVE in vertical direction
	li	$s7, -1			#-1 - left
	add 	$s0, $s0, 2
	blt 	$s0, $s1, main_loop
	j	exit

dir_down:
	li	$s6, -1			#-1 - DOWN
	li	$s7, 0			#0 NO MOVE in horizontal direction
	add 	$s0, $s0, 2
	blt 	$s0, $s1, main_loop
	j	exit
#CASE MOVE============================================================================
move_by:
	srl 	$t1, $t0, RS_MOVE
	and	$t1, $t1, MASK_MOVE	#t1 holds current move value
	mul	$t4, $s7, $t1		#t4 holds amount to move in horizontal dir (X)
	mul 	$t5, $s6, $t1		#t5 holds amount to move in vertical dir (Y)
	
	add 	$t4, $s4, $t4		#t4 is now future X position
	add 	$t5, $s5, $t5		#t5 is now future Y position 
	
	#check for boundaries
	sgt	$t8, $t4, 0		#if t4 < 0, then t8 will be 0, 1 otherwise
	mul 	$t4, $t8, $t4		#t4 is now zero if it was less than 0

	sgt	$t8, $t5, 0		#if t5 < 0, then t8 will be 0, 1 otherwise
	mul 	$t5, $t8, $t5		#t5 is now zero if it was less than 0
	
	ble	$t4, X_DIM, y_bound	#check if x > 600
	li	$t4, X_DIM		#and load 600 if the above condition was achieved
y_bound:
	ble	$t5, Y_DIM, move_then	#check if y > 50
	li	$t5, Y_DIM		#and load 50 if the above condition was achieved

#This version of code was written in order to get rid of jumps, but contains more instructions and is not optimal
	#sle	$t8, $t4, X_DIM 
	#mul	$t4, $t8, $t4
	#xor 	$t8, $t8, 1
	#mul	$t8, $t8, X_DIM
	#add 	$t4, $t4, $t8  
	
	#sle	$t8, $t5, Y_DIM 
	#mul	$t5, $t8, $t5
	#xor 	$t8, $t8, 1
	#mul	$t8, $t8, Y_DIM
	#add 	$t5, $t5, $t8
	#end check for boundaries
#End of experimental section
	
move_then:	
	beq 	$s2, PEN_DOWN, move_loop #If the pen is down go to the drawing loop
	move 	$s4, $t4		 #else: perform copying and go to another iteration
	move 	$s5, $t5		 #copy desired Y pos from t5 to s5
	add 	$s0, $s0, 2		 #add two to main iterator
	blt 	$s0, $s1, main_loop	
	j	exit
	
move_loop:
	move 	$a0, $s4		#load X pos to a0 
	move 	$a1, $s5		#load Y pos to a1
	move 	$a2, $s3		#load color to a2
	jal 	put_pixel		#draw in the memory
		
	add 	$s4, $s4, $s7		#perform addition in order to update position (X)
	add	$s5, $s5, $s6		#the same with Y pos
	
	bne	$s4, $t4, move_loop	#if the current position is not equal to desired move again. (X)
	bne 	$s5, $t5, move_loop	#the same with Y pos
	
	move 	$a0, $s4		#the iteration is finished, but last pixel also must be put on the image
	move 	$a1, $s5
	move 	$a2, $s3
	jal 	put_pixel
	
	add 	$s0, $s0, 2		#on the end increment main counter
	blt 	$s0, $s1, main_loop	#and jump to main loop again
	j	exit			#or exit if program counter has finished

#CASE SET_PEN==============================================================
set_pen:
	srl 	$t1, $t0, RS_SET_PEN_MODE	#right shift contents of instruction to get pen mode
	and 	$s2, $t1, MASK_SET_PEN_UD	#mask t1 in order to get proper contents and store in global s2
	srl	$t1, $t1, RS_SET_PEN_COLR	#shift t1 in order to get color index
	
	la 	$t2, colors		#load address of color table
	sll	$t1, $t1, 2		#multiply by 4
	add 	$t1, $t1, $t2		#add: t1 = t1 + t2
	lw	$s3, 0($t1)		#load color from specified address with offset 
	
	add 	$s0, $s0, 2		#incerment main counter
	blt 	$s0, $s1, main_loop	#jump to main loop
	j	exit			#or exit when instruction counter is after last instruction

#EXIT==========================================================================			
exit:	
	jal save_bmp			#call save bmp to save file
	li $v0, 10			#set code 10 for proper termination
	syscall				#terminate



# ============================================================================
read_bin_file:
#description: 
#	reads the contents binary instruction file into memory
#arguments:
#	none
#return value: number of bytes read stored in $v1

	li 	$v0, 13
        la 	$a0, bin_name		#file name 
        li 	$a1, 0			#flags: 0-read file
        li 	$a2, 0			#mode: ignored
        syscall
	move 	$t1, $v0      		# save the file descriptor
	
	
	#if descriptor is lower than 0 then terminate the program with message
	bgt	$t1, 0, read
	li	$v0, 4  
	la 	$a0, file_error_b
	syscall
	li 	$v0, 10
	syscall

read:
	li	$v0, 14
	move	$a0, $t1
	la	$a1, bin_file
	li	$a2, MAX_BIN_FILE_SIZE
	syscall
	move 	$v1, $v0

#close file
	li 	$v0, 16
        syscall
	jr 	$ra
# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, 0($sp)
#open file
	li 	$v0, 13
        la 	$a0, bmp_input_name	#file name 
        li 	$a1, 0			#flags: 0-read file
        li 	$a2, 0			#mode: ignored
        syscall
	move 	$s1, $v0      		#save the file descriptor
	
	bgt	$s1, 0, readff
	li	$v0, 4  
	la 	$a0, file_error_i
	syscall
	li 	$v0, 10
	syscall
readff:
#read file
	li 	$v0, 14
	move 	$a0, $s1
	la 	$a1, image
	li 	$a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 0($sp)			#restore (pop) $s1
	add $sp, $sp, 4
	jr $ra

# ============================================================================	
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub 	$sp, $sp, 4		#push $s1
	sw 	$s1, 0($sp)
#open file
	li 	$v0, 13
        la 	$a0, bmp_output_name	#file name 
        li 	$a1, 1		#flags: 1-write file
        li 	$a2, 0		#mode: ignored
        syscall
	move 	$s1, $v0      	#save the file descriptor
	
	bgt	$s1, 0, save_im
	li	$v0, 4  
	la 	$a0, file_error_i
	syscall
	li 	$v0, 10
	syscall


#save file
save_im:
	li 	$v0, 15
	move 	$a0, $s1
	la 	$a1, image
	li 	$a2, BMP_FILE_SIZE
	syscall

#close file
	li 	$v0, 16
	move 	$a0, $s1
        syscall
	
	lw 	$s1, 0($sp)		#restore (pop) $s1
	add 	$sp, $sp, 4
	jr 	$ra
# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none
	la 	$t1, image + 10		#adress of file offset to pixel array
	lw 	$t2, ($t1)		#file offset to pixel array in $t2
	la 	$t1, image		#adress of bitmap
	add 	$t2, $t1, $t2		#adress of pixel array in $t2
	
	#pixel address calculation
	mul 	$t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move 	$t3, $a0		
	sll 	$a0, $a0, 1
	add 	$t3, $t3, $a0		#$t3 = 3*x
	add 	$t1, $t1, $t3		#$t1 = 3x + y*BYTES_PER_ROW
	add 	$t2, $t2, $t1		#pixel address 
	
	#set new color
	sb 	$a2, ($t2)		#store B
	srl 	$a2, $a2, 8
	sb 	$a2, 1($t2)		#store G
	srl 	$a2, $a2, 8
	sb 	$a2, 2($t2)		#store R

	jr 	$ra
# ============================================================================
