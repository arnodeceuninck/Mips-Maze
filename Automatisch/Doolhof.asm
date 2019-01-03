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

victory_message: .asciiz "\nProficiat! Je hebt gewonnen! (OK)\n"
error_message_player:	.asciiz "\nDe speler bevindt zich niet op de locatie die is meegegeven.\n"
error_message_stepsize:	.asciiz "\nDe speler zet niet exact 1 stap\n"
error_message_passage:	.asciiz "\nDe nieuwe positie is geen plaats waarop de speler kan staan\n"
message_move_from:	.asciiz "\nMoving from:\n"
message_move_to:	.asciiz "\nTo:\n"

possible_move_tbl:	.space 8  # 2*1*4 (4 keer een koppel van 2 getallen) 

visited:	.space 2048 # 1 (size byte) *2 (2 numbers per coordinate) * 32 (columns) * 32 (rows)
size_visited:	.word 0
.text
	j main	#SafetyFirst
	
########################################################################
#PROCEDURE to read a maze from the file in input.txt
# Parameters: filename in $a0
readmazefile:
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
	sw	$s6, -28($fp)
		
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
	# Functie afronden
	move	$v0, $s4    	# place result in return value location
	move	$v1, $s5
	
	lw	$s6, -28($fp)
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
# Alle draw_ functies laden een kleur om vervolgens te tekenen
draw_enemy:
	la 	$t4, enemy
	j 	draw
draw_player:
	# TODO store coordinates
	move	$s4, $s2	#Onthoud de rij van de speler
	move	$s5, $s0	# Onthoud het kolomnr
	la	$s6, player_position
	j 	draw
draw_wall:
	la 	$s6, wall
	j 	draw
draw_passage:
	la	$s6, passage
	j 	draw
draw_exit_location:
	la 	$s6, exit_location
	j 	draw
draw_candy:
	la	$s6, candy
	j 	draw
draw:
	la	$a0, ($s0)	# Het kolomnr laden als parameter 1
	la	$a1, ($s2)	# Het rijnr laden als parameter 2
	jal	displayposition	# Bereken de addresplaats van de pixel op de gevraagde rij en kolom
	lw	$t4, ($s6)	# Laad de kleur die in draw_ is bepaald
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
	
	# Debug messages:
	la	$a0, message_move_from
	li	$v0, 4
	syscall
	
	move	$a0, $s0
	li	$v0, 1
	syscall
	
	move	$a0, $s1
	li	$v0, 1
	syscall
	
	la	$a0, message_move_to
	li	$v0, 4
	syscall
	
	move	$a0, $s2
	li	$v0, 1
	syscall
	
	move	$a0, $s3
	li	$v0, 1
	syscall

			
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
	beq	$t1, $t0, error_passage	# Controleer of de nieuwe locatie een pad is
	# TODO: Hier moet de controle komen op exit location, enemy, ...
	
	# Er wordt maar 1 stap gezet, de nieuwe plaats is geen muur, we kunnen de speler dus gaan verplaatsen
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
	# sleep time (0.05s)
	li	$a0, 50
	li	$v0, 32
	syscall

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
########################################################################
# PROCEDURE find a way to the exit
# Parameters: location row in $a0, location column in $a1, visited in $a2 # visited is een array van posities 
player_dfs:
	# Functie klaarzetten
	sw	$fp, 0($sp)	# push old frame pointer (dynamic link)
	move	$fp, $sp	# frame	pointer now points to the top of the stack
	subu	$sp, $sp, 40	# allocate 16 bytes on the stack
	sw	$ra, -4($fp)	# store the value of the return address
	sw	$s0, -8($fp)	# save locally used registers
	sw	$s1, -12($fp)
	sw	$s2, -16($fp)
	sw	$s3, -20($fp)
	sw	$s4, -24($fp)
	sw	$s5, -28($fp)
	sw	$s6, -32($fp)
	sw	$s7, -36($fp)
	
	
	# Parameters ophalen
	move	$s0, $a0	# rijnr current player
	move	$s1, $a1	# kolomnr current player
	
	#lw	$s2, size_visited	# remember this number to restore it at the end - this makes the algorithm slower
	
	# Controleren op finish
	# huidige $gp+offset locatie ophalen
	move	$a0, $s1	# Laad de parameters om de $gp+offset te berekenen # kolomnr
	move	$a1, $s0	# Rijnr
	jal displayposition	# Bereken de addresslocatie van de pixel
	move	$s4, $v0	
	
	lw	$t0, exit_location	# Laad de exit_location kleur in t0
	lw	$t1, ($s4)	# Laad de kleur van de current_player pixel in t1
	beq	$t1, $t0, exit	# Kijk of de pixel op de meegegeven locatie de player bevat
				# victory # De victory message zelf wordt al geprint in moveplayer
	
	# maak de array voor mogleijke bewegingen
	la	$s3, possible_move_tbl	# Laad de vrijgehouden geheugenplaatsen voor een 2*8*4 array
	li	$t1, -1
	li	$t2, 0
	li	$t3, 1
	sb	$t1, 0($s3) # Plaats (-1, 0) in de array
	sb	$t2, 1($s3) 
	sb	$t3, 2($s3) # Plaats (1, 0) in de array
	sb	$t2, 3($s3) 
	sb	$t2, 4($s3) # Plaats (0, -1) in de array
	sb	$t1, 5($s3) 
	sb	$t2, 6($s3) # Plaats (0, 1) in de array
	sb	$t3, 7($s3)
