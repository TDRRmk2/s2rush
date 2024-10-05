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

; ---------------------------------------------------------------------------
; Subroutine to animate Blaze's sprites
; See also: AnimateSprite
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B350:
Blaze_Animate:
	lea	(BlazeAniData).l,a1
	;tst.b	(Super_Sonic_flag).w
	;beq.s	+
	;lea	(SuperSonicAniData).l,a1
+
	moveq	#0,d0
	move.b	anim(a0),d0
	cmp.b	prev_anim(a0),d0	; has animation changed?
	beq.s	BAnim_Do		; if not, branch
	move.b	d0,prev_anim(a0)	; set previous animation
	move.b	#0,anim_frame(a0)	; reset animation frame
	move.b	#0,anim_frame_duration(a0)	; reset frame duration
	bclr	#5,status(a0)
; loc_1B384:
BAnim_Do:
	add.w	d0,d0
	adda.w	(a1,d0.w),a1	; calculate address of appropriate animation script
	move.b	(a1),d0
	bmi.s	BAnim_WalkRun	; if animation is walk/run/roll/jump, branch
	bra		SAnim_DoCont

; ===========================================================================
BAnim_WalkRun:
	addq.b	#1,d0		; is the start flag = $FF?
	bne 	SAnim_Roll	; if not, branch
	moveq	#0,d0		; is animation walking/running?
	move.b	flip_angle(a0),d0	; if not, branch
	bne 	SAnim_Tumble
	moveq	#0,d1
	move.b	angle(a0),d0	; get Sonic's angle
	bmi.s	+
	beq.s	+
	subq.b	#1,d0
+
	move.b	status(a0),d2
	andi.b	#1,d2		; is Sonic mirrored horizontally?
	bne.s	+		; if yes, branch
	not.b	d0		; reverse angle
+
	addi.b	#$10,d0		; add $10 to angle
	bpl.s	+		; if angle is $0-$7F, branch
	moveq	#3,d1
+
	andi.b	#$FC,render_flags(a0)
	eor.b	d1,d2
	or.b	d2,render_flags(a0)
	btst	#5,status(a0)
	bne 	SAnim_Push
	lsr.b	#4,d0		; divide angle by 16
	andi.b	#6,d0		; angle must be 0, 2, 4 or 6
	mvabs.w	inertia(a0),d2	; get Sonic's "speed" for animation purposes
    if status_sec_isSliding = 7
	tst.b	status_secondary(a0)
	bpl.w	+
    else
	btst	#status_sec_isSliding,status_secondary(a0)
	beq.w	+
    endif
	add.w	d2,d2
+
	;tst.b	(Super_Sonic_flag).w
	;bne.s	SAnim_Super
	lea	(BlzAni_Run).l,a1	; use running animation
	cmpi.w	#$600,d2		; is Sonic at running speed?
	bhs.s	+			; use running animation
	lea	(BlzAni_Walk).l,a1	; if yes, branch
	add.b	d0,d0
+
	add.b	d0,d0
	move.b	d0,d3
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	1(a1,d1.w),d0
	cmpi.b	#-1,d0
	bne.s	+
	move.b	#0,anim_frame(a0)
	move.b	1(a1),d0
+
	move.b	d0,mapping_frame(a0)
	add.b	d3,mapping_frame(a0)
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	return_1B4AC_blz
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)	; modify frame duration
	addq.b	#1,anim_frame(a0)		; modify frame number

return_1B4AC_blz:
	rts

