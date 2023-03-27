################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Ocean Chen, 1007934531
# Student 2: Name, Student Number
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:			.word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:			.word 0xffff0000
# Constant color values
WALL_CLR:			.word 0xc0c0c0
RED:				.word 0xff0000
GREEN:				.word 0x00ff00
BLUE:				.word 0x0000ff
BLACK:				.word 0x000000
PADDLE_COLOUR:		.word 0x00ffff
BALL_COLOUR:		.word 0xff00ff
# address offset between rows
OFFSET:				.word 128
# INITIAL BALL POSITION AND VELOCITIES
BALL_X:				.word 18
BALL_Y:				.word 16
BALL_VELX:			.word 1
BALL_VELY:			.word -1
# BALL SPEED
BALL_MAX_TIME:		.word 20 # max value that timer resets to
BALL_CURR:			.word 20 # current time


##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    lw $t1, RED        # $t1 = red
    lw $t2, GREEN        # $t2 = green
    lw $t3, BLUE        # $t3 = blue
    lw $t4, WALL_CLR	    # $t4 = light gray (wall colour)
    
    lw $t0, ADDR_DSPL       # $t0 = base address for display
    
    addi $t5, $t0, 128		# $t5 = last address in first row

# draw wall ceiling
draw_ceil:
	beq $t0, $t5, end_ceil	# while $t0 != $t5
	sw $t4, 0($t0)			# draw pixel on bitmap
	addi $t0, $t0, 4		# move one pixel to right
	j draw_ceil
end_ceil:

# draw left wall
	lw $t0, ADDR_DSPL		# $t0 = reinitialized to base address
	add $a0, $zero, $t0		# $a0 = top left pixel
	jal draw_wall			# draw vert wall starting from top left
	
# pad left wall with extra width bc math
	addi $a0, $t0, 4		# a0 = second pixel on first row
	jal draw_wall			# draw vert wall starting from second pixel
	
# draw right wall
	addi $a0, $t0, 124		# $a0 = top right pixel
	jal draw_wall			# draw vert wall starting from top right

# draw bricks
	addi $a2, $zero, 20		# brick size = 20 (5 * 4)
	# find initial position of brick
	addi $a0, $t0, 4		# $a0 = third pixel on first row
	addi $t6, $zero, 5
	sll $t6, $t6, 7			# set $t6 = 5th row offset (5 * 128)
	add $a0, $a0, $t6		# row 5, col 3 (initial brick)
	# draw first row
	move $a1, $t1			# set a1 == red
	jal draw_brick_row
	
	# draw second row
	addi $a0, $a0, 384		# row 7, col 3
	move $a1, $t3			# set a1 == blue
	jal draw_brick_row
	
	#draw third row
	addi $a0, $a0, 384		# row 9, col 3
	move $a1, $t2			# set a1 == green
	jal draw_brick_row
	
	#draw fourth row
	addi $a0, $a0, 384		# row 11, col 3
	add $a1, $t1, $t2		# set a1 == yellow (red + green)
	jal draw_brick_row

# draw paddle (1 px above floor)
	add $a2, $zero, 20		# paddle size = 20 (5 * 4)
	add $a1, $t2, $t3		# cyan = green + blue (paddle colour)
	addi $a0, $zero, 30		# set $a0 to 30
	sll $a0, $a0, 7			# multiply by 128 (row 30 offset)
	add $a0, $a0, $t0		# $a0 = address of start of row 30
	addi $a0, $a0, 52		# $a0 = row 30, col 13
	jal draw_paddle
	
# draw ball
	# initial location: (18, 16)
	lw $a0, BALL_X
	lw $a1, BALL_Y
	# create magenta colour as third arg
	lw $a3, BALL_COLOUR
	jal draw_ball

