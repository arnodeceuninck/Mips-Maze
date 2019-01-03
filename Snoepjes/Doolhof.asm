.globl main

.data
# Data voor readmazefile gebruikt
file: 	.asciiz "input.txt"
victory_file: .asciiz "victory.txt"
display_size: .byte 32
buffer: 	.space 1024 	# geheugen vrijgehouden voor het ingelezen bestand
wall:	.word 0x000000ff
passage:	.word 0x00000000
player_position:	.word 0x00ffff00
enemy:	.word 0x00ff0000
candy:	.word 0x00ffffff
exit_location:	.word 0x0000ff00
victory_message: .asciiz "Proficiat! Je hebt gewonnen! (OK)"
error_message_player:	.asciiz "De speler bevindt zich niet op de locatie die is meegegeven.\n"
error_message_stepsize:	.asciiz "De speler zet niet exact 1 stap\n"
error_message_passage:	.asciiz "De nieuwe positie is geen plaats waarop de speler kan staan\n"

exit_row:	.byte 0
exit_column:	.byte 0
candies_left:	.byte 0

.text
	j main	#SafetyFirst
	
########################################################################
#PROCEDURE to read a maze from the file in input.txt
# Parameters: filename in $a0
readmazefile:
	# Functie klaarzetten
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 36	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s4, -24($fp)
	sw	$s5, -28($fp)
	sw	$s6, -32($fp)	# s6 houdt het aantal snoepjes bij
	
	# Parameters ophalen
	move	$s0, $a0 # filename
	#s4 gaat de rij van de speler bijhouden
	#s5 gaat de kolom ervan bijhouden

	# Open het bestand 
	#la 	$a0, file # | is niet nodig, want file wordt al als parameter in a0 doorgegeven
	move	$s0, $a0
	li 	$a1, 0
	li 	$a2, 0
	li 	$v0, 13
	syscall

	# Laad de tekst van het bestand in het geheugen
	move 	$a0, $v0
	li 	$v0, 14
	la 	$a1, buffer
	li 	$a2, 1024 # aantal te lezen bytes
	syscall
	
	la 	$s1, buffer	# Het adres van de ingelezen tekst (string) wordt opgeslagen in $a0
	li	$s0, -1		# t2 houdt het nummer van het teken dat ik ga lezen bij
	li	$s2, 0	# Houdt het rijnr bij
	li	$s3, -1 # Houdt het karakternummer bij
	li	$s6, 0	# je begint met 0 snoepjes
next_pixel:
	addi	$s0, $s0, 1	# laat het kolomnr met 1 stijgen
	addi 	$s3, $s3, 1
	
	add	$t3, $s1, $s3	
	
	lb 	$t1, ($t3)	# laadt het karakter
	
	beq	$t1, '\0', finish	# Als we bij het einde van de string zijn, dan ronden we de functie af
	beq	$t1, '\n', next_row	# Als we aan een nieuwe lijn zitten moet er geen nieuwe pixel gekleurd worden
	beq	$t1, '\r', next_row	# Omdat op sommige OS'es er /r staat ipv /n
	beq	$t1, 'w', draw_wall
	beq	$t1, 'p', draw_passage
	beq	$t1, 's', draw_player
	beq	$t1, 'u', draw_exit_location
	beq	$t1, 'e', draw_enemy
	beq	$t1, 'c', draw_candy
	
finish:

	la	$t0, candies_left # Max. 2 return values, via datageheugen aantal snoepjes returnen dus
	sb	$s6, ($t0)
	
	# Functie afronden
	move	$v0, $s4    	# place result in return value location
	move	$v1, $s5
	
	
	lw	$s6, -32($fp)
	lw	$s5, -28($fp)
	lw	$s4, -24($fp)
	lw	$s3, -20($fp)
	lw	$s2, -16($fp)
	lw	$s1, -12($fp)	# reset saved register $s1
	lw	$s0, -8($fp)	# reset saved register $s0
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
next_row:
	addi	$s2, $s2, 1	# Laat het rijnr met 1 stijgen
	li	$s0, -1	# Start opnieuw aan het begin van de rij (0'de kolom dus)
	j	next_pixel
draw_enemy:
	la 	$t4, enemy
	j 	draw
draw_player:
	move	$s4, $s2	#Onthoud de rij van de speler
	move	$s5, $s0	# Onthoud het kolomnr
	la	$t4, player_position
	j 	draw
draw_wall:
	la 	$t4, wall
	j 	draw
draw_passage:
	la	$t4, passage
	j 	draw
draw_exit_location:
	# Onthou de positie van de uitgang, maar laat deze nog niet zien
	la	$t0, exit_row
	sb	$s2, ($t0)
	la	$t0, exit_column
	sb	$s0, ($t0)
	#la 	$t4, exit_location
	j 	draw_passage # teken gewoon een doorgang op de plaats van de uitgang
draw_candy:
	addi	$s6, $s6, 1 # Het aantal snoepjes op het speelveld stijgt met 1
	la	$t4, candy
	j 	draw
