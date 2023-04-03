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

# address offset between rows
OFFSET:				.word 128
##############################################################################
# Mutable Data
##############################################################################

# PADDLE INFO
PADDLE_COLOUR:		.word 0x00ffff
PADDLE_LOC:         .word 14
BALL_COLOUR:		.word 0xff00ff

# INITIAL BALL POSITION AND VELOCITIES
BALL_X:				.word 16
BALL_Y:				.word 16
BALL_VELX:			.word 0
BALL_VELY:			.word 1
# BALL SPEED
BALL_MAX_TIME:		.word 15 # max value that timer resets to
BALL_CURR:			.word 15 # current time
PITCH:              .word 59    # middle C

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
	# draw black over screen
	jal cover_screen

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
	li $a2, 20				# brick size = 20 (5 * 4)
	# find initial position of brick
	addi $a0, $t0, 4		# $a0 = third pixel on first row
	addi $t6, $zero, 5
	sll $t6, $t6, 7			# set $t6 = 5th row offset (5 * 128)
	
	# note that row 0, col 0 is left most px (start counting from 0 instead of 1)
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
	
	jal compute_loc			# v0 = absolute address at xy
	move $s0 $v0
	
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
#	a0 - abs address of first brick
#	a1 - colour of bricks
#	a2 - length of bricks in exact px
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

jal pause

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
    # SLEEP FOR 10 ms
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
	beq $a0, 0x70, pause           # key was p
	
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
	addi $sp, $sp, -4				# store $t2 on stack
	sw $t2, 0($sp)
	
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
		lw $t2, PADDLE_LOC
		addi $t2, $t2, -1             # move paddle loc one to left
		sw $t2, PADDLE_LOC
	hit_left:
	
	# restore mem
	lw $t2, 0($sp)					# restore $t2
	addi $sp, $sp, 4
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
	addi $sp, $sp, -4				# store $t2 on stack
	sw $t2, 0($sp)
	
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
		lw $t2, PADDLE_LOC
		addi $t2, $t2, 1              # move paddle loc one to left
		sw $t2, PADDLE_LOC
	hit_right:
	
	# restore mem
	lw $t2, 0($sp)					# restore $t2
	addi $sp, $sp, 4
	lw $t1, 0($sp)					# restore $t1
	addi $sp, $sp, 4
	lw $t0, 0($sp)					# restore $t0
	addi $sp, $sp, 4
	lw $ra, 0($sp)					# restore $ra
	addi $sp, $sp, 4
	# return
	jr $ra
end_key_d:

# CHECKS COLLISIONS, MOVES THE BALL, UPDATES XY VELOCITY, UPDATES X,Y VALUES.
# IF COLLIDES, CALL FUNCTION TO DAMAGE THE BRICK
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
	addi $sp, $sp, -4      # store t6 on stack
	sw $t6, 0($sp)
	
	lw $t2, BALL_CURR
	bnez $t2, NO_MOVE_BALL
	# CALL DRAW BALL FUNCTION WITH BLACK AT CURR LOCATION
	lw $a0, BALL_X
	lw $a1, BALL_Y
	lw $a3, BLACK
	jal draw_ball
	li $t6, 0              # flag. Add only dir if flag is 1
	
# ======================== CHECK COLLISIONS BASED ON DIRECTION ==============================
	jal compute_direction  # find absolute direction (no magnitude)
	move $t0, $v0          # t0 - x dir
	move $t1, $v1          # t1 - y dir
	
	add $a0, $t0, $a0		# a0 - new X offset (direction)
	# a1 remains to be BALL_Y
	jal compute_loc
	
	move $t3, $v0			# t3 - updated location x
	lw $t4, 0($t3)			# FIND COLOUR AT ADDRESS T3
	
	lw $t0, BALL_VELX      # load x velocity back into t0
	
	# CASE 1: ball immediately beside collidable
	beq $t4, $a3, NO_COLLIDE_X	# if colour == black, skip
		li $t5, -1
		mult $t0, $t5		# multiply t0 by -1
		mflo $t0			# t0 stores negative velocity
		sw $t0, BALL_VELX	# update BALL_VELX
		# a0 - new X offset
		# a1 - current Y offset
		move $a2, $t4		# pass colour into break_brick
		jal break_brick		# a0, a1 already contains correct values to break brick
		# NOTE: break_brick sets v0 to 0 or 1.
		jal play_collision_sound
		# JUMP OUT
		j end_x_collision
	NO_COLLIDE_X:
	# ================================ CHECK COLLISIONS BASED ON VELOCITY ===================================
	# reset, a0 value
	lw $a0, BALL_X             # a0 - BALL_X value
	# a1 remains to be BALL_Y
	# CHECK COLLISIONS
	add $a0, $t0, $a0		# a0 - new X offset (direction)
	# a1 remains to be BALL_Y
	jal compute_loc
	
	move $t3, $v0			# t3 - updated location x
	lw $t4, 0($t3)			# FIND COLOUR AT ADDRESS T3
	
	# CASE 2: ball will collide next clock cycle based on velocity
	beq $t4, $a3, NO_COLLIDE_X_VEL	# if colour == black, skip
		li $t5, -1
		# t0 now stores x velocity
		mult $t0, $t5		# multiply t0 by -1
		mflo $t0			# t0 stores negative velocity
		sw $t0, BALL_VELX	# update BALL_VELX
		# a0 - new X offset
		# a1 - current Y offset
		move $a2, $t4		# pass colour into break_brick
		jal break_brick		# a0, a1 already contains correct values to break brick
		# NOTE: break_brick sets v0 to 0 or 1.
		jal play_collision_sound
	NO_COLLIDE_X_VEL:
	end_x_collision:
	
	lw $a0, BALL_X
	add $a0, $t0, $a0		# a0 - add velocity to ball_x
	sw $a0, BALL_X			# update BALL_X value
	
