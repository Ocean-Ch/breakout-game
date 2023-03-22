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

.text
lw $t0, displayAddress # $t0 stores the base address for display
li $t1, 0xff0000 # $t1 stores the red colour code
li $t2, 0x00ff00 # $t2 stores the green colour code
li $t3, 0x0000ff # $t3 stores the blue colour code
# sw $t1, 0($t0) # paint the first (top-left) unit red.
# sw $t2, 4($t0) # paint the second unit on the first row green. Why $t0+4?
# sw $t3, 128($t0) # paint the first unit on the second row blue. Why +128?

add $t4, $t1, $t2	#  $t4 = $t1 + $t2  ($t4 = yellow)
sw $t1, 0($t0) 		# paint the first (top-left) unit red.
addi $t0, $t0, 4   	# move to the next pixel over in the bitmap
sw $t2, 0($t0) 		# paint the second unit on the first row green. Why $t0+4?
addi $t0, $t0, 124   	# move to the next pixel over in the bitmap
sw $t3, 0($t0) 		# paint the first unit on the second row blue. Why $t0+124?
addi $t0, $t0, 4   	# move to the next pixel over in the bitmap
sw $t4, 0($t0) 		# paint the second unit on the second row yellow.

# Draw a 2x3 cyan rectangle
add $t6, $t2, $t3	#  $t6 = $t2 + $t3  ($t6 = cyan)
addi $t0, $t0, 252   	# move to the first pixel two rows down in the bitmap
sw $t6, 0($t0) 		# paint this pixel cyan
addi $t0, $t0, 4   	# move to the next pixel over in the bitmap
sw $t6, 0($t0) 		# paint this pixel cyan
addi $t0, $t0, 4   	# move to the next pixel over in the bitmap
sw $t6, 0($t0) 		# paint this pixel cyan
addi $t0, $t0, 120   	# move to the first pixel in the next row
sw $t6, 0($t0) 		# paint this pixel cyan
addi $t0, $t0, 4   	# move to the next pixel over in the bitmap
sw $t6, 0($t0) 		# paint this pixel cyan
addi $t0, $t0, 4   	# move to the next pixel over in the bitmap
sw $t6, 0($t0) 		# paint this pixel cyan


# Add some assembly code below, as an experiment
# - Start with arithmetic operations
add $t4, $t1, $t2	#  $t4 = $t1 + $t2  ($t4 = yellow)
add $t5, $t4, $t3	#  $t5 = $t4 + $t3  ($t5 = white)
sub $t6, $t5, $t2	#  $t6 = $t5 - $t1  ($t6 = cyan)
addi $t7, $t6, 42	#  This will work
addi $t7, $zero, 8	#  Store 8 into $t7
addi $t8, $zero, 3	#  Store 3 into $zero
mult $t7, $t8		#  $t7 * $t8
mflo $t9		#  Store result into $t9
div $t7, $t8		#  $t7 / $t8
mflo $t9		#  Store result into $t9
# - Next, some logical operations
or $t9, $t1, $t2	#  $t1 | $t2
and $t9, $t1, $t2	#  $t1 & $t2
xori $t9, $t3, 0xffffffff	# invert the bits of $t3
# - Finally, some shifting operations
sll $t9, $t9, 1		# shift $t9 left by one bit
sll $t9, $t9, 1		# shift $t9 left by one bit
sll $t9, $t9, 1		# shift $t9 left by one bit
sll $t9, $t9, 1		# shift $t9 left by one bit
sra $t9, $t9, 1		# shift $t9 right by one bit
sra $t9, $t9, 1		# shift $t9 right by one bit
sra $t9, $t9, 1		# shift $t9 right by one bit
sra $t9, $t9, 1		# shift $t9 right by one bit



Exit:
li $v0, 10 # terminate the program gracefully
syscall