draw:
	la	$a0, ($s0)	# Het kolomnr laden als parameter 1
	la	$a1, ($s2)	# Het rijnr laden als parameter 2
	jal	displayposition	# Bereken de addresplaats van de pixel op de gevraagde rij en kolom
	lw	$t4, ($t4)
	sw 	$t4, ($v0)
	j	next_pixel
########################################################################

########################################################################
#PROCEDURE to calculate the address location of the pixel at column $a0 and row $a1
# Parameters: columnnr $a0, rownr $a1
displayposition:
	# Functie klaarzetten
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 24	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	
	# Parameters ophalen
	move	$s0, $a0	# kolomnr
	move	$s1, $a1	# rijnr

	# In de juiste kolom zetten
	lb $s2, display_size	# n_columns: the max column number
	
	mul $s0, $s0, 4 # 4 = stepsize
	add $s3, $gp, $s0 # $s3 is going to contain the final variable
	
	# In de juiste rij zetten 
	mul $s1, $s1, 4 # 4 = stepsize 
	mul $s1, $s1, $s2 # $s2 = aantal kolommen per rij 
	add $s3, $s3, $s1
	
	# Coordinates calculated	
	# Functie afronden
	move	$v0, $s3    	# place result in return value location

	lw	$s3, -20($fp)	# reset saved register $s3
	lw	$s2, -16($fp)	# reset saved register $s2
	lw	$s1, -12($fp)	# reset saved register $s1
	lw	$s0, -8($fp)	# reset saved register $s0
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
########################################################################
########################################################################
#PROCEDURE to move the player on the map
# Parameters: rijnr current player $a0, kolomnr current player $a1, nieuw rijnr $a2, nieuw kolomnr $a3
moveplayer:
	# Functie klaarzetten
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 32	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s4, -24($fp)
	sw	$s5, -28($fp)
	
	# Parameters ophalen
	move	$s0, $a0	# rijnr current player
	move	$s1, $a1	# kolomnr current player
	move	$s2, $a2	# new rownr
	move	$s3, $a3	# new columnnr
	
	move	$a0, $s1	# Laad de parameters om de $gp+offset te berekenen # kolomnr
	move	$a1, $s0	# Rijnr
	
	jal displayposition	# Bereken de addresslocatie van de pixel
	move	$s4, $v0	
	
	lw	$t0, player_position	# Laad de speler kleur in t0
	lw	$t1, ($s4)	# Laad de kleur van de pixel in t1
	bne	$t1, $t0, error_player	# Kijk of de pixel op de meegegeven locatie de player bevat
	
	# Bereken of er maar 1 stap gezet word
	sub	$t0, $s2, $s0	# Bereken het verschil tussen de oude en nieuwe rij
	mul	$t0, $t0, $t0	# kwadrateer het verschil tussen de rijen om een positief getal te krijgen
	
	sub	$t1, $s1, $s3	# Bereken het verschil tussen de oude en nieuwe kolom
	mul	$t1, $t1, $t1	# kwadrateer het verschil tussen de kolommen om een positief getal te krijgen
	
	add	$t0, $t0, $t1	# ofwel moet het verschil in rijen 1 zijn, ofwel het verschil in kolommen 1, de som moet dus sowieso 1 zijn
	bne	$t0, 1, error_stepsize
	
	# Laad het adres van de nieuwe plaats van de speler
	move	$a0, $s3	# laad het kolomnr van de nieuwe locatie in als parameter
	move	$a1, $s2	# laad het rijnr van de nieuwe locatie in als parameter
	jal	displayposition
	move	$s5, $v0	# De geheugenplaats van de nieuwe locatie pixel wordt opgeslagen. Het rijnr is niet meer nodig
	
	lw	$t0, wall	# Laad de kleur van een muur
	lw	$t1, ($s5)	# Laad de kleur van de nieuwe positie
	beq	$t1, $t0, error_passage	# Controleer of de nieuwe locatie geen muur
	# TODO: Hier moet de controle komen op exit location, enemy, ...
	
	# Er wordt maar 1 stap gezet, de nieuwe plaats is geen muur, we kunnen de speler dus gaan verplaatsen
	lw	$t0, ($s5)
	lw	$t2, candy
	beq	$t0, $t2, snoepje_opgegeten
	j	verplaats_speler

snoepje_opgegeten:
	la	$t0, candies_left
	lb	$t1, ($t0)
	addi	$t1, $t1, -1
	sb	$t1, ($t0)	
	j	verplaats_speler
	
verplaats_speler:
	lw	$t0, passage	# De oude plaats van de speler wordt een passage
	sw	$t0, ($s4)
	lw	$t0, player_position	# En op de nieuwe plaats komt de speler
	sw	$t0, ($s5)
	
	# Controleren op overwinning (Pas na de verplaatsing)
	# t1 is nogsteeds de kleur van de nieuwe positie
	lw	$t0, exit_location	# Laad de kleur van een muur
	bne	$t1, $t0, return_newposition	# Controleer of de nieuwe locatie een pad is
	
	# Als het programma hier geraakt is, ben je tot op de exit location geraakt	
	la	$a0, victory_message
	li	$v0, 4	# Syscall om de error te printen
	syscall
	
	# Wacht 0.2 seconde om de plaats op de overwinning te aanschouwen
	li 	$a0, 200
	li 	$v0, 32
	syscall
	
	# Laat het fancy overwinnigsscherm zien
	la	$a0, victory_file 	# laad de filename in als parameter # nog een probleem mee
	jal	readmazefile	# Call procedure
	
	# Sluit het programma af
	j exit
	