# ====================== CHECK Y COLLISIONS BASED ON DIRECTION =============================
	# t1 currently stores dir
	add $a1, $a1, $t1		# a1 - new Y offset (direction)
	jal compute_loc	       	# v0 - bitmap address
	
	move $t3, $v0			# t3 - updated location for x and y
	lw $t4, 0($t3)			# FIND COLOUR AT ADDRESS T3
	
	lw $t1, BALL_VELY      # t1 - ACTUAL y velocity
	# CHECK IF NEW Y VALUE COLLIDES
	beq $t4, $a3, NO_COLLIDE_Y     	# if colour == black, skip
		li $t5, -1			
		mult $t1, $t5		# multiply t1 by -1
		mflo $t1			# t1 stores negative velocity
		sw $t1, BALL_VELY	# update BALL_velY
		# a0 - new X offset
		# a1 - new Y offset
		move $a2, $t4		# pass in brick colour to break_brick
		jal break_brick		# a0, a1 already contains correct values for break_brick
		# break_brick set v0 to 0 or 1
		jal play_collision_sound
		li $t6, 1             # set flag for y collsion to 1
		# JUMP OUT
		j end_y_collision
	NO_COLLIDE_Y:
	
	# ================================ CHECK Y COLLISIONS BASED ON VELOCITY ===================================
	# reset, a1 value
	lw $a1, BALL_Y             # a0 - BALL_X value
	# a0 is new ball_x value
	# CHECK COLLISIONS
	add $a1, $t1, $a1		# a1 - new X offset (velocity)
	jal compute_loc
	
	move $t3, $v0			# t3 - updated location y
	lw $t4, 0($t3)			# FIND COLOUR AT ADDRESS T3
	
	# CASE 2: ball will collide next clock cycle based on velocity
	beq $t4, $a3, NO_COLLIDE_Y_VEL	# if colour == black, skip
		li $t5, -1
		# t0 now stores x velocity
		mult $t1, $t5		# multiply t0 by -1
		mflo $t1			# t0 stores negative velocity
		sw $t1, BALL_VELY	# update BALL_VELX
		# a0 - new X offset
		# a1 - current Y offset
		move $a2, $t4		# pass colour into break_brick
		jal break_brick		# a0, a1 already contains correct values to break brick
		# NOTE: break_brick sets v0 to 0 or 1.
		jal play_collision_sound
		li $t6, 1             # set flag for y collision to 1
	NO_COLLIDE_Y_VEL:
	end_y_collision:
	
	lw $a1, BALL_Y			# a1 - BALL_Y value
	add $a1, $t1, $a1		# a1 - new Y offset
	sw $a1, BALL_Y			# update BALL_Y value
	
	# a0 = BALL_X, a1 = BALL_Y
	# Check if ball outside region
	blt $a1, 32, no_death	# if BALL_Y < 32 (upper bound), branch out
		# otherwise, jump to death function
		jal die
	no_death:
	
	# DRAW BALL AT NEW LOCATION
	# a0 = BALL_X, a1 = BALL_Y
	lw $a3, BALL_COLOUR		# load ball colour from mem
	jal draw_ball			# draw ball at new location
	
	bne $t6, 1, no_y_collide
        move $a0, $t4       # recall that t4 stores the colour of collided object
        jal check_paddle_collisions
	no_y_collide:
	
	lw $t2, BALL_MAX_TIME	# reset BALL_CURR to BALL_TIME_MAX
	sw $t2, BALL_CURR
	NO_MOVE_BALL:
	
	addi $t2, $t2, -1		# decrement BALL_CURR by 1
	sw $t2, BALL_CURR
	
	# restore mem
	lw $t6, 0($sp)         # restore t6
	addi $sp, $sp, 4
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
	add $t0, $a0, $zero		# store x offset
	sll $t0, $t0, 2			# multiply by 4
	add $s0, $a1, $zero		# store y offset
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
end_compute_loc:

# draw black over entire screen
cover_screen:
	# STORE REG ON STACK
	addi $sp, $sp, -20		# space for 3 reg values
	sw $ra, 0($sp)			# store ra
	sw $a0, 4($sp)			# store a0
	sw $a1, 8($sp)			# store a1
	sw $t0, 12($sp)			# store t0
	sw $t1, 16($sp)			# store t1
	
	li $a0, 32				# a0 = bottom right x coord + 1 (since we want to compute <)
	li $a1, 31				# a1 = bottom right y coord
	# compute bottom right pixel
	jal compute_loc			# v0 - absolute address of bottom right px + 4px
	
	lw $t0, ADDR_DSPL		# t0 - base address of bmp dspl
	lw $t1, BLACK			# t1 - black
	# loop over all addresses until end bottom right pixel
	cs_loop:
	beq $t0, $v0, end_cs_loop	# while t0 <= bottom right px
		sw $t1, 0($t0)			# draw black at curr
		addi $t0, $t0, 4		# move right 1 px
		j cs_loop				
	end_cs_loop:
	
	# RESTORE REG VALUES
	lw $ra, 0($sp)			# restore ra
	lw $a0, 4($sp)			# restore a0
	lw $a1, 8($sp)			# restore a1
	lw $t0, 12($sp)			# restore t0
	lw $t1, 16($sp)			# restore t1
	addi $sp, $sp, 20		# restore sp val
	
	# RETURN
	jr $ra
end_cover_screen:

# break the brick given the collision coordinate as a0, a1*
# *NOTE: only breaks if given coord is a valid (breakable) brick coord. DO NOTHING OTHERWISE
#	a0 - x collision coord
#	a1 - y collision coord
#	a2 - brick colour
#   RETURN: v0 - 1 if brick collision, 0 otherwise
break_brick:
	# STORE MEM ON STACK
	addi $sp, $sp, -36		# allocate mem for 8 regs
	sw $ra, 0($sp)			# store ra
	sw $a0, 4($sp)			# store a0
	sw $a1, 8($sp)			# store a1
	sw $a2, 12($sp)			# store a2
	sw $t0, 16($sp)			# store t0
	sw $t1, 20($sp)			# store t1
	sw $t2, 24($sp)			# store t2
	sw $t3, 28($sp)			# store t3
	sw $t4, 32($sp)			# store t4
	
	li $v0, 0              # flag: intially set to 0, indicating not brick collision
	
	# CHECK IF BRICK
	# NOTE THAT IS (breakable) BRICK IFF 2 <= X <= 30, 5 <= Y <= 15
	blt $a0, 2, not_brick		# branch if a0 < 2
	bgt $a0, 30, not_brick		# branch if a0 > 30
	blt $a1, 5, not_brick		# branch if a1 < 5
	bgt $a1, 15, not_brick		# branch if a1 > 15
	
	# NOTE: x diff between bricks is 6, y diff between bricks is 3
	addi $t0, $a0, -2			# calibrate coordinates (bricks start on col 2)
	addi $t1, $a1, -5			# bricks start on row 5
	
	li $t3, 6					# t3 - x dist btwn bricks
	li $t4, 3					# t4 - y dist btwn bricks
	
	div $t0, $t0, $t3			# t0 - int div by 6 to see which column
	div $t1, $t1, $t4			# t1 - int div by 3 to see which row
	mult $t0, $t3
	mflo $t0					# t0 - calibrated x coord of leftmost px on brick
	mult $t1, $t4
	mflo $t1					# t1 - calibrated y coord of upmost px on brick
	
	addi $t0, $t0, 1			# reset x calibration
	addi $t1, $t1, 5			# reset y calibration
	
	# note that t0, t1 are xy coord of left-upper most px of brick
	move $a0, $t0				# prep args to compute absolute location
	move $a1, $t1				
	jal compute_loc				# v0 = abs address of top-left px of brick

	move $a0, $v0				# prep args to draw brick (a0 - abs address of starting point)
	# TEST
	lw $a1, BLACK				# load in black
	li $a2, 20					# set brick length to 5 (4 * 20)
	jal draw_brick				# replaces brick with black brick
	
	li $v0, 1                  # flag set to 1 indicating brick collision
	
	not_brick:
	
	lw $ra, 0($sp)			# restore ra
	lw $a0, 4($sp)			# restore a0
	lw $a1, 8($sp)			# restore a1
	lw $a2, 12($sp)			# restore a2
	lw $t0, 16($sp)			# store t0
	lw $t1, 20($sp)			# store t1
	lw $t2, 24($sp)			# restore t2
	lw $t3, 28($sp)			# restore t3
	lw $t4, 32($sp)			# restore t4
	addi $sp, $sp, 36		# restore stack pt
	
	# RETURN
	jr $ra
