# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
displayAddress: .word 0x10008000
rect_x:		.word 2		# set rectangle location
rect_y:		.word 2		#   to (2,2)

.text
lw $t0, displayAddress 	# $t0 stores the base address for display
li $t1, 0xff0000 	# $t1 stores the red colour code
li $t2, 0x00ff00 	# $t2 stores the green colour code
li $t3, 0x0000ff 	# $t3 stores the blue colour code
# sw $t1, 0($t0) 	# paint the first (top-left) unit red.
# sw $t2, 4($t0) 	# paint the second unit on the first row green. Why $t0+4?
# sw $t3, 128($t0) 	# paint the first unit on the second row blue. Why +128?
add $t4, $t1, $t2	#  $t4 = $t1 + $t2  ($t4 = yellow)

process_loop:

lw $t0, displayAddress 	# $t0 stores the base address for display
la $t7, rect_x		# $t7 has the address of rect_x
lw $t8, 0($t7)		# Fetch x position of rectangle
la $t7, rect_y		# $t7 has the address of rect_y
lw $t9, 0($t7)		# Fetch y position of rectangle
sll $t9, $t9, 7		# Multiply $t9 by 128
sll $t8, $t8, 2		# Multiply $t8 by 4
add $t0, $t0, $t9	# Add y offset to $t0
add $t0, $t0, $t8	# Add x offset to $t0
addi $a0, $zero, 3	# Set input to draw rectangle with
addi $a1, $zero, 4	#   height = 3 and width = 4
jal draw_rectangle	

addi $t4, $t4, 10	# update colour value
la $t7, rect_x		# $t7 has the address of rect_x
lw $t8, 0($t7)		# Fetch x position of rectangle
addi $t8, $t8, 1	# Add 1 to the x position
sw $t8, 0($t7)		# Store updated x position into memory

j process_loop

#
# Example function: Drawing a rectangle
#
draw_rectangle:
# Draw a rectangle:
add $t6, $zero, $zero	# Set index value ($t6) to zero
draw_rect_loop:
beq $t6, $a0, end_rect 	# If $t6 == height ($a0), jump to end

# Draw a line:
add $t5, $zero, $zero	# Set index value ($t5) to zero
draw_line_loop:
beq $t5, $a1, end_draw_line  # If $t5 == width ($a1), jump to end
sw $t4, 0($t0)		#   - Draw a pixel at memory location $t0
addi $t0, $t0, 4	#   - Increment $t0 by 4
addi $t5, $t5, 1	#   - Increment $t5 by 1
j draw_line_loop	#   - Jump to start of line drawing loop
end_draw_line:

addi $t0, $t0, 88	# Set $t0 to the first pixel of the next line.
			# Note: This value really should be calculated.
addi $t6, $t6, 1	#   - Increment $t6 by 1
j draw_rect_loop	#   - Jump to start of rectangle drawing loop
end_rect:

jr $ra 			# jump back to the calling program


Exit:
li $v0, 10 # terminate the program gracefully
syscall