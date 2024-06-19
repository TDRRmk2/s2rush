; ===========================================================================
; ----------------------------------------------------------------------------
; Object 02 - Blaze
; ----------------------------------------------------------------------------
; Sprite_19F50: Object_Sonic:
; Unlike Tails in the vanilla game, this object depends a lot more on
; Obj01/Sonic, so most of the code is just what has to be different
; between both characters.

Tails_Animate = Sonic_Animate
LoadTailsDynPLC = LoadSonicDynPLC

Obj02:
	; a0=character
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	Obj02_Normal			; if not, branch
	jmp	(DebugMode).l
; ---------------------------------------------------------------------------
; loc_19F5C:
Obj02_Normal:
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	Obj02_Index(pc,d0.w),d1
	jmp	Obj02_Index(pc,d1.w)
; ===========================================================================
; off_19F6A: Obj01_States:
Obj02_Index:	offsetTable
		offsetTableEntry.w Obj02_Init		;  0
		offsetTableEntry.w Obj01_Control	;  2
		offsetTableEntry.w Obj01_Hurt		;  4
		offsetTableEntry.w Obj01_Dead		;  6
		offsetTableEntry.w Obj01_Gone		;  8
		offsetTableEntry.w Obj01_Respawning	; $A
; ===========================================================================
; loc_19F76: Obj_01_Sub_0: Obj01_Main:
Obj02_Init:
	addq.b	#2,routine(a0)	; => Obj01_Control
	move.b	#$13,y_radius(a0) ; this sets Sonic's collision height (2*pixels)
	move.b	#9,x_radius(a0)
	move.l	#MapUnc_Blaze,mappings(a0)
	move.b	#2,priority(a0)
	move.b	#$18,width_pixels(a0)
	move.b	#4,render_flags(a0)
	move.w	#$600,(Sonic_top_speed).w	; set Sonic's top speed
	move.w	#$C,(Sonic_acceleration).w	; set Sonic's acceleration
	move.w	#$80,(Sonic_deceleration).w	; set Sonic's deceleration
	tst.b	(Last_star_pole_hit).w
	bne.s	Obj02_Init_Continued
	; only happens when not starting at a checkpoint:
	move.w	#make_art_tile(ArtTile_ArtUnc_Blaze,0,0),art_tile(a0)
	bsr.w	Adjust2PArtPointer
	move.b	#$C,top_solid_bit(a0)
	move.b	#$D,lrb_solid_bit(a0)
	move.w	x_pos(a0),(Saved_x_pos).w
	move.w	y_pos(a0),(Saved_y_pos).w
	move.w	art_tile(a0),(Saved_art_tile).w
	move.w	top_solid_bit(a0),(Saved_Solid_bits).w

Obj02_Init_Continued:
	move.b	#0,flips_remaining(a0)
	move.b	#4,flip_speed(a0)
	move.b	#0,(Super_Sonic_flag).w
	move.b	#30,air_left(a0)
	subi.w	#$20,x_pos(a0)
	addi_.w	#4,y_pos(a0)
	move.w	#0,(Sonic_Pos_Record_Index).w

	move.w	#$3F,d2
-	bsr.w	Sonic_RecordPos
	subq.w	#4,a1
	move.l	#0,(a1)
	dbf	d2,-

	addi.w	#$20,x_pos(a0)
	subi_.w	#4,y_pos(a0)
	bra		Obj01_Control

; loc_1B84E:
LoadBlazeDynPLC_Part2:
	cmp.b	(Blaze_LastLoadedDPLC).w,d0
	beq		BPLC_Return
	move.b	d0,(Blaze_LastLoadedDPLC).w
	lea	(MapRUnc_Blaze).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	BPLC_Return
	move.w	#tiles_to_bytes(ArtTile_ArtUnc_Blaze),d4
; loc_1B86E:
BPLC_ReadEntry:
	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#ArtUnc_Blaze,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,BPLC_ReadEntry	; repeat for number of entries
BPLC_Return:
	rts
