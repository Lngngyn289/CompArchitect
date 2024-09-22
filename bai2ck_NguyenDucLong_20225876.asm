.eqv KEY_CODE 0xFFFF0004  
.eqv KEY_READY 0xFFFF0000                      		
.eqv SCREEN_MONITOR 0x10010000
.data
array_end:	.word	1	# The end of the "circle_points" array
circle_points:		.word		# Array saves all points position of circle 
.text
setup:
	li $s0, 255	# x = 255
	li $s1, 255	# y = 255
	li $s2, 0	# dx = 0
	li $s3, 0	# dy = 0
	li $s4, 20	# r = 20
	li $a0, 40	# t = 40ms/frame
	jal	get_circle_data

input:		
	li	$k0, KEY_READY	# Check whether there is input data
	lw	$t0, 0($k0)
	bne	$t0, 1, edge_check
	jal	direction_change

# Check whether the circle has touched the edge
edge_check:

right:	
	bne	$s2, 1, left
	j	check_right

left:
	bne	$s2, -1, down
	j	check_left
	
down:
	bne	$s3, 1, up
	j	check_down
	
up:
	bne	$s3, -1, move_circle
	j	check_up

move_circle:
	add	$s5, $0, $0	# Set color to black
	jal	draw_circle	# Erase the old circle
	
	add	$s0, $s0, $s2 	# Set x and y to the coordinates of the center of the new circle 
	add	$s1, $s1, $s3 
	li	$s5, 0x00FFFF00	# Set color to yellow
	jal	draw_circle	# Draw the new circle

loop:
	li $v0, 32	 	# Syscall value for sleep
	syscall
	j	input		# Renew the cycle

# Procedure below

get_circle_data:
	addi	$sp, $sp, -4	# Save $ra
	sw 	$ra, 0($sp)
	la 	$s5, circle_points	# $s5 becomes the pointer of the "circle" array
	mul	$a3, $s4, $s4	# $a3 = r^2	
	add	$s7, $0, $0	# pixel x (px) = 0
	
point_of_circle:
	bgt	$s7, $s4, data_end
	mul	$t0, $s7, $s7	# $t0 = px^2
	sub	$a2, $a3, $t0	# $a2 = r^2 - px^2 = py^2
	jal	square_root		# $a2 = py
	add	$a1, $0, $s7	# $a1 = px
	add	$s6, $0, $0	# After saving (px, py), (-px, py), (-px, -py), (px, -py), we swap px and py, then save (-py, px), (py, px), (py, -px), (-py, -px)
	
doiXung:
	beq	$s6, 2, finish
	jal	point_save	# px >= 0 , py >= 0
	sub	$a1, $0, $a1	
	jal	point_save	# px <= 0, py >= 0
	sub	$a2, $0, $a2 
	jal	point_save	# px <= 0, py <= 0
	sub	$a1, $0, $a1	
	jal	point_save	# px >= 0, py <= 0
	
	add	$t0, $0, $a1	# Swap px and -py
	add	$a1, $0, $a2
	add	$a2, $0, $t0
	
	addi	$s6, $s6, 1
	j	doiXung

finish:	
	addi	$s7, $s7, 1
	j	point_of_circle
	
data_end:
	la	$t0, array_end	
	sw	$s5, 0($t0)	# Save the end address of the "circle_points" array
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
square_root:	# Find the square root of $a2	
	add $t9, $a2, $0 	#$t9 = $a2
	mtc1.d $a2, $f2	        # move $a2 to $f2
	cvt.d.w $f2, $f2	#convert $f2 from word to double
	sqrt.d $f2, $f2		#sqrt $f2
	cvt.w.d $f2, $f2	#convert $f2 from double to word
	mfc1.d $t2, $f2		#move to $t2 
	add $a2, $t9, $0	#$a2 = $t9 
	mul $t5, $t2, $t2 	#$t5 = $t2 ^ 2
	addi $t3, $t2, 1 	#$t3 = $t2 + 1
	mul $t6, $t3, $t3	#$t3 = $t3 ^ 2
	sub $t8, $a2, $t5	#$t8 = py^2 - $t2
	sub $t9, $t6, $a2	#$t9 = $t3 - py^2