possible_move:
	lb	$s5, 0($s3) # Laad de verplaatsing voor de rij
	lb	$s6, 1($s3) # Laad de verplaatsing voor de kolom
	add	$s5, $s5, $s0 # Bereken de nieuwe rij door de verplaatsing op te tellen bij de huidige positie
	add	$s6, $s6, $s1 # idem, maar voor kolom
	
	# controleer of ($s5, $s6) al in visited zit
	la	$s4, visited # De addresplaats van de array met alle bezochte plaatsen
	la	$s7, size_visited # Het aantal bytes in de array met bezochte plaatsen (altijd even, want ieder coordinaat bestaat uit 2 getallen)
	lw	$s7, ($s7)
	move	$t4, $s4
	move	$t7, $s7
loop_visited:
	beqz	$t7, not_in_visited # Alle elementen in lijst gepasseerd, zonder een identieke te vinden
	add	$t0, $t4, $t7 # Bereken de laatste adresplaats # addr_pl + aantal_el = laatste adresplaats
	lb	$t5, -1($t0) # Laad de kolomwaarde van deze positie in visited
	lb	$t6, -2($t0) # laad de rijwaarde van dit adres in visited
	bne	$t5, $s5, next_for_loop_cycle # Kijk of de rijen gelijk zijn
	bne	$t6, $s6, next_for_loop_cycle # Kijk of de kolommen gelijk zijn
	# Eens aan deze regel gekomen, zijn zowel de rijen als de kolommen gelijk
	j continue_next_move

next_for_loop_cycle:
	addi	$t7, $t7, -2	# Een element in visited minder om te controleren
	j	loop_visited 
	
not_in_visited:
	# Heronder word de code binnen de eerste if uitgevoerd
	#lw	$s7, size_visited # Het aantal elementen in de array met bezochte plaatsen # zit er nogsteeds in van voor loop_visited
	addi	$s7, $s7, 2 # nieuwe positie, visited wordt 2 bytes groter
	add	$t0, $s4, $s7 # begin_addr + aantal_el = laatste addr_plaats
	sb	$s5, -1($t0) # plaats de nieuwe rij in visited
	sb	$s6, -2($t0) # plaats de nieuwe kolom in visited
	la	$t0, size_visited
	sw	$s7, ($t0) # sla de nieuwe grootte van visited op
	
	# Verplaats de speler
	move 	$a0, $s0 # huidige rijnummer speler
	move	$a1, $s1 # huidige kolomnr speler
	move	$a2, $s5 # nieuwe rijnr speler
	move	$a3, $s6 # nieuwe kolomnr speler
	jal moveplayer
	# $v0 bevat momenteel het nieuwe rijnr vd speler, $v1 het kolomnt
	move	$s5, $v0
	move	$s6, $v1
	
	# niet 2x hetzelfde resultaat
	bne	$s5, $s0, new_position_not_equal
	bne	$s6, $s1, new_position_not_equal
	# vanaf hier is de nieuwe positie wel gelijk, en moeten we dus naar de volgende move
	j 	continue_next_move
new_position_not_equal:
	move	$a0, $s5
	move	$a1, $s6
	move	$a2, $s2
	jal	player_dfs
	
	#lw      $s7, size_visited # laad de aangepaste size van visit - niet meer nodig, gebeurt bij elke next move
	# Ga terug naar de orginele positie
	# Verplaats de speler
	move 	$a0, $s5 # huidige rijnummer speler
	move	$a1, $s6 # huidige kolomnr speler
	move	$a2, $s0 # nieuwe rijnr speler
	move	$a3, $s1 # nieuwe kolomnr speler
	jal moveplayer
	
	j 	continue_next_move

continue_next_move:
	addi	$s3, $s3, 2 # ga naar de volgende move in moves (2*1) verder
	la	$t3 possible_move_tbl
	addi	$t3, $t3, 8
	beq	$s3, $t3, finish_dfs # alle 2*4 moves uitgevoerd
	j	possible_move
	
finish_dfs:
	# restore visited terug naar de oorspronkelijke grootte - niet nodig, door de aangepaste grootte te behouden worden routes niet overbodig dubbel gedaan
	#la	$t0, size_visited
	#sw	$s2, ($t0) 
	
	# Functie afronden
	lw	$s7, -36($fp)
	lw	$s6, -32($fp)
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
########################################################################

#Starting Point
main:
	la	$a0, file 	# laad de filename in als parameter # nog een probleem mee
	jal	readmazefile	# Call procedure
	
	move 	$a0, $v0	# Get procedure result
	move	$a1, $v1
	la	$a2, visited
	jal player_dfs

exit:
	li   $v0, 10 		# system call for exit
	syscall      		# exit (back to operating system)