return_newposition:
	move	$v0, $s2    	# return new row
	move	$v1, $s3	# return new column

finish_moveplayer:
	# Functie afronden

	lw	$s5, -28($fp)
	lw	$s4, -24($fp)
	lw	$s3, -20($fp)	# reset saved register $s3
	lw	$s2, -16($fp)	# reset saved register $s2
	lw	$s1, -12($fp)	# reset saved register $s1
	lw	$s0, -8($fp)	# reset saved register $s0
	lw	$ra, -4($fp)    # get return address from frame
	move	$sp, $fp        # get old frame pointer from current fra
	lw	$fp, ($sp)	# restore old frame pointer
	jr	$ra
error_player:
	# Laad de error message
	la	$a0, error_message_player
	j move_failed
	
error_stepsize:
	# Laad de error message
	la	$a0, error_message_stepsize
	j move_failed
error_passage:
	# Laad de error message
	la	$a0, error_message_passage
	j move_failed
	
move_failed:

	# Print de error message
	li	$v0, 4	# Syscall om de error te printen
	syscall
	
	move	$v0, $s0    	# return old row
	move	$v1, $s1	# return old column
	j finish_moveplayer
########################################################################

#Starting Point
main:
	# TODO: fix parameters en laat positie speler returnen
	la	$a0, file 	# laad de filename in als parameter # nog een probleem mee
	#move	$a0, $t0	# Put procedure arguments
	#move	$a1, $t1	# Put procedure arguments
	jal	readmazefile	# Call procedure
	
	# s0 houdt het rijnr van de speler bij
	# s1 houdt het kolomnr van de speler bij
	move 	$s0, $v0	# Get procedure result
	move	$s1, $v1
	
	# Test op verplaatsen player
	#li	$a0, 1	# Huidige positie
	#li	$a1, 6
	#li	$a2, 1	# 1 stap naar rechts
	#li	$a3, 5
	#jal 	moveplayer
	
	# s0 houdt het rijnr van de speler bij
	# s1 houdt het kolomnr van de speler bij
	#li	$s0, 1
	#li	$s1, 5
	
	j 	game_loop
	
game_loop: 
	j sleep
continue: 
	lb	$s2, candies_left
	beqz	$s2, draw_exit
	# check for input
	lw $t1, 0xffff0000
	beq $t1, 1, check_input
	
	## no input, asking for input
	#la $a0, text
	#li $v0, 4
	#syscall
	
	j game_loop
	
check_input:
	lw $t0, 0xffff0004
	
	# TODO: plaats deze lijntjes terug voor indienen
	#beq $t0, 'z', move_up
	#beq $t0, 's', move_down
	#beq $t0, 'q', move_left
	#beq $t0, 'd', print_right
	beq $t0, 'w', move_up
	beq $t0, 's', move_down
	beq $t0, 'a', move_left
	beq $t0, 'd', move_right
	
	beq $t0, 'x', exit
	j sleep
move_up:
	add	$t0, $s0, -1 # Rijnummer daalt met 1
	move	$t1, $s1	# Kolomnr blijft hetzelfde
	j move
move_down:
	add	$t0, $s0, 1 # Rijnummer stijgt met 1
	move	$t1, $s1	# Kolomnr blijft hetzelfde
	j move
move_left:
	add	$t1, $s1, -1 # Kolomnummer daalt met 1
	move	$t0, $s0	# Rijnnr blijft hetzelfde
	j move
move_right:
	add	$t1, $s1, 1 # Kolomnummer stijgt met 1
	move	$t0, $s0	# Rijnr blijft hetzelfde
	j move
move:
	move	$a0, $s0	# Huidige positie
	move	$a1, $s1
	move	$a2, $t0	# Positie na verplaatsing
	move	$a3, $t1
	jal 	moveplayer
	
	move	$s0, $v0	# Sla de gereturnde (nieuwe?) positie op
	move	$s1, $v1
	
	j 	game_loop

sleep:
	
	# Sleep 60ms
	li $a0, 60
	li $v0, 32
	syscall
	
	j continue
	
draw_exit:
	# Laad de positie van de uitgang, en laat ze zien
	lb	$a1, exit_row
	lb	$a0, exit_column
	jal	displayposition	# Bereken de addresplaats van de pixel op de gevraagde rij en kolom
	la 	$t4, exit_location
	lw	$t4, ($t4)
	sw 	$t4, ($v0)
	
	# zorg dat candies_left niet op 0 blijft staan, anders blijven we de uitgang opnieuw tekenen, terwijl dit maar 1x moet
	la	$t1, candies_left
	li	$t0, -1
	sb	$t0, ($t1)
	j	continue

exit:
	li   $v0, 10 		# system call for exit
	syscall      		# exit (back to operating system)