# FUNCTION: draw ball at given xy coords
#	param:
#		a0 - x offset
#		a1 - y offset
#		DEPRECATED: a2 - base address at (0, 0)
#		a3 - colour
j end_ball		# skip function
draw_ball:
	addi $sp, $sp, -4
	sw $ra, 0($sp)			# store ra on stack
	addi $sp, $sp, -4
	sw $s0, 0($sp)			# store $s0 on stack
	addi $sp, $sp, -4
	sw $t0, 0($sp)			# store $t0 on stack
	addi $sp, $sp, -4
	sw $t1, 0($sp)			# store $t1 on stack
	addi $sp, $sp, -4		
	sw $t2, 0($sp)			# store $t2 on stack
	
	# NOTE: a0 = x	a1 = y
	add $t0, $a1, $zero		# store x offset
	sll $t0, $t0, 2			# multiply by 4
	add $s0, $a0, $zero		# store y offset
	sll $s0, $s0, 7			# multiply by 128
	add $s0, $s0, $t0		# xy offset
	lw $t2, ADDR_DSPL		# load base address
	add $s0, $s0, $t2		# absolute address at xy
	
	# draw ball at s0
	sw $a3, 0($s0)
	
	# restore mem
	lw $t2, 0($sp)			# restore $t2
	addi $sp, $sp, 4
	lw $t1, 0($sp)			# restore $t1
	addi $sp, $sp, 4
	lw $t0, 0($sp)			# restore $t0
	addi $sp, $sp, 4
	lw $s0, 0($sp)			# restore $s0
	addi $sp, $sp, 4
	lw $ra, 0($sp)			# restore $ra
	addi $sp, $sp, 4
	
	# return
	jr $ra
end_ball:
# END FUNCTION: draw_draw ball


# FUNCTION: draw a single brick (size 5)
# param: 
#		$a0 - left most location
#		$a1 - colour of brick
#		$a2 - length of brick

j end_brick
draw_brick:
	# allocate mem on stack
	addi $sp, $sp, -4
	sw $s0, 0($sp)			# store $s0 on top of stack
	add $s0, $a0, $a2		# s0 = last pixel of the brick
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)			# store $t1 on stack
	
	# start drawing brick from left to right
	db_loop:
	beq $s0, $a0, end_db_loop	# while s0 != a0
		sw $a1, 0($s0)			# draw pixel with colour a1 to s0
		addi $t1, $s0, 128		# draw pixel directly under s0
		sw $a1, 0($t1)
		addi $s0, $s0, -4	# move pixel left by 1
		j db_loop
	end_db_loop:
	
	# restore register values
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	# return
	jr $ra
end_brick:

# FUNCTION: draw a single paddle (save paddle location to $s0)
# param: 
#		$a0 - left most location
#		$a1 - colour of paddle
#		$a2 - length of paddle
j end_paddle		# skip function
draw_paddle:
	# NO NEED TO SAVE S0 ON STACK BC WE WANT TO MODIFY IT
	
	add $s0, $a0, $a2		# s0 = last pixel of the paddle
	# start drawing brick from left to right
	dp_loop:
	beq $s0, $a0, end_dp_loop	# while s0 != a0
		sw $a1, 0($s0)			# draw pixel with colour a1 to s0
		addi $s0, $s0, -4	# move pixel left by 1
		j dp_loop
	end_dp_loop:
	
	# return
	jr $ra
end_paddle:
# END FUNCTION: draw paddle

# FUNCTION: ERASE a single paddle
# param: 
#		$a0 - left most location
#		$a1 - Nothing (don't care)
#		$a2 - length of paddle
j end_erase_paddle		# skip function
erase_paddle:
	# allocate mem
	addi $sp, $sp, -4		# store s0 on stack
	sw $s0, 0($sp)
	addi $sp, $sp, -4		# store t0 on stack
	sw $t0, 0($sp)
	
	add $s0, $a0, $a2		# s0 = last pixel of the paddle
	# start drawing brick from right to left
	ep_loop:
	beq $s0, $a0, end_ep_loop	# while s0 != a0
		lw $t0, BLACK
		sw $t0, 0($s0)			# draw black pixel to s0
		addi $s0, $s0, -4	# move pixel left by 1
		j ep_loop
	end_ep_loop:
	
	# restore mem
	lw $t0, 0($sp)			# restore t0
	addi $sp, $sp, 4
	lw $s0, 0($sp)			# restore s0
	addi $sp, $sp, 4
	# return
	jr $ra