end_break_brick:

# PLAYS COLLISION SOUND DEPENDING ON COLLISION TYPE
# COLLISION TYPE GIVEN BY $V0 (accepts no other arguments)
play_collision_sound:
        # prepare for midi out syscall by storing a0, a1, a2, a3 on stack
		addi $sp, $sp, -20            # make space for 4 register values
		sw $a0, 0($sp)                # store a0
		sw $a1, 4($sp)                # store a1
		sw $a2, 8($sp)                # store a2
		sw $a3, 12($sp)               # store a3
		sw $t0, 16($sp)               # store t0
		
		# prep sound depending on collision type
		beq $v0, 1, if_brick_collision
		# paddle or wall collision

		li $v0, 31                    # midi async syscall
		lw $a0, PITCH                 # a0 - current pitch to play
		move $t0, $a0
		addi $t0, $t0, 2              # t0 - pitch incremented by 1 semitone
		blt $t0, 90, no_pitch_reset
		  li $t0, 60                  # reset pitch to 60
		no_pitch_reset:
		sw $t0, PITCH                 # store incremented pitch
		li $a1, 50                    # duration in ms
		# Intruments: 120-127 - sound effects
		li $a2, 4                     # instrument 0-127
		li $a3, 127                   # volume 0 - 127
		
		j end_if_brick_collision
		if_brick_collision:
		# brick collision
		li $v0, 31                    # midi syscall
		li $a0, 90                    # pitch 0-127
		li $a1, 50                    # duration in ms
		# Intruments: 120-127 - sound effects
		li $a2, 4                   # instrument 0-127
		li $a3, 127                   # volume 0 - 127
		end_if_brick_collision:
		
		syscall
		
		lw $a0, 0($sp)                # restore a0
		lw $a1, 4($sp)                # restore a1
		lw $a2, 8($sp)                # restore a2
		lw $a3, 12($sp)               # restore a3
		lw $t0, 16($sp)               # restore t0
		addi $sp, $sp, 20             # restore stack pt
		
		# RETURN
		jr $ra
end_play_collision_sound:

# CHECK PADDLE COLLISIONS, AND DETERMINE NEXT XY VEL
# a0 - colour of collided object
# PRECONDITION: y collision has occurred
check_paddle_collisions:
    # STORE MEM ON STACK
	addi $sp, $sp, -36		# allocate mem for 8 regs
	sw $ra, 0($sp)			# store ra
	sw $a0, 4($sp)			# store a0
	sw $t5, 8($sp)			# store a1
	sw $t6, 12($sp)			# store a2
	sw $t0, 16($sp)			# store t0
	sw $t1, 20($sp)			# store t1
	sw $t2, 24($sp)			# store t2
	sw $t3, 28($sp)			# store t3
	sw $t4, 32($sp)			# store t4
	
	lw $t0, BALL_X         
	lw $t1, BALL_VELX
	li $t4, -1
	mult $t1, $t4
	mflo $t1               # t1 - negative x vel
	add $t4, $t0, $t1      # t4 - previous x position
	lw $t2, PADDLE_COLOUR  # t2 - paddle colour
	lw $t3, PADDLE_LOC     # t3 - left most location on paddle
	
	bne $a0, $t2, no_paddle_collision      # skip if collision wasn't between paddle
    	beq $t4, $t3, paddle_pos0
    	addi $t3, $t3, 1
    	beq $t4, $t3, paddle_pos1
    	addi $t3, $t3, 1
    	beq $t4, $t3, paddle_pos2
    	addi $t3, $t3, 1
    	beq $t4, $t3, paddle_pos3
    	addi $t3, $t3, 1
    	beq $t4, $t3, paddle_pos4
        paddle_pos0:
            # left most location on paddle (go left)
            li $t5, -2
            sw $t5, BALL_VELX
            li $t5, -1
            sw $t5, BALL_VELY
            j no_paddle_collision
        paddle_pos1:
            jal compute_direction
            sw $v0, BALL_VELX
            sw $v1, BALL_VELY
            j no_paddle_collision
        paddle_pos2:
            # middle (launch straight up)
            li $t5, 0
            sw $t5, BALL_VELX
            j no_paddle_collision
        paddle_pos3:
            jal compute_direction
            sw $v0, BALL_VELX
            sw $v1, BALL_VELY
            j no_paddle_collision
        paddle_pos4:
            # go right
            li $t5, 2
            sw $t5, BALL_VELX
            li $t5, -1
            sw $t5, BALL_VELY
	no_paddle_collision:
	
	lw $ra, 0($sp)			# restore ra
	lw $a0, 4($sp)			# restore a0
	lw $t5, 8($sp)			# restore a1
	lw $t6, 12($sp)			# restore a2
	lw $t0, 16($sp)			# store t0
	lw $t1, 20($sp)			# store t1
	lw $t2, 24($sp)			# restore t2
	lw $t3, 28($sp)			# restore t3
	lw $t4, 32($sp)			# restore t4
	addi $sp, $sp, 36		# restore stack pt
	# RETURN
	jr $ra