compare:
	blt	$t8, $t9, set_closest	# if $t8 < $t9, $t2 is nearer to square root of $a2 than $t3
	add	$a2, $0, $t3		# Else $t3 is the nearear number to square root of $a2
	jr	$ra
set_closest: 
	add $a2, $0, $t2
	jr $ra
	
point_save:
	sw	$a1, 0($s5)	# Store px in the "circle_points" array
	sw	$a2, 4($s5)	# Store py in the "circle_points" array
	addi	$s5, $s5, 8	# Move the pointer to next block
	jr	$ra			
		
direction_change:
	li	$k0, KEY_CODE
	lw	$t0, 0($k0)

char_D:
	bne	$t0, 'd', char_A
	bgtz 	$s2, speed_up 
	li $s2, 1	# dx = 1
	li $s3, 0	# dy = 0
	li	$a0, 50
	jr	$ra

char_A:
	bne	$t0, 'a', char_S
	bltz 	$s2, speed_up
	li $s2, -1	# dx = -1	
	li $s3, 0	# dy = 0
	li	$a0, 50
	jr	$ra
	
char_S:
	bne	$t0, 's', char_W
	bgtz $s3, speed_up
	li $s2, 0	# dx = 0	
	li $s3, 1	# dy = 1
	li	$a0, 50
	jr	$ra

char_W:
	bne	$t0, 'w', default
	bltz $s3, speed_up
	li $s2, 0	# dx = 0	
	li $s3, -1	# dy = -1
	li	$a0, 50
	jr	$ra

speed_up:
	addi	$a0, $a0, -5	
	jr	$ra
		
default:
	jr	$ra

check_right:
	add	$t0, $s0, $s4	# Set $t0 to the right point of the circle
	beq	$t0, 511, reverse_direction	# Reverse direction if point hits edge
	j	move_circle	# Return otherwise
	
check_left:
	sub	$t0, $s0, $s4	# Set $t0 to the left point of the circle
	beq	$t0, 0, reverse_direction	# Reverse direction if point hits edge
	j	move_circle	# Return otherwise
check_down:
	add	$t0, $s1, $s4	# Set $t0 to the below point of the circle
	beq	$t0, 511, reverse_direction	# Reverse direction if point hits edge
	j	move_circle	# Return otherwise
	
check_up:
	sub	$t0, $s1, $s4	# Set $t0 to the upper point of the circle
	beq	$t0, 0, reverse_direction	# Reverse direction if point hits edge
	j	move_circle	# Return otherwise
	
reverse_direction:
	sub	$s2, $0, $s2	# dx = -dx
	sub	$s3, $0, $s3	# dy = -dy
	j	move_circle

draw_circle:
	addi	$sp, $sp, -4	# Save $ra 
	sw 	$ra, 0($sp)
	la	$s6, array_end	
	lw	$s7, 0($s6)	# $s7 becomes the end address of the "circle" array
	la	$s6, circle_points	# $s6 becomes the pointer to the "circle" array
	
draw_loop:
	beq	$s6, $s7, draw_end	# Stop when reach to the end of array
	lw	$a1, 0($s6)		# Get px
	lw	$a2, 4($s6)		# Get py
	jal	point_draw
	addi	$s6, $s6, 8		# Get to the next point 
	j	draw_loop
	
draw_end:
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra										
					
point_draw:
	li	$t0, SCREEN_MONITOR
	add	$t1, $s0, $a1		# x_point = x + px
	add	$t2, $s1, $a2		# y_point = y + py
	sll	$t2, $t2, 9		# $t2 = y_point * 512
	add	$t2, $t2, $t1		# $t2 += x_point
	sll	$t2, $t2, 2		# $t2 *= 4
	add	$t0, $t0, $t2		#point (pixel_position) on screen monitor
	sw	$s5, 0($t0)		#draw yellow in this pixel
	jr	$ra