end_erase_paddle:
# END FUNCTION: ERASE paddle

# FUNCTION: draws row or bricks starting at $a0
j end_brick_row				# skip over function
draw_brick_row:
	# allocate mem on stack
	addi $sp, $sp, -4		# allocate and store mem for $ra on stack
	sw $ra, 0($sp)

	addi $sp, $sp, -4		# initialize memory for $s0
	sw $s0, 0($sp)
	move $s0, $a0			# store $a0 in $s0
	
	addi $sp, $sp, -4
	sw $a0, 0($sp)			# store $a0 on the stack
	
	addi $sp, $sp, -4		# store $t5 on stack
	sw $t5, 0($sp)


	addi $t5, $s0, 120		# last pixel on this row (excluding wall)
	
	# LOOP: drawing bricks
	draw_bricks_loop:
	beq $s0, $t5, end_bricks_loop
	add $a0, $s0, $zero		# set arugment as current val
	jal draw_brick
	addi $s0, $s0, 24		# each brick length 6 (5 for brick, 1 for gap)
	j draw_bricks_loop
	end_bricks_loop:
	# END LOOP: drawing bricks
	
	# RESTORE REGISTER VALUES
	lw $t5, 0($sp)			# restore $t5
	addi $sp, $sp, 4		# pop sp
	lw $a0, 0($sp)			# restore a0
	addi $sp, $sp, 4
	lw $s0, 0($sp)			# restore $s0
	addi $sp, $sp, 4
	lw $ra, 0($sp)			# restore return address
	addi $sp, $sp, 4		# back to initial sp
	
	# return
	jr $ra
	
end_brick_row:
# END FUNCTION: draw_brick_row

# FUNCTION: draw vert wall starting at $a0
j end_wall					# skip over function
draw_wall:
# prep variables 
	addi $sp, $sp, -4		# initialize space for $s0 on stack
	sw $s0, 0($sp)				# save $s0 in current sp
	
	move $s0, $a0			# move starting address to $s0
	addi $t5, $zero, 31		# $t5 = 31 (32 rows total)
	addi $t6, $zero, 128	# $t6 = 128 (4 bytes per address x 32 pixels)
	mult $t5, $t6			# lo = bottom pixel offset
	mflo $t5				# $t5 = bottom pixel offset
	add $t5, $t5, $s0		# $t5 = bottom pixel address
   
# draw wall starting $s0
wall_loop:
	beq $s0, $t5, end_wall_loop	# while $s0 != $t5
	addi $s0, $s0, 128		# move one pixel down			
	sw $t4, 0($s0)			# draw wall tile at $s0
	j wall_loop
end_wall_loop:
	lw $s0, 0($sp)				# restore $s0 register
	addi $sp, $sp, 4		# restore sp
	jr $ra
end_wall:
# END FUNCTION: draw_wall


game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    
    # KEYBOARD INPUTS
    # (1) Check if keypressed
    lw $t4, ADDR_KBRD               # $t4 = base address for keyboard
    lw $t8, 0($t4)                  # Load first word from keyboard (1 if keypressed)
    
    bne $t8, 1, else_key				# check if keypressed. Jump otherwise
    	lw $a0, 4($t4)				# pass keycode as arg
    	jal keyboard_inputs			# evaluate keypress
    else_key:
    
    # LAUNCH BALL
    jal move_ball
    li $v0, 32
    li $a0, 10
    syscall
    b game_loop


# FUNCTION: keyboard_inputs
keyboard_inputs:
	addi $sp, $sp, -4				# store prev return address on stack
	sw $ra, 0($sp)
	
	beq $a0, 0x61, key_a			# key was a
	beq $a0, 0x64, key_d			# key was d
	beq $a0, 0x71, key_q			# key was q
	
	lw $ra 0($sp)					# restore return address
	addi $sp, $sp, 4	
	jr $ra
end_keyboard_inputs:

# move left
key_a:
	# allocate mem
	addi $sp, $sp, -4				# store $ra on stack
	sw $ra, 0($sp)					
	addi $sp, $sp, -4				# store $t0 on stack
	sw $t0, 0($sp)
	addi $sp, $sp, -4				# store $t1 on stack
	sw $t1, 0($sp)
	
	div $t1, $s0, 128				# t1 = s0 // 128 (integer division)
	mul $t0, $t1, 128				# t0 = t1 * 128
	sub $t1, $s0, $t0				# t1 = s0 % 128 to see offset from left wall
	
	beq $t1, 4, hit_left			# check if $t1 has space to move left
		move $a0, $s0
		lw $a1, BLACK
		li $a2, 20					# set length to 5
		jal draw_paddle				# erases old paddle with black
		addi $a0, $a0, -4			# move paddle left
		lw $a1, PADDLE_COLOUR		# change back to OG colour				
		jal draw_paddle				# draw new paddle
	hit_left:
	
	# restore mem
	lw $t1, 0($sp)					# restore $t1
	addi $sp, $sp, 4
	lw $t0, 0($sp)					# restore $t0
	addi $sp, $sp, 4
	lw $ra, 0($sp)					# restore $ra
	addi $sp, $sp, 4
	# return
	jr $ra
end_key_a:

# move right
key_d:
	# allocate mem
	addi $sp, $sp, -4				# store $ra on stack
	sw $ra, 0($sp)					
	addi $sp, $sp, -4				# store $t0 on stack
	sw $t0, 0($sp)
	addi $sp, $sp, -4				# store $t1 on stack
	sw $t1, 0($sp)
	
	div $t1, $s0, 128				# t1 = s0 // 128 (integer division)
	mul $t0, $t1, 128				# t0 = t1 * 128
	sub $t1, $s0, $t0				# t1 = s0 % 128 to see offset from left wall
	
	beq $t1, 100, hit_right			# 128 - 20 (paddle size) - 8 check if $t1 has space to move right
		move $a0, $s0
		lw $a1, BLACK
		li $a2, 20					# set length to 5
		jal draw_paddle				# erases old paddle with black
		addi $a0, $a0, 4			# move paddle left
		lw $a1, PADDLE_COLOUR		# change back to OG colour				
		jal draw_paddle				# draw new paddle
	hit_right:
	
	# restore mem
	lw $t1, 0($sp)					# restore $t1
	addi $sp, $sp, 4
	lw $t0, 0($sp)					# restore $t0
	addi $sp, $sp, 4
	lw $ra, 0($sp)					# restore $ra
	addi $sp, $sp, 4
	# return
	jr $ra
end_key_d:

move_ball:
	# store ra into stack pointer
	addi $sp, $sp, -4		# store ra on stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4		# store t0 on stack
	sw $t0, 0($sp)
	addi $sp, $sp, -4		# store t1 on stack
	sw $t1, 0($sp)
	addi $sp, $sp, -4		# store t2 on stack
	sw $t2, 0($sp)
	addi $sp, $sp, -4		# store t3 on stack
	sw $t3, 0($sp)
	addi $sp, $sp, -4		# store t4 on stack
	sw $t4, 0($sp)
	addi $sp, $sp, -4		# store t5 on stack
	sw $t5, 0($sp)
	
	
	lw $t2, BALL_CURR
	bnez $t2, NO_MOVE_BALL
	# CALL DRAW BALL FUNCTION WITH BLACK AT CURR LOCATION
	lw $a0, BALL_X
	lw $a1, BALL_Y
	lw $a3, BLACK
	jal draw_ball
	
	# compute new location
	lw $t0, BALL_VELX		# load velocities
	lw $t1, BALL_VELY
	add $a0, $t0, $a0		# a0 - new X offset
	# a1 remains to be BALL_Y
	jal compute_loc
	
	move $t3, $v0			# t3 - updated location x
	lw $t4, 0($t3)			# FIND COLOUR AT ADDRESS T3
	
	beq $t4, $a3, NO_COLLIDE_X	# if colour == black, skip
		li $t5, -1			
		mult $t0, $t5		# multiply t0 by -1
		mflo $t0			# t0 stores negative velocity
		sw $t0, BALL_VELX	# update BALL_VELX
	NO_COLLIDE_X:
	lw $a0, BALL_X			# a0 - BALL_X value
	add $a0, $t0, $a0		# a0 - add velocity to ball_x
	sw $a0, BALL_X			# update BALL_X value
	
	# a1 = BALL_Y, t1 = BALL_VELY
	add $a1, $a1, $t1		# a1 - new Y offset
	jal compute_loc		# v0 - bitmap address
	
	move $t3, $v0			# t3 - updated location for x and y
	lw $t4, 0($t3)			# FIND COLOUR AT ADDRESS T3
	
	# CHECK IF NEW Y VALUE COLLIDES
	beq $t4, $a3, NO_COLLIDE_Y	# if colour == black, skip
		lw $t1, BALL_VELY	# load Y velocity
		li $t5, -1			
		mult $t1, $t5		# multiply t1 by -1
		mflo $t1			# t1 stores negative velocity
		sw $t1, BALL_VELY	# update BALL_Y
	NO_COLLIDE_Y:
	lw $a1, BALL_Y			# a1 - BALL_Y value
	add $a1, $t1, $a1		# a1 - new Y offset
	sw $a1, BALL_Y			# update BALL_Y value
	
	# DRAW BALL AT NEW LOCATION
	# a0 = BALL_X, a1 = BALL_Y
	lw $a3, BALL_COLOUR		# load ball colour from mem
	jal draw_ball			# draw ball at new location
	
	lw $t2, BALL_MAX_TIME	# reset BALL_CURR to BALL_TIME_MAX
	sw $t2, BALL_CURR
	NO_MOVE_BALL:
	
	addi $t2, $t2, -1		# decrement BALL_CURR by 1
	sw $t2, BALL_CURR
	
	# restore mem
	lw $t5, 0($sp)			# restore t5
	addi $sp, $sp, 4
	lw $t4, 0($sp)			# restore t4
	addi $sp, $sp, 4
	lw $t3, 0($sp)			# restore t3
	addi $sp, $sp, 4
	lw $t2, 0($sp)			# restore t2
	addi $sp, $sp, 4
	lw $t1, 0($sp)			# restore t1
	addi $sp, $sp, 4
	lw $t0, 0($sp)			# restore t0
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	addi $sp, $sp, 4		# restore ra 
	
	jr $ra
	
end_move_ball:

# Computes the location on the bitmap display given xy coords
#		a0 - x coord
#		a1 - y coord
#		v0 - bitmap location
compute_loc:
	addi $sp, $sp, -4
	sw $s0, 0($sp)			# store $s0 on stack
	addi $sp, $sp, -4
	sw $t0, 0($sp)			# store $t0 on stack
	addi $sp, $sp, -4
	sw $t1, 0($sp)			# store $t1 on stack
	addi $sp, $sp, -4		
	sw $t2, 0($sp)			# store $t2 on stack
	
	# NOTE: a0 = x	a1 = y
	add $t0, $a1, $zero		# store x offset
	sll $t0, $t0, 2			# multiply by 4
	add $s0, $a0, $zero		# store y offset
	sll $s0, $s0, 7			# multiply by 128
	add $s0, $s0, $t0		# xy offset
	lw $t2, ADDR_DSPL		# load base address
	add $s0, $s0, $t2		# absolute address at xy
	
	move $v0, $s0
	
	# restore mem
	lw $t2, 0($sp)			# restore $t2
	addi $sp, $sp, 4
	lw $t1, 0($sp)			# restore $t1
	addi $sp, $sp, 4
	lw $t0, 0($sp)			# restore $t0
	addi $sp, $sp, 4
	lw $s0, 0($sp)			# restore $s0
	addi $sp, $sp, 4
	
	jr $ra
end_computer_loc:

# QUIT FUNCTION
key_q:
	li $v0, 10                      # Quit gracefully
	syscall
end_key_q:
	
	
	
	