; ---------------------------------------------------------------------------
; Animation script - Blaze
; ---------------------------------------------------------------------------
; off_1B618:
BlazeAniData:			offsetTable
BlzAni_Walk_ptr:		offsetTableEntry.w BlzAni_Walk		;  0 ;   0
BlzAni_Run_ptr:			offsetTableEntry.w BlzAni_Run		;  1 ;   1
BlzAni_Roll_ptr:		offsetTableEntry.w BlzAni_Roll		;  2 ;   2
BlzAni_Roll2_ptr:		offsetTableEntry.w BlzAni_Roll2		;  3 ;   3
BlzAni_Push_ptr:		offsetTableEntry.w BlzAni_Push		;  4 ;   4
BlzAni_Wait_ptr:		offsetTableEntry.w BlzAni_Wait		;  5 ;   5
BlzAni_Balance_ptr:		offsetTableEntry.w BlzAni_Balance	;  6 ;   6
BlzAni_LookUp_ptr:		offsetTableEntry.w BlzAni_LookUp	;  7 ;   7
BlzAni_Duck_ptr:		offsetTableEntry.w BlzAni_Duck		;  8 ;   8
BlzAni_Spindash_ptr:		offsetTableEntry.w BlzAni_Spindash	;  9 ;   9
BlzAni_Blink_ptr:		offsetTableEntry.w BlzAni_Blink		; 10 ;  $A
BlzAni_GetUp_ptr:		offsetTableEntry.w BlzAni_GetUp		; 11 ;  $B
BlzAni_Balance2_ptr:		offsetTableEntry.w BlzAni_Balance2	; 12 ;  $C
BlzAni_Stop_ptr:		offsetTableEntry.w BlzAni_Stop		; 13 ;  $D
BlzAni_Float_ptr:		offsetTableEntry.w BlzAni_Float		; 14 ;  $E
BlzAni_Float2_ptr:		offsetTableEntry.w BlzAni_Float2	; 15 ;  $F
BlzAni_Spring_ptr:		offsetTableEntry.w BlzAni_Spring	; 16 ; $10
BlzAni_Hang_ptr:		offsetTableEntry.w BlzAni_Hang		; 17 ; $11
BlzAni_Dash2_ptr:		offsetTableEntry.w BlzAni_Dash2		; 18 ; $12
BlzAni_Dash3_ptr:		offsetTableEntry.w BlzAni_Dash3		; 19 ; $13
BlzAni_Hang2_ptr:		offsetTableEntry.w BlzAni_Hang2		; 20 ; $14
BlzAni_Bubble_ptr:		offsetTableEntry.w BlzAni_Bubble	; 21 ; $15
BlzAni_DeathBW_ptr:		offsetTableEntry.w BlzAni_DeathBW	; 22 ; $16
BlzAni_Drown_ptr:		offsetTableEntry.w BlzAni_Drown		; 23 ; $17
BlzAni_Death_ptr:		offsetTableEntry.w BlzAni_Death		; 24 ; $18
BlzAni_Hurt_ptr:		offsetTableEntry.w BlzAni_Hurt		; 25 ; $19
BlzAni_Hurt2_ptr:		offsetTableEntry.w BlzAni_Hurt		; 26 ; $1A
BlzAni_Slide_ptr:		offsetTableEntry.w BlzAni_Slide		; 27 ; $1B
BlzAni_Blank_ptr:		offsetTableEntry.w BlzAni_Blank		; 28 ; $1C
BlzAni_Balance3_ptr:		offsetTableEntry.w BlzAni_Balance3	; 29 ; $1D
BlzAni_Balance4_ptr:		offsetTableEntry.w BlzAni_Balance4	; 30 ; $1E
SupBlzAni_Transform_ptr:	offsetTableEntry.w SupSonAni_Transform	; 31 ; $1F
BlzAni_Lying_ptr:		offsetTableEntry.w BlzAni_Lying		; 32 ; $20
BlzAni_LieDown_ptr:		offsetTableEntry.w BlzAni_LieDown	; 33 ; $21

BlzAni_Walk:	dc.b $FF, $D, $E, $F, $10, $11, $12, $FF
	rev02even
BlzAni_Run:	dc.b $FF,$2D,$2E,$2F,$30,$FF,$FF,$FF,$FF,$FF
	rev02even
BlzAni_Roll:	dc.b $FE,$3D,$41,$3E,$41,$3F,$41,$40,$41,$FF
	rev02even
BlzAni_Roll2:	dc.b $FE,$3D,$41,$3E,$41,$3F,$41,$40,$41,$FF
	rev02even
BlzAni_Push:	dc.b $FD,$48,$49,$4A,$4B,$FF,$FF,$FF,$FF,$FF
	rev02even
BlzAni_Wait:
	dc.b   $17,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 2, 3, 3, 3, 4, $FE,  2
	rev02even
BlzAni_Balance:	dc.b   9,$CC,$CD,$CE,$CD,$FF
	rev02even
BlzAni_LookUp:	dc.b   5, $C, $FF
	rev02even
BlzAni_Duck:	dc.b   5, $4D, $FF
	rev02even
BlzAni_Spindash:dc.b   0,$42,$43,$42,$44,$42,$45,$42,$46,$42,$47,$FF
	rev02even
BlzAni_Blink:	dc.b   1,  2,$FD,  0
	rev02even
BlzAni_GetUp:	dc.b   3, $A,$FD,  0
	rev02even
BlzAni_Balance2:dc.b   3,$C8,$C9,$CA,$CB,$FF
	rev02even
BlzAni_Stop:	dc.b   5,$D2,$D3,$D4,$D5,$FD,  0 ; halt/skidding animation
	rev02even
BlzAni_Float:	dc.b   7,$54,$59,$FF
	rev02even
BlzAni_Float2:	dc.b   7,$54,$55,$56,$57,$58,$FF
	rev02even
BlzAni_Spring:	dc.b $2F,$5B,$FD,  0
	rev02even
BlzAni_Hang:	dc.b   1,$50,$51,$FF
	rev02even
BlzAni_Dash2:	dc.b  $F,$43,$43,$43,$FE,  1
	rev02even
BlzAni_Dash3:	dc.b  $F,$43,$44,$FE,  1
	rev02even
BlzAni_Hang2:	dc.b $13,$6B,$6C,$FF
	rev02even
BlzAni_Bubble:	dc.b  $B,$5A,$5A,$11,$12,$FD,  0 ; breathe
	rev02even
BlzAni_DeathBW:	dc.b $20,$5E,$FF
	rev02even
BlzAni_Drown:	dc.b $20,$5D,$FF
	rev02even
BlzAni_Death:	dc.b $20,$5C,$FF
	rev02even
BlzAni_Hurt:	dc.b $40,$4E,$FF
	rev02even
BlzAni_Slide:	dc.b   9,$4E,$4F,$FF
	rev02even
BlzAni_Blank:	dc.b $77,  0,$FD,  0
	rev02even
BlzAni_Balance3:dc.b $13,$D0,$D1,$FF
	rev02even
BlzAni_Balance4:dc.b   3,$CF,$C8,$C9,$CA,$CB,$FE,  4
	rev02even
BlzAni_Lying:	dc.b   9,  8,  9,$FF
	rev02even
BlzAni_LieDown:	dc.b   3,  7,$FD,  0
	even
