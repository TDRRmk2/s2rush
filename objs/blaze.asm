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
	move.w	#0,(Tails_Pos_Record_Index).w

	move.w	#$3F,d2
-	bsr.w	Blaze_RecordPos
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
	lea	(BlzAni_Fall).l,a1
	btst	#1, status(a0)
	bne		+
	lea (BlzAni_FullSpd).l,a1
	cmpi.w  #$900,d2
	bhs		+
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
BlzAni_Fall_ptr:		offsetTableEntry.w BlzAni_Fall		; 22 ; $16
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
BlzAni_FullSpd_ptr:		offsetTableEntry.w BlzAni_FullSpd   ; 34 ; $22
BlzAni_Hover_ptr:		offsetTableEntry.w BlzAni_Hover     ; 35 ; $23
BlzAni_AxelT_ptr:		offsetTableEntry.w BlzAni_AxelT		; 36 ; $24
BlzAni_Trick1_ptr:		offsetTableEntry.w BlzAni_Trick1	; 37 ; $25
BlzAni_Trick2_ptr:		offsetTableEntry.w BlzAni_Trick2	; 38 ; $26
BlzAni_Trick3_ptr:		offsetTableEntry.w BlzAni_Trick3	; 39 ; $27
BlzAni_SpringFall_ptr:	offsetTableEntry.w BlzAni_SpringFall	; 40 ; $28
BlzAni_AirBoost_ptr:	offsetTableEntry.w BlzAni_AirBoost	; 41 ; $29

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
	dc.b   $17,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 3, 2, 3, 2, 3, 2, 3, 2, 4, 5, $FE,  2
	rev02even
BlzAni_Balance:	dc.b   16,$6D,$6E,$FF
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
BlzAni_Balance2:dc.b   16,$6D,$6E,$FF
	rev02even
BlzAni_Stop:	dc.b   5,$77,$78,$FF ; halt/skidding animation
	rev02even
BlzAni_Float:	dc.b   7,$54,$59,$FF
	rev02even
BlzAni_Float2:	dc.b   7,$54,$55,$56,$57,$58,$FF
	rev02even
BlzAni_Spring:	dc.b $2F,$5B,$FD,(BlzAni_SpringFall_ptr-BlazeAniData)/2
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
BlzAni_Fall:	dc.b 5,$7D,$7E,$FF,$FF,$FF,$FF,$FF,$FF,$FF
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
BlzAni_Balance3:dc.b   16,$6D,$6E,$FF
	rev02even
BlzAni_Balance4:dc.b   16,$6D,$6E,$FF
	rev02even
BlzAni_Lying:	dc.b   9,  8,  9,$FF
	rev02even
BlzAni_LieDown:	dc.b   3,  7,$FD,  0
	rev02even
BlzAni_FullSpd:	dc.b $FF,$7B,$7C,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	rev02even
BlzAni_Hover:	dc.b 5, $8B, $8C, $FF
	rev02even
BlzAni_AxelT:	dc.b 7, 6, 7, 8, 9, $A, $FF
	rev02even
BlzAni_Trick1:	dc.b 7, $41, $59, $FE, 1
	rev02even
BlzAni_Trick2:	dc.b 7, $41, $77, $FE, 1
	rev02even
BlzAni_Trick3:	dc.b 7, $41, $5A, $FE, 1
	rev02even
BlzAni_SpringFall: dc.b 5,$7D,$7E,$FF
	rev02even
BlzAni_AirBoost: dc.b $10,$8B,$FF
	even

Blaze_HoverSpd = 32
Blaze_AxelSpd = -1750
Blaze_BoostSpd = $9A0
Blaze_FlameFreq = 4

Blaze_Tricks:
	move.b	anim(a0), d0
	cmpi.b 	#(BlzAni_Spring_ptr-BlazeAniData)/2, d0
	beq		.doTrick
	cmpi.b 	#(BlzAni_SpringFall_ptr-BlazeAniData)/2, d0
	beq		.doTrick
	cmpi.b 	#(BlzAni_Trick1_ptr-BlazeAniData)/2, d0
	beq		.inTrick
	cmpi.b 	#(BlzAni_Trick2_ptr-BlazeAniData)/2, d0
	beq		.inTrick
	cmpi.b 	#(BlzAni_Trick3_ptr-BlazeAniData)/2, d0
	beq		.inTrick
	bra 	.ret
.inTrick:
	addq.b  #1, (Trick_Timer)
	cmpi.b  #30, (Trick_Timer)
	blo		.ret
.doTrick:
	move.b	(Ctrl_1_Press_Logical).w, d0
	andi	#button_B_mask|button_C_mask, d0
	beq     .ret
	move.b  #0, (Trick_Timer)
	jsr 	RandomNumber
	andi.b  #3, d0
	cmpi.b  #3, d0
	bne 	+
	move.b  #0, d0
+
	addi.b	#(BlzAni_Trick1_ptr-BlazeAniData)/2, d0
	move.b	d0, anim(a0)
	addi.w	#Boost_Increase, (Boost_Amount)
.ret:
	rts

Blaze_Abilities:
	tst.w	(Boost_Amount).w
	beq		.stopBoosting
	btst 	#button_A, (Ctrl_1_Held_Logical).w
	beq		.stopBoosting
	tst.b 	(IsBoosting).w
	bne		.alreadyBoosting
	cmpi.w	#Boost_Increase, (Boost_Amount).w
	blt 	.stopBoosting
	subi.w	#Boost_Increase-1, (Boost_Amount).w
	move.b	#1, (IsBoosting).w
.alreadyBoosting:
	subq.w	#1, (Boost_Amount).w
	move.w	#Blaze_BoostSpd, d0
	move.w	inertia(a0), d1
	move.w	#0, anim(a0)
	btst	#0, status(a0)
	beq		.faceRight
	neg.w	d0
	cmp.w	d0, d1
	ble		.noSpeedSet
	bra		.doneFace
.faceRight:
	cmp.w	d0, d1
	bge		.noSpeedSet
.doneFace:
	move.w	d0, inertia(a0)
.noSpeedSet:
	jsr 	RandomNumber
	move.w	d0, -(sp)
	jsr		RandomNumber
	move.w	(sp)+, d1
	andi.w	#30, d0
	andi.w	#30, d1
	subi.w	#15, d0
	subi.w	#15, d1
	add.w	x_pos(a0), d0
	add.w	y_pos(a0), d1
	bra 	Blaze_SpawnFlame
.stopBoosting:
	move.b	#0, (IsBoosting).w
.ret:
	rts

Blaze_AirAbilities:
	move.b 	anim(a0), d0
	cmpi.b	#(BlzAni_Hover_ptr-BlazeAniData)/2, d0
	beq		Blaze_HoverTick
	cmpi.b	#(BlzAni_AxelT_ptr-BlazeAniData)/2, d0
	beq		Blaze_AxelTick
	cmpi.b 	#(BlzAni_Roll_ptr-BlazeAniData)/2, d0
	blo		.ret
	cmpi.b 	#(BlzAni_Roll2_ptr-BlazeAniData)/2, d0
	bhi		.ret
	move.b	(Ctrl_1_Press_Logical).w, d0
	btst	#button_A, d0
	bne		.doAirBoost
	btst	#button_C, d0
	bne     .doHover
	btst	#button_B, d0
	bne		.doAxelT
	bra		.ret
.doAirBoost:
	cmpi.w	#Boost_Increase, (Boost_Amount).w
	blt 	.ret

	move.w	x_pos(a0), d0
	move.w	y_pos(a0), d1
	subq.w	#8, d1
	bsr 	Blaze_SpawnFlame_NoTimer
	addq.w	#8, d1
	bsr 	Blaze_SpawnFlame_NoTimer
	addq.w	#8, d1
	bsr 	Blaze_SpawnFlame_NoTimer

	subi.w	#Boost_Increase, (Boost_Amount).w
	move.w	#-60, y_vel(a0)
	move.w	#Blaze_BoostSpd, d0
	move.w	x_vel(a0), d1
	move.b	#(BlzAni_AirBoost_ptr-BlazeAniData)/2, anim(a0)
	btst	#0, status(a0)
	beq		.faceRight
	neg.w	d0
	cmp.w	d0, d1
	ble		.noSpeedSet
	bra		.doneFace
.faceRight:
	cmp.w	d0, d1
	bge		.noSpeedSet
.doneFace:
	move.w	d0, x_vel(a0)
.noSpeedSet:
	bra 	.ret
.doHover:
	move.b	#(BlzAni_Hover_ptr-BlazeAniData)/2, anim(a0)
	bra 	.ret
.doAxelT:
	move.b	#(BlzAni_AxelT_ptr-BlazeAniData)/2, anim(a0)
	move.w	#Blaze_AxelSpd, y_vel(a0)
.ret:
	rts

Blaze_HoverTick:
	btst	#button_C, (Ctrl_1_Held_Logical).w
	beq		.stopHover
	move.w	x_pos(a0), d0
	move.w	y_pos(a0), d1
	addi.w  #12, d1
	btst   #0, status(a0)
	bne	   .FaceRight
.FaceLeft:
	subi.w  #13, d0
	bra		.DoneFace
.FaceRight:
	addi.w  #13, d0
.DoneFace:
	bsr		Blaze_SpawnFlame
	cmpi.w	#Blaze_HoverSpd, y_vel(a0)
	ble		.noSpeedSet
	move.w	#Blaze_HoverSpd, y_vel(a0)
	bra		.ret
.stopHover:
	move.b	#(BlzAni_Roll_ptr-BlazeAniData)/2, anim(a0)
.noSpeedSet:
.ret:
	rts

Blaze_AxelTick:
	tst.w	y_vel(a0)
	blt	    .Rising
	move.b	#(BlzAni_Fall_ptr-BlazeAniData)/2, anim(a0)
.Rising:
	addq.b  #1, (BlzFlameTimer).w
	cmpi.b  #Blaze_FlameFreq, (BlzFlameTimer).w
	bne		.ret
	move.b  #0, (BlzFlameTimer).w
	move.w  x_pos(a0), d0
	move.w  y_pos(a0), d1
	subi.w  #10, d0
	bsr     Blaze_SpawnFlame_NoTimer
	addi.w  #20, d0
	bsr     Blaze_SpawnFlame_NoTimer
.ret:
	rts

Blaze_SpawnFlame:
	addq.b  #1, (BlzFlameTimer).w
	cmpi.b  #Blaze_FlameFreq, (BlzFlameTimer).w
	bne		Blaze_SpawnFlame_Return
	move.b  #0, (BlzFlameTimer).w
Blaze_SpawnFlame_NoTimer:
	movem.w	d0-d1,-(sp)
	bsr 	AllocateObject
	bne		Blaze_SpawnFlame_Return
	;move.b	#0, $29(a1)
	;btst    #6, obStatus(a0)
	;beq		.NotUnderwater
	;move.b	#1, $29(a1)
;.NotUnderwater:
	movem.w	(sp)+,d0-d1
	_move.b	#ObjID_BlazeFlame, id(a1)
	move.w	d0, x_pos(a1)
	move.w	d1, y_pos(a1)
	bra		Blaze_SpawnFlame_Return_NoPop
Blaze_SpawnFlame_Return:
	movem.w	(sp)+,d0-d1
Blaze_SpawnFlame_Return_NoPop:
	rts

Blaze_UpdateSpindash:
	move.b	(Ctrl_1_Held_Logical).w,d0
	btst	#button_down,d0
	bne.w	Sonic_ChargingSpindash

	; unleash the charged spindash and start rolling quickly:
	move.b	#$E,y_radius(a0)
	move.b	#7,x_radius(a0)
	move.b	#AniIDSonAni_Roll,anim(a0)
	addq.w	#5,y_pos(a0)	; add the difference between Sonic's rolling and standing heights
	move.b	#0,spindash_flag(a0)
	moveq	#0,d0
	move.b	spindash_counter(a0),d0
	add.w	d0,d0
	move.w	BlzSpindashSpeeds(pc,d0.w),inertia(a0)
	tst.b	(Super_Sonic_flag).w
	beq.s	+
	move.w	BlzSpindashSpeedsSuper(pc,d0.w),inertia(a0)
+
	; Determine how long to lag the camera for.
	; Notably, the faster Sonic goes, the less the camera lags.
	; This is seemingly to prevent Sonic from going off-screen.
	move.w	inertia(a0),d0
	subi.w	#$800,d0 ; $800 is the lowest spin dash speed
    if fixBugs
	; To fix a bug in 'ScrollHoriz', we need an extra variable, so this
	; code has been modified to make the delay value only a single byte.
	; The lower byte has been repurposed to hold a copy of the position
	; array index at the time that the spin dash was released.
	; This is used by the fixed 'ScrollHoriz'.
	lsr.w	#7,d0
	neg.w	d0
	addi.w	#$20,d0
	move.b	d0,(Horiz_scroll_delay_val_P2).w
	; Back up the position array index for later.
	move.b	(Sonic_Pos_Record_Index+1).w,(Horiz_scroll_delay_val_P2+1).w
    else
	add.w	d0,d0
	andi.w	#$1F00,d0 ; This line is not necessary, as none of the removed bits are ever set in the first place
	neg.w	d0
	addi.w	#$2000,d0
	move.w	d0,(Horiz_scroll_delay_val_P2).w
    endif

	btst	#0,status(a0)
	beq.s	+
	neg.w	inertia(a0)
+
	bset	#2,status(a0)
	move.b	#0,(Tails_Dust+anim).w
	move.w	#SndID_SpindashRelease,d0	; spindash zoom sound
	jsr	(PlaySound).l
	bra		Obj01_Spindash_ResetScr
; ===========================================================================
; word_1AD0C:
BlzSpindashSpeeds:
	dc.w  $800	; 0
	dc.w  $880	; 1
	dc.w  $900	; 2
	dc.w  $980	; 3
	dc.w  $A00	; 4
	dc.w  $A80	; 5
	dc.w  $B00	; 6
	dc.w  $B80	; 7
	dc.w  $C00	; 8
; word_1AD1E:
BlzSpindashSpeedsSuper:
	dc.w  $B00	; 0
	dc.w  $B80	; 1
	dc.w  $C00	; 2
	dc.w  $C80	; 3
	dc.w  $D00	; 4
	dc.w  $D80	; 5
	dc.w  $E00	; 6
	dc.w  $E80	; 7
	dc.w  $F00	; 8

Blaze_RecordPos:
	move.w	(Tails_Pos_Record_Index).w,d0
	lea	(Tails_Pos_Record_Buf).w,a1
	lea	(a1,d0.w),a1
	move.w	x_pos(a0),(a1)+
	move.w	y_pos(a0),(a1)+
	addq.b	#4,(Tails_Pos_Record_Index+1).w

	;lea	(Tails_Stat_Record_Buf).w,a1
	;lea	(a1,d0.w),a1
	;move.w	(Ctrl_1_Logical).w,(a1)+
	;move.w	status(a0),(a1)+

	rts

Ani_Obj62:	dc.w Ani_Obj62_Normal-Ani_Obj62
		Ani_Obj62_Normal:	dc.b 6,	$B, $C, $D, $FE, 1
		even

Obj62:
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	Obj62_Index(pc,d0.w),d1
	jmp	Obj62_Index(pc,d1.w)

Obj62_Index:	offsetTable
		offsetTableEntry.w Obj62_Init	; 0
		offsetTableEntry.w Obj62_Main	; 2

Obj62_Init:
	addq.b	#2,routine(a0)
	move.l	#HUD_MapUnc_40A9A,mappings(a0)
	move.w	#make_art_tile(ArtTile_ArtNem_HUD,0,1),art_tile(a0)
	move.b	#0,anim(a0)
	move.b	#4,render_flags(a0)
	move.b	#1,priority(a0)
	move.b	#8,width_pixels(a0)
	move.w	#-$150,y_vel(a0)	; set initial speed (upwards)

Obj62_Main:
	tst.w	y_vel(a0)		; test speed
	bpl.w	DeleteObject		; if it's positive (>= 0), delete the object
	bsr.w	ObjectMove		; move the points
	addi.w	#$10,y_vel(a0)		; slow down
	lea		(Ani_Obj62).l,a1
	bsr.w	AnimateSprite
	bra.w	DisplaySprite