end_check_paddle_collisions:

# LOAD VELOCITIES FROM MEMORY, COMPUTE DIRECTION
# NO ARGUMENTS
# RETURN:
#       v0 - x dir
#       v1 - y dir 
compute_direction:
    addi $sp, $sp, -8
    sw $t0, 0($sp)                      # store t0
    sw $t1, 4($sp)                      # store t1
    
    lw $t0, BALL_VELX		# load velocities
	lw $t1, BALL_VELY
	
	# COMPUTE X DIRECTION
	bne $t0, $zero, xpos_not_zero       # if t0 == 0
	   j x_dir_done                    # no need to do anything
	xpos_not_zero:
	bgtz $t0, xpos_vel                  # if t0 < 0
	   li $t0, -1                      # load t0 = -1
	   j x_dir_done
	xpos_vel:
	li $t0, 1                          # otherwise, t0 > 0, so load t0 = 1
	x_dir_done:
	# COMPUTER Y DIRECTION
	bne $t1, $zero, ypos_not_zero       # if t1 == 0
	   j y_dir_done                    # no need to do anything
	ypos_not_zero:
	bgtz $t1, ypos_vel                  # if t1 < 0
	   li $t1, -1                      # load t1 = -1
	   j y_dir_done
	ypos_vel:
	li $t1, 1                          # otherwise, t1 > 0, so load t1 = 1
	y_dir_done:
	
	move $v0, $t0                      # set v0 = x dir
	move $v1, $t1                      # set v1 = y dir
    
    lw $t0, 0($sp)                      # restore t0
    lw $t1, 4($sp)                      # restore t1
    addi $sp, $sp, 8
    # RETURN
    jr $ra
end_compute_direction:

pause:
    addi $sp, $sp, -16              
    sw $t4, 0($sp)                      # store t4
    sw $t8, 4($sp)                      # store t8         
    sw $a0, 8($sp)                      # store a0
    sw $v0, 12($sp)                     # store v0
    
    pause_loop:
    # (1) Check if keypressed
    lw $t4, ADDR_KBRD               # $t4 = base address for keyboard
    lw $t8, 0($t4)                  # Load first word from keyboard (1 if keypressed)
    bne $t8, 1, no_keypress			# check if keypressed. Jump otherwise
    	lw $t8, 4($t4)				# t8 - keycode
    	bne $t8, 0x70, not_unpause     # check if user pressed space
    	   lw $t4, 0($sp)                  # restore t4
            lw $t8, 4($sp)                  # restore t8
            lw $a0, 8($sp)                  # restore a0
            lw $v0, 12($sp)                 # restore v0
            addi $sp, $sp, 16
    	   jr $ra                  # RETURN
    	not_unpause:
    no_keypress:
    # sleep for 10 ms
    li $v0, 32
    li $a0, 10
    syscall
    j pause_loop
    
    lw $t4, 0($sp)                  # restore t4
    lw $t8, 4($sp)                  # restore t8
    lw $a0, 8($sp)                  # restore a0
    lw $v0, 12($sp)                 # restore v0
    addi $sp, $sp, 16
end_pause:

# checks if the player has died
die:
	# TODO do something cooler
	li $v0, 10				# quit game
	syscall
	jr $ra
end_die:


# QUIT FUNCTION
key_q:
	li $v0, 10                      # Quit gracefully
	syscall
end_key_q:

