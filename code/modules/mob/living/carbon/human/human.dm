#define MASSAGE_RHYTM_RIGHT   11
#define MASSAGE_ALLOWED_ERROR 2

/mob/living/carbon/human
	name = "unknown"
	real_name = "unknown"
	voice_name = "unknown"
	icon = 'icons/mob/human.dmi'
	hud_possible = list(HEALTH_HUD, STATUS_HUD, INSURANCE_HUD, ID_HUD, WANTED_HUD, IMPLOYAL_HUD, IMPCHEM_HUD, IMPTRACK_HUD, IMPMINDS_HUD, ANTAG_HUD, HOLY_HUD, GOLEM_MASTER_HUD, BROKEN_HUD, ALIEN_EMBRYO_HUD, IMPOBED_HUD)
	w_class = SIZE_HUMAN
	//icon_state = "body_m_s"

	var/datum/species/species //Contains icon generation and language information, set during New().
	var/heart_beat = 0
	var/embedded_flag	  //To check if we've need to roll for damage on movement while an item is imbedded in us.

	var/metadata
	var/gnomed = 0 // timer used by gnomecurse.dm
	var/hulk_activator = null

	var/last_massage = 0
	var/massages_done_right = 0
	attack_push_vis_effect = ATTACK_EFFECT_PUNCH
	attack_disarm_vis_effect = ATTACK_EFFECT_DISARM
	throw_range = 2

	moveset_type = /datum/combat_moveset/human

	appearance_flags = TILE_BOUND|PIXEL_SCALE|KEEP_TOGETHER

/mob/living/carbon/human/atom_init(mapload, new_species)
	AddComponent(/datum/component/mood)

	dna = new
	hulk_activator = pick(HULK_ACTIVATION_OPTIONS) //in __DEFINES/geneticts.dm

	var/datum/reagents/R = new/datum/reagents(1000)
	reagents = R
	R.my_atom = src

	if(!species)
		if(new_species)
			set_species(new_species, FALSE, TRUE)
		else
			set_species()

	if(species) // Just to be sure.
		butcher_results = species.butcher_drops.Copy() // todo move to species on_gain/on_loose

	dna.species = species.name
	dna.b_type = random_blood_type()

	. = ..()

	AddComponent(/datum/component/footstep, FOOTSTEP_MOB_HUMAN)
	human_list += src

	RegisterSignal(src, list(COMSIG_MOB_EQUIPPED), PROC_REF(mood_item_equipped))

	if(dna)
		dna.real_name = real_name

	handcrafting = new()
	AddComponent(/datum/component/altcraft)

	prev_gender = gender // Debug for plural genders
	make_blood()

/mob/living/carbon/human/Destroy()
	human_list -= src
	if(my_master)
		var/datum/atom_hud/golem/golem_hud = global.huds[DATA_HUD_GOLEM]
		golem_hud.remove_from_hud(src)
		my_master = null
	if(my_golem)
		var/datum/atom_hud/golem/golem_hud = global.huds[DATA_HUD_GOLEM]
		golem_hud.remove_from_hud(src)
		my_golem.death()
	my_golem = null
	QDEL_LIST(bodyparts)
	QDEL_LIST(organs)
	QDEL_NULL(vessel)
	return ..()


/mob/living/carbon/human/pluvian/atom_init(mapload)
	. = ..(mapload, PLUVIAN)

/mob/living/carbon/human/pluvian_spirit
	var/mob/living/carbon/human/my_corpse
	var/list/spells_to_remember = list()

/mob/living/carbon/human/pluvian_spirit/atom_init(mapload)
	. = ..(mapload, PLUVIAN_SPIRIT)

/mob/living/carbon/human/skrell/atom_init(mapload)
	h_style = "Skrell Male Tentacles"
	. = ..(mapload, SKRELL)

/mob/living/carbon/human/tajaran/atom_init(mapload)
	h_style = "Tajaran Ears"
	. = ..(mapload, TAJARAN)

/mob/living/carbon/human/unathi/atom_init(mapload)
	h_style = "Unathi Horns"
	. = ..(mapload, UNATHI)

/mob/living/carbon/human/vox/atom_init(mapload)
	h_style = "Short Vox Quills"
	. = ..(mapload, VOX)

/mob/living/carbon/human/voxarmalis/atom_init(mapload)
	h_style = "Bald"
	. = ..(mapload, VOX_ARMALIS)

/mob/living/carbon/human/diona/atom_init(mapload)
	. = ..(mapload, DIONA)

/mob/living/carbon/human/podman/atom_init(mapload)
	. = ..(mapload, PODMAN)

/mob/living/carbon/human/machine/atom_init(mapload)
	h_style = "blue IPC screen"
	. = ..(mapload, IPC)

/mob/living/carbon/human/abductor/atom_init(mapload)
	. = ..(mapload, ABDUCTOR)

/mob/living/carbon/human/golem/atom_init(mapload)
	. = ..(mapload, GOLEM)

/mob/living/carbon/human/shadowling/atom_init(mapload)
	underwear = 0
	undershirt = 0
	. = ..(mapload, SHADOWLING)
	var/newNameId = pick(possibleShadowlingNames)
	possibleShadowlingNames.Remove(newNameId)
	real_name = newNameId
	name = real_name

	faction = "faithless"

	AddSpell(new /obj/effect/proc_holder/spell/targeted/shadowling_hivemind)
	AddSpell(new /obj/effect/proc_holder/spell/targeted/enthrall)
	AddSpell(new /obj/effect/proc_holder/spell/targeted/glare)
	AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/veil)
	AddSpell(new /obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shadow_walk)
	AddSpell(new /obj/effect/proc_holder/spell/aoe_turf/flashfreeze)
	AddSpell(new /obj/effect/proc_holder/spell/targeted/collective_mind)
	AddSpell(new /obj/effect/proc_holder/spell/targeted/shadowling_regenarmor)

	notify_ghosts("\A [src], new hatched shadowling, at [get_area(src)]!", source = src, action = NOTIFY_ORBIT, header = "Shadowling")

/mob/living/carbon/human/skeleton/atom_init(mapload)
	. = ..(mapload, pick(HUMAN, UNATHI, TAJARAN, SKRELL))

	ADD_TRAIT(src, ELEMENT_TRAIT_SKELETON, ADMIN_TRAIT)

/mob/living/carbon/human/serpentid/atom_init(mapload)
	. = ..(mapload, SERPENTID)

/mob/living/carbon/human/moth/atom_init(mapload)
	. = ..(mapload, MOTH)

/mob/living/carbon/human/prepare_data_huds()
	//Update med hud images...
	..()
	//...sec hud images...
	sec_hud_set_ID()
	sec_hud_set_implants()
	sec_hud_set_security_status()
	//...and display them.
	add_to_all_data_huds()

/mob/living/carbon/human/OpenCraftingMenu()
	handcrafting.ui_interact(src)

/mob/living/carbon/human/Stat()
	..()

	if(statpanel("Status"))
		stat(null, "Intent: [a_intent]")
		stat(null, "Move Mode: [m_intent]")
		//Info for IPC
		if(species.flags[IS_SYNTHETIC])
			var/obj/item/organ/internal/liver/IO = organs_by_name[O_LIVER]
			var/obj/item/weapon/stock_parts/cell/I = locate(/obj/item/weapon/stock_parts/cell) in IO
			if(I)
				stat(null, "Charge: [round(100.0*nutrition/I.maxcharge, 1)]%")
				stat(null, "Operating temp: [round(bodytemperature-T0C)]&deg;C")
		if(internal)
			if(!internal.air_contents)
				qdel(internal)
			else
				stat("Internal Atmosphere Info", internal.name)
				stat("Tank Pressure", internal.air_contents.return_pressure())
				stat("Distribution Pressure", internal.distribute_pressure)

		if(istype(wear_suit, /obj/item/clothing/suit/space/space_ninja))
			var/obj/item/clothing/suit/space/space_ninja/SN = wear_suit
			stat("SpiderOS Status:","[SN.s_initialized ? "Initialized" : "Disabled"]")
			stat("Current Time:", "[worldtime2text()]")
			if(SN.s_initialized)
				//Suit gear
				stat("Energy Charge", "[round(SN.cell.charge/100)]%")
				stat("Smoke Bombs:", "\Roman [SN.s_bombs]")
				//Ninja status
				stat("Fingerprints:", "[md5(dna.uni_identity)]")
				stat("Unique Identity:", "[dna.unique_enzymes]")
				stat("Overall Status:", "[stat > 1 ? "dead" : "[health]% healthy"]")
				stat("Nutrition Status:", "[nutrition]")
				stat("Oxygen Loss:", "[ceil(getOxyLoss())]")
				stat("Toxin Levels:", "[ceil(getToxLoss())]")
				stat("Burn Severity:", "[ceil(getFireLoss())]")
				stat("Brute Trauma:", "[ceil(getBruteLoss())]")
				stat("Radiation Levels:","[radiation] rad")
				stat("Body Temperature:","[bodytemperature-T0C] degrees C ([bodytemperature*1.8-459.67] degrees F)")

	if(mind)
		for(var/role in mind.antag_roles)
			var/datum/role/R = mind.antag_roles[role]
			stat(R.StatPanel())

	if(istype(wear_suit, /obj/item/clothing/suit/space/rig))
		var/obj/item/clothing/suit/space/rig/rig = wear_suit
		rig_setup_stat(rig)

/mob/living/carbon/human/ex_act(severity)
	if(!blinded)
		flash_eyes()

	var/shielded = 0
	var/b_loss = null
	var/f_loss = null
	switch (severity)
		if(EXPLODE_DEVASTATE)
			b_loss += 500
			if (!prob(getarmor(null, BOMB)))
				gib()
				return
			else
				var/atom/target = get_edge_target_turf(src, get_dir(src, get_step_away(src, src)))
				throw_at(target, 200, 4)
			//return
//				var/atom/target = get_edge_target_turf(user, get_dir(src, get_step_away(user, src)))
				//user.throw_at(target, 200, 4)

		if(EXPLODE_HEAVY)
			if (!shielded)
				b_loss += 60

			f_loss += 60

			if (prob(getarmor(null, BOMB)))
				b_loss = b_loss/1.5
				f_loss = f_loss/1.5

			if (!istype(l_ear, /obj/item/clothing/ears/earmuffs) && !istype(r_ear, /obj/item/clothing/ears/earmuffs))
				ear_damage += 30
				ear_deaf += 120
			if (prob(70) && !shielded)
				Paralyse(10)

		if(EXPLODE_LIGHT)
			b_loss += 30
			if (prob(getarmor(null, BOMB)))
				b_loss = b_loss/2
			if (!istype(l_ear, /obj/item/clothing/ears/earmuffs) && !istype(r_ear, /obj/item/clothing/ears/earmuffs))
				ear_damage += 15
				ear_deaf += 60
			if (prob(50) && !shielded)
				Paralyse(10)

	// focus most of the blast on one organ
	var/obj/item/organ/external/BP = pick(bodyparts)
	BP.take_damage(b_loss * 0.9, f_loss * 0.9, used_weapon = "Explosive blast")

	// distribute the remaining 10% on all limbs equally
	b_loss *= 0.1
	f_loss *= 0.1

	var/weapon_message = "Explosive Blast"
	take_overall_damage(b_loss * 0.2, f_loss * 0.2, used_weapon = weapon_message)

/mob/living/carbon/human/airlock_crush_act()
	..()
	emote("scream")

/mob/living/carbon/human/singularity_act()
	var/gain = 20
	if(mind)
		switch(mind.assigned_role)
			if("Station Engineer","Chief Engineer")
				gain = 100
			if("Clown")
				gain = rand(-300, 300)//HONK
	log_investigate(" has consumed [key_name(src)].",INVESTIGATE_SINGULO) //Oh that's where the clown ended up!
	gib()
	return(gain)

/mob/living/carbon/human/singularity_pull(S, current_size)
	if(current_size >= STAGE_THREE)
		var/list/handlist = list(l_hand, r_hand)
		for(var/obj/item/hand in handlist)
			if(prob(current_size * 5) && hand.w_class >= ((STAGE_FIVE-current_size)/2)  && unEquip(hand))
				step_towards(hand, src)
				to_chat(src, "<span class='warning'>\The [S] pulls \the [hand] from your grip!</span>")
	irradiate_one_mob(src, current_size * 3)
	if(mob_negates_gravity())//Magboots protection
		return
	..()

/mob/living/carbon/human/blob_act()
	if(stat == DEAD)	return
	to_chat(src, "<span class='danger'>The blob attacks you!</span>")
	var/dam_zone = pick(BP_CHEST , BP_L_ARM , BP_R_ARM , BP_L_LEG , BP_R_LEG, BP_HEAD)
	var/obj/item/organ/external/BP = bodyparts_by_name[ran_zone(dam_zone)]
	apply_damage(rand(30, 40), BRUTE, BP, run_armor_check(BP, MELEE))
	return

/mob/living/carbon/human/proc/can_use_two_hands(broken = TRUE) // Replace arms with hands in case of reverting Kurshan's PR.
	var/obj/item/organ/external/l_arm/BPL = bodyparts_by_name[BP_L_ARM]
	var/obj/item/organ/external/r_arm/BPR = bodyparts_by_name[BP_R_ARM]
	if(broken && (BPL.is_broken() || BPR.is_broken()))
		return FALSE
	if(!BPL.is_usable() || !BPR.is_usable())
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/is_type_organ(organ, o_type)
	var/obj/item/organ/O
	if(organ in organs_by_name)
		O = organs_by_name[organ]
	if(organ in bodyparts_by_name)
		O = bodyparts_by_name[organ]
	if(!O)
		return FALSE
	return istype(O, o_type)

/mob/living/carbon/human/proc/is_bruised_organ(organ)
	var/obj/item/organ/internal/IO = organs_by_name[organ]
	if(!IO)
		return TRUE
	if(IO.is_bruised())
		return TRUE
	return FALSE

/mob/living/carbon/human/proc/find_damaged_bodypart()
	for(var/obj/item/organ/external/BP in bodyparts) // find a broken/destroyed limb
		if(BP.status & (ORGAN_BROKEN | ORGAN_SPLINTED) || BP.is_stump)
			if(BP.parent && (BP.parent.is_stump))
				continue
			else
				return BP
	return FALSE // In case we didn't find anything.

/mob/living/carbon/human/proc/make_pumped()
	for(var/obj/item/organ/external/BP in bodyparts)
		if(BP.is_stump || BP.parent && (BP.parent.is_stump))
			continue

		if(!BP.max_pumped)
			continue

		BP.adjust_pumped(BP.max_pumped)

/mob/living/carbon/human/proc/regen_bodyparts(remove_blood_amount = 0, use_cost = FALSE)
	if(regenerating_bodypart) // start fixing broken/destroyed limb
		if(remove_blood_amount)
			blood_remove(remove_blood_amount)
		var/regenerating_capacity_penalty = 0 // Used as time till organ regeneration.
		if(regenerating_bodypart.is_stump)
			regenerating_capacity_penalty = regenerating_bodypart.regen_bodypart_penalty
		else
			regenerating_capacity_penalty = regenerating_bodypart.regen_bodypart_penalty/2
		regenerating_organ_time++
		switch(regenerating_organ_time)
			if(1)
				visible_message("<span class='notice'>You see odd movement in [src]'s [regenerating_bodypart.name]...</span>","<span class='notice'> You [HAS_TRAIT(src, TRAIT_NO_PAIN) ? "notice" : "feel"] strange vibration on tips of your [regenerating_bodypart.name]... </span>")
			if(10)
				visible_message("<span class='notice'>You hear sickening crunch In [src]'s [regenerating_bodypart.name]...</span>")
			if(20)
				visible_message("<span class='notice'>[src]'s [regenerating_bodypart.name] shortly bends...</span>")
			if(30)
				if(regenerating_capacity_penalty == regenerating_bodypart.regen_bodypart_penalty/2)
					visible_message("<span class='notice'>[src] stirs his [regenerating_bodypart.name]...</span>","<span class='userdanger'>You [HAS_TRAIT(src, TRAIT_NO_PAIN) ? "notice" : "feel"] freedom in moving your [regenerating_bodypart.name]</span>")
				else
					visible_message("<span class='notice'>From [src]'s [parse_zone(regenerating_bodypart.body_zone)] grows a small meaty sprout...</span>")
			if(50)
				visible_message("<span class='notice'>You see something resembling [parse_zone(regenerating_bodypart.body_zone)] at [src]'s [regenerating_bodypart.parent.name]...</span>")
			if(65)
				visible_message("<span class='userdanger'>A new [parse_zone(regenerating_bodypart.body_zone)] has grown from [src]'s [regenerating_bodypart.parent.name]!</span>","<span class='userdanger'>You [HAS_TRAIT(src, TRAIT_NO_PAIN) ? "notice" : "feel"] your [parse_zone(regenerating_bodypart.body_zone)] again!</span>")
		if(prob(50))
			emote("scream")
		if(regenerating_organ_time >= regenerating_capacity_penalty) // recover organ
			regenerating_bodypart.rejuvenate()
			regenerating_organ_time = 0
			if(use_cost)
				nutrition -= regenerating_capacity_penalty
			update_body(regenerating_bodypart.body_zone)
			regenerating_bodypart = null

/mob/living/carbon/human/restrained(check_type = ARMS)
	if ((check_type & ARMS) && handcuffed)
		return TRUE
	if ((check_type & LEGS) && legcuffed)
		return TRUE
	if (istype(wear_suit, /obj/item/clothing/suit/straight_jacket))
		return TRUE
	return 0

/mob/living/carbon/human/resist()
	..()
	if(usr && !usr.incapacitated())
		var/mob/living/carbon/human/D = usr
		if(D.get_species() == DIONA)
			var/list/choices = list()
			for(var/mob/living/carbon/monkey/diona/V in contents)
				if(istype(V) && V.gestalt == src)
					choices += V
			var/mob/living/carbon/monkey/diona/V = input(D,"Who do wish you to expel from within?") in null|choices
			if(V)
				to_chat(D, "<span class='notice'>You wriggle [V] out of your insides.</span>")
				V.splitting(D)

/mob/living/carbon/human/show_inv(mob/user)
	user.set_machine(src)
	var/has_breathable_mask = istype(wear_mask, /obj/item/clothing/mask)
	var/list/obscured = check_obscured_slots()
	var/list/dat = list()
	var/obj/item/clothing/under/suit = isunder(w_uniform) ? w_uniform : null

	dat += "<table>"
	dat += "<tr><td><B>Left Hand:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_L_HAND]'>[(l_hand && !(l_hand.flags & ABSTRACT)) ? l_hand : "<font color=grey>Empty</font>"]</a></td></tr>"
	dat += "<tr><td><B>Right Hand:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_R_HAND]'>[(r_hand && !(r_hand.flags & ABSTRACT)) ? r_hand : "<font color=grey>Empty</font>"]</a></td></tr>"
	dat += "<tr><td>&nbsp;</td></tr>"

	dat += "<tr><td><B>Back:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_BACK]'>[(back && !(back.flags & ABSTRACT)) ? back : "<font color=grey>Empty</font>"]</A>"
	if(has_breathable_mask && istype(back, /obj/item/weapon/tank))
		dat += "&nbsp;<A href='byond://?src=\ref[src];internal=[SLOT_BACK]'>[internal ? "Disable Internals" : "Set Internals"]</A>"

	dat += "</td></tr><tr><td>&nbsp;</td></tr>"

	dat += "<tr><td><B>Head:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_HEAD]'>[(head && !(head.flags & ABSTRACT)) ? head : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(SLOT_WEAR_MASK in obscured)
		dat += "<tr><td><font color=grey><B>Mask:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Mask:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_WEAR_MASK]'>[(wear_mask && !(wear_mask.flags & ABSTRACT)) ? wear_mask : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(SLOT_NECK in obscured)
		dat += "<tr><td><font color=grey><B>Neck:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Neck:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_NECK]'>[(neck && !(neck.flags & ABSTRACT)) ? neck : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(SLOT_GLASSES in obscured)
		dat += "<tr><td><font color=grey><B>Eyes:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Eyes:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_GLASSES]'>[(glasses && !(glasses.flags & ABSTRACT))	? glasses : "<font color=grey>Empty</font>"]</A></td></tr>"

	if(SLOT_EARS in obscured)
		dat += "<tr><td><font color=grey><B>Ears:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Left Ear:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_L_EAR]'>[(l_ear && !(l_ear.flags & ABSTRACT))		? l_ear		: "<font color=grey>Empty</font>"]</A></td></tr>"
		dat += "<tr><td><B>Right Ear:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_R_EAR]'>[(r_ear && !(r_ear.flags & ABSTRACT))		? r_ear		: "<font color=grey>Empty</font>"]</A></td></tr>"

	dat += "<tr><td>&nbsp;</td></tr>"

	dat += "<tr><td><B>Exosuit:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_WEAR_SUIT]'>[(wear_suit && !(wear_suit.flags & ABSTRACT)) ? wear_suit : "<font color=grey>Empty</font>"]</A></td></tr>"
	if(wear_suit)
		if(SLOT_S_STORE in obscured)
			dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Suit Storage:</B></font></td></tr>"
		else
			dat += "<tr><td>&nbsp;&#8627;<B>Suit Storage:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_S_STORE]'>[(s_store && !(s_store.flags & ABSTRACT)) ? s_store : "<font color=grey>Empty</font>"]</A>"
			if(has_breathable_mask && istype(s_store, /obj/item/weapon/tank))
				dat += "&nbsp;<A href='byond://?src=\ref[src];internal=[SLOT_S_STORE]'>[internal ? "Disable Internals" : "Set Internals"]</A>"
			dat += "</td></tr>"
	else
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Suit Storage:</B></font></td></tr>"

	if(SLOT_SHOES in obscured)
		dat += "<tr><td><font color=grey><B>Shoes:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Shoes:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_SHOES]'>[(shoes && !(shoes.flags & ABSTRACT))		? shoes		: "<font color=grey>Empty</font>"]</A></td></tr>"

	if(SLOT_GLOVES in obscured)
		dat += "<tr><td><font color=grey><B>Gloves:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Gloves:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_GLOVES]'>[(gloves && !(gloves.flags & ABSTRACT))		? gloves	: "<font color=grey>Empty</font>"]</A></td></tr>"

	if(SLOT_W_UNIFORM in obscured)
		dat += "<tr><td><font color=grey><B>Uniform:</B></font></td><td><font color=grey>Obscured</font></td></tr>"
	else
		dat += "<tr><td><B>Uniform:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_W_UNIFORM]'>[(w_uniform && !(w_uniform.flags & ABSTRACT)) ? w_uniform : "<font color=grey>Empty</font>"]</A>[(suit && suit.has_sensor == 1) ? " <A href='byond://?src=\ref[src];sensor=1'>Sensors</A>" : ""]</td></tr>"

	if(w_uniform == null || (SLOT_W_UNIFORM in obscured))
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Pockets:</B></font></td></tr>"
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>ID:</B></font></td></tr>"
		dat += "<tr><td><font color=grey>&nbsp;&#8627;<B>Belt:</B></font></td></tr>"
	else
		dat += "<tr><td>&nbsp;&#8627;<B>Belt:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_BELT]'>[(belt && !(belt.flags & ABSTRACT)) ? belt : "<font color=grey>Empty</font>"]</A>"
		if(has_breathable_mask && istype(belt, /obj/item/weapon/tank))
			dat += "&nbsp;<A href='byond://?src=\ref[src];internal=[SLOT_BELT]'>[internal ? "Disable Internals" : "Set Internals"]</A>"
		dat += "</td></tr>"
		dat += "<tr><td>&nbsp;&#8627;<B>Pockets:</B></td><td><A href='byond://?src=\ref[src];pockets=left'>[(l_store && !(l_store.flags & ABSTRACT)) ? "Left (Full)" : "<font color=grey>Left (Empty)</font>"]</A>"
		dat += "&nbsp;<A href='byond://?src=\ref[src];pockets=right'>[(r_store && !(r_store.flags & ABSTRACT)) ? "Right (Full)" : "<font color=grey>Right (Empty)</font>"]</A></td></tr>"
		dat += "<tr><td>&nbsp;&#8627;<B>ID:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_WEAR_ID]'>[(wear_id && !(wear_id.flags & ABSTRACT)) ? wear_id : "<font color=grey>Empty</font>"]</A></td></tr>"
		if(suit)
			for(var/obj/item/I in suit.accessories)
				dat += "<tr><td>&nbsp;&#8627;<B>[I.name]:</B></td><td><A href='byond://?src=\ref[src];accessory=\ref[I];suit_accessory=\ref[suit]'>Remove Accessory</A></td></tr>"

	if(handcuffed)
		dat += "<tr><td><B>Handcuffed:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_HANDCUFFED]'>Remove</A></td></tr>"
	if(legcuffed)
		dat += "<tr><td><B>Legcuffed:</B></td><td><A href='byond://?src=\ref[src];item=[SLOT_LEGCUFFED]'>Remove</A></td></tr>"

	dat += "<tr><td><B>Bandages:</B></td><td><A href='byond://?src=\ref[src];bandages=1'>Remove</A></td></tr>"
	dat += "<tr><td><B>Splints:</B></td><td><A href='byond://?src=\ref[src];splints=1'>Remove</A></td></tr>"

	dat += "</table>"

	var/datum/browser/popup = new(user, "mob\ref[src]", "[src]", 440, 640)
	popup.set_content(dat.Join())
	popup.open()

// called when something steps onto a human
// this could be made more general, but for now just handle mulebot
/mob/living/carbon/human/Crossed(atom/movable/AM)
	var/obj/machinery/bot/mulebot/MB = AM
	if(istype(MB))
		MB.RunOver(src)
	SpreadFire(AM)
	. = ..()

// Get rank from ID, ID inside PDA, PDA, ID in wallet, etc.
/mob/living/carbon/human/proc/get_authentification_rank(if_no_id = "No id", if_no_job = "No job")
	var/obj/item/device/pda/pda = wear_id
	if (istype(pda))
		if (pda.id)
			return pda.id.rank
		else
			return pda.ownrank
	else
		var/obj/item/weapon/card/id/id = get_idcard()
		if(id)
			return id.rank ? id.rank : if_no_job
		else
			return if_no_id

//gets assignment from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_assignment(if_no_id = "No id", if_no_job = "No job")
	var/obj/item/device/pda/pda = wear_id
	var/obj/item/weapon/card/id/id = wear_id
	if (istype(pda))
		if (pda.id && istype(pda.id, /obj/item/weapon/card/id))
			. = pda.id.assignment
		else
			. = pda.ownjob
	else if (istype(id))
		. = id.assignment
	else
		return if_no_id
	if (!.)
		. = if_no_job
	return

//gets name from ID or ID inside PDA or PDA itself
//Useful when player do something with computers
/mob/living/carbon/human/proc/get_authentification_name(if_no_id = "Unknown")
	var/obj/item/device/pda/pda = wear_id
	var/obj/item/weapon/card/id/id = wear_id
	if (istype(pda))
		if (pda.id)
			. = pda.id.registered_name
		else
			. = pda.owner
	else if (istype(id))
		. = id.registered_name
	else
		return if_no_id
	return

//repurposed proc. Now it combines get_id_name() and get_face_name() to determine a mob's name variable. Made into a seperate proc as it'll be useful elsewhere
/mob/living/carbon/human/proc/get_visible_name(face_name_priority = FALSE)
	if( wear_mask && (wear_mask.flags_inv&HIDEFACE) )	//Wearing a mask which hides our face, use id-name if possible
		return get_id_name("Unknown")
	if( head && (head.flags_inv&HIDEFACE) )
		return get_id_name("Unknown")		//Likewise for hats
	if(name_override)
		return name_override
	var/face_name = get_face_name()
	var/id_name = get_id_name("")
	if(id_name && (id_name != face_name) && !face_name_priority)
		return "[face_name] (as [id_name])"
	return face_name

//Returns "Unknown" if facially disfigured and real_name if not. Useful for setting name when polyacided or when updating a human's name variable
/mob/living/carbon/human/proc/get_face_name()
	if(!real_name || is_disfigured())
		return "Unknown"

	return real_name

/mob/living/carbon/human/proc/is_disfigured()
	if(!bodyparts_by_name[BP_HEAD])
		return TRUE

	if(HAS_TRAIT(src, TRAIT_HUSK) || HAS_TRAIT(src, TRAIT_BURNT))
		return TRUE

	if(istype(bodyparts_by_name[BP_HEAD], /obj/item/organ/external/head))
		var/obj/item/organ/external/head/BP = bodyparts_by_name[BP_HEAD]
		if(!BP || BP.disfigured || BP.is_stump)
			return TRUE

	return FALSE

//gets name from ID or PDA itself, ID inside PDA doesn't matter
//Useful when player is being seen by other mobs
/mob/living/carbon/human/proc/get_id_name(if_no_id = "Unknown")
	. = if_no_id
	if(istype(wear_id,/obj/item/device/pda))
		var/obj/item/device/pda/P = wear_id
		return P.owner
	if(wear_id)
		var/obj/item/weapon/card/id/I = wear_id.GetID()
		if(I)
			return I.registered_name
	return

//gets ID card object from special clothes slot or null.
/mob/living/carbon/human/proc/get_idcard()
	if(wear_id)
		return wear_id.GetID()

//Removed the horrible safety parameter. It was only being used by ninja code anyways.
//Now checks siemens_coefficient of the affected area by default
/mob/living/carbon/human/electrocute_act(shock_damage, obj/source, siemens_coeff = 1.0, def_zone = null, tesla_shock = 0)
	SEND_SIGNAL(src, COMSIG_ATOM_ELECTROCUTE_ACT, shock_damage, source, siemens_coeff, def_zone, tesla_shock)
	if(HAS_TRAIT(src, TRAIT_SHOCK_IMMUNE))
		return 0

	if((HULK in mutations) && hulk_activator == ACTIVATOR_ELECTRIC_SHOCK) //for check to transformation Hulk.
		to_chat(src, "<span class='notice'>You feel pain, but you like it!</span>")
		try_mutate_to_hulk()

	if(tesla_shock)
		var/total_coeff = 1
		if(gloves)
			var/obj/item/clothing/gloves/G = gloves
			if(G.siemens_coefficient <= 0)
				total_coeff -= 0.5
		if(wear_suit)
			var/obj/item/clothing/suit/S = wear_suit
			if(S.siemens_coefficient <= 0)
				total_coeff -= 0.95
		siemens_coeff = total_coeff
	else if(def_zone)
		var/obj/item/organ/external/BP = get_bodypart(check_zone(def_zone))
		siemens_coeff *= get_siemens_coefficient_organ(BP)
	if(species)
		siemens_coeff *= species.siemens_coefficient

	. = ..(shock_damage, source, siemens_coeff, def_zone, tesla_shock)
	if(.)
		if(species && species.flags[IS_SYNTHETIC])
			nutrition += . // Electrocute act returns it's shock_damage value.
		if(HAS_TRAIT(src, TRAIT_NO_PAIN)) // Because for all intents and purposes, if the mob feels no pain, he was not shocked.
			. = 0
		electrocution_animation(4 SECONDS)

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["skill"])
		update_skills(href_list)
	if(href_list["set_max_skills"])
		mind.skills.maximize_active_skills()
		to_chat(usr, "<span class='notice'>You are trying your best now.</span>")
	if(href_list["help_other"])
		var/mob/target = locate(href_list["help_other"])
		help_other(target)
	if(href_list["request_help"])
		ask_for_help()
	if (href_list["item"])
		var/slot = text2num(href_list["item"])
		if(slot in check_obscured_slots())
			to_chat(usr, "<span class='warning'>You can't reach that! Something is covering it.</span>")
			return

	if(href_list["pockets"] && usr.CanUseTopicInventory(src))
		var/pocket_side = href_list["pockets"]
		var/pocket_id = (pocket_side == "right" ? SLOT_R_STORE : SLOT_L_STORE)
		var/obj/item/pocket_item = (pocket_id == SLOT_R_STORE ? r_store : l_store)
		var/obj/item/place_item = usr.get_active_hand() // Item to place in the pocket, if it's empty

		var/delay_denominator = 1
		if(pocket_item && !(pocket_item.flags & (ABSTRACT | DROPDEL)))
			if((pocket_item.flags & NODROP) || !pocket_item.canremove)
				to_chat(usr, "<span class='warning'>You try to empty [src]'s [pocket_side] pocket, it seems to be stuck!</span>")
			to_chat(usr, "<span class='notice'>You try to empty [src]'s [pocket_side] pocket.</span>")
		else if(place_item && place_item.mob_can_equip(src, pocket_id) && !(place_item.flags & (ABSTRACT | DROPDEL)))
			to_chat(usr, "<span class='notice'>You try to place [place_item] into [src]'s [pocket_side] pocket.</span>")
			delay_denominator = 4
		else
			return

		if(do_mob(usr, src, HUMAN_STRIP_DELAY/delay_denominator)) //placing an item into the pocket is 4 times faster
			if(pocket_item)
				if(pocket_item == (pocket_id == SLOT_R_STORE ? r_store : l_store)) //item still in the pocket we search
					remove_from_mob(pocket_item)
					attack_log += text("\[[time_stamp()]\] <font color='orange'>Has had their [pocket_item] ([slot_id_to_name(pocket_id)]) removed by [usr.name] ([usr.ckey])</font>")
					usr.attack_log += text("\[[time_stamp()]\] <font color='red'>Removed [name]'s ([ckey]) [pocket_item] ([slot_id_to_name(pocket_id)])</font>")
			else
				if(place_item)
					if(place_item.mob_can_equip(src, pocket_id))
						usr.remove_from_mob(place_item)
						equip_to_slot_if_possible(place_item, pocket_id)
						attack_log += text("\[[time_stamp()]\] <font color='orange'>[usr.name] ([usr.ckey]) placed on our [slot_id_to_name(pocket_id)] ([place_item])</font>")
						usr.attack_log += text("\[[time_stamp()]\] <font color='red'>Placed on [name]'s ([ckey]) [slot_id_to_name(pocket_id)] ([place_item])</font>")
					//do nothing otherwise
		else
			// Display a warning if the user mocks up
			to_chat(src, "<span class='warning'>You feel your [pocket_side] pocket being fumbled with!</span>")

		if(usr.machine == src && Adjacent(usr))
			show_inv(usr)

	if (href_list["bandages"] && usr.CanUseTopicInventory(src))
		remove_bandages()

	if (href_list["splints"] && usr.CanUseTopicInventory(src))
		var/list/splints

		for(var/bodypart_name in list(BP_L_LEG , BP_R_LEG , BP_L_ARM , BP_R_ARM))
			var/obj/item/organ/external/BP = bodyparts_by_name[bodypart_name]
			if(BP && BP.status & ORGAN_SPLINTED)
				LAZYADD(splints, BP)

		if(splints)
			visible_message("<span class='danger'>[usr] is trying to remove [src]'s splints!</span>")
			if(do_mob(usr, src, HUMAN_STRIP_DELAY))
				for(var/obj/item/organ/external/BP in splints)
					if (BP.status & ORGAN_SPLINTED)
						var/obj/item/W = new /obj/item/stack/medical/splint(loc, 1)
						BP.status &= ~ORGAN_SPLINTED
						W.add_fingerprint(usr)
				attack_log += "\[[time_stamp()]\] <font color='orange'>Had their splints removed by [usr.name] ([usr.ckey]).</font>"
				usr.attack_log += "\[[time_stamp()]\] <font color='red'>Removed [name]'s ([ckey]) splints.</font>"

	if (href_list["sensor"] && usr.CanUseTopicInventory(src))
		if(isunder(w_uniform))
			var/obj/item/clothing/under/S = w_uniform
			visible_message("<span class='danger'>[usr] is trying to set [src]'s suit sensors!</span>")
			if(do_mob(usr, src, HUMAN_STRIP_DELAY))
				if(S.has_sensor >= 2)
					to_chat(usr, "<span class='notice'>The controls are locked.</span>")
				else
					S.set_sensors(usr)
					attack_log += text("\[[time_stamp()]\] <font color='orange'>Had their sensors toggled by [usr.name] ([usr.ckey]) mode=([S.sensor_mode]).</font>")
					usr.attack_log += text("\[[time_stamp()]\] <font color='red'>Toggled [name]'s ([ckey]) sensors mode=([S.sensor_mode]).</font>")

	if (href_list["accessory"] && href_list["suit_accessory"] && usr.CanUseTopicInventory(src))
		var/obj/item/clothing/accessory/A = locate(href_list["accessory"])
		var/obj/item/clothing/under/S = locate(href_list["suit_accessory"])
		if(istype(A) && istype(S) && (A in S.accessories))
			var/strip_time = HUMAN_STRIP_DELAY
			if(istype(A, /obj/item/clothing/accessory/holobadge) || istype(A, /obj/item/clothing/accessory/medal))
				strip_time = 5
			visible_message("<span class='danger'>[usr] is trying to take off \a [A] from [src]'s [w_uniform]!</span>")
			if(do_mob(usr, src, strip_time) && (A in S.accessories))
				if(strip_time == 5)
					visible_message("<span class='danger'>[usr] tears off \the [A] from [src]'s [S]!</span>")
				else
					visible_message("<span class='danger'>[usr] removed \the [A] from [src]'s [S]!</span>")

				S.remove_accessory(usr, A)

				attack_log += "\[[time_stamp()]\] <font color='orange'>Had their accessory ([A]) removed by [usr.name] ([usr.ckey])</font>"
				usr.attack_log += "\[[time_stamp()]\] <font color='red'>Attempted to remove [name]'s ([ckey]) accessory ([A])</font>"

	if (href_list["criminal"])
		if(hasHUD(usr,"security"))
			var/perpname = get_visible_name(TRUE)
			change_criminal_status(usr, usr, perpname)

	if (href_list["secrecord"])
		if(hasHUD(usr,"security"))
			var/read = FALSE
			var/record_id = find_record_by_name(usr, get_visible_name(TRUE))
			var/datum/data/record/R = find_security_record("id", record_id)
			if(R)
				to_chat(usr, "<b>Name:</b> [R.fields["name"]]	<b>Criminal Status:</b> [R.fields["criminal"]]")
				to_chat(usr, "<b>Minor Crimes:</b> [R.fields["mi_crim"]]")
				to_chat(usr, "<b>Details:</b> [R.fields["mi_crim_d"]]")
				to_chat(usr, "<b>Major Crimes:</b> [R.fields["ma_crim"]]")
				to_chat(usr, "<b>Details:</b> [R.fields["ma_crim_d"]]")
				to_chat(usr, "<b>Notes:</b> [R.fields["notes"]]")
				to_chat(usr, "<a href='byond://?src=\ref[src];secrecordComment=`'>\[View Comment Log\]</a>")
				read = TRUE
			if(!read)
				to_chat(usr, "<span class='warning'>Человек с таким именем не найден в базе данных.</span>")

	if (href_list["secrecordComment"])
		if(hasHUD(usr,"security"))
			var/read = FALSE
			var/record_id = find_record_by_name(usr, get_visible_name(TRUE))
			var/datum/data/record/R = find_security_record("id", record_id)
			if(R)
				var/counter = 1
				while(R.fields[text("com_[]", counter)])
					to_chat(usr, text("[]", R.fields[text("com_[]", counter)]))
					counter++
				if (counter == 1)
					to_chat(usr, "No comment found")
				to_chat(usr, "<a href='byond://?src=\ref[src];secrecordadd=`'>\[Add comment\]</a>")
				read = TRUE
			if(!read)
				to_chat(usr, "<span class='warning'>Человек с таким именем не найден в базе данных.</span>")

	if (href_list["secrecordadd"])
		if(hasHUD(usr,"security"))
			var/read = FALSE
			var/record_id = find_record_by_name(usr, get_visible_name(TRUE))
			var/datum/data/record/R = find_security_record("id", record_id)
			if(R)
				var/t1 = sanitize(input("Add Comment:", "Sec. records", null, null)  as message)
				if( !(t1) || usr.incapacitated() || !(hasHUD(usr,"security")) )
					return
				add_record(usr, R, t1)
				read = TRUE
			if(!read)
				to_chat(usr, "<span class='warning'>Человек с таким именем не найден в базе данных.</span>")

	if (href_list["medical"])
		if(hasHUD(usr,"medical"))
			var/perpname = get_visible_name(TRUE)
			var/modified = 0
			for (var/datum/data/record/E in data_core.general)
				if (E.fields["name"] == perpname)
					for (var/datum/data/record/R in data_core.general)
						if (R.fields["id"] == E.fields["id"])

							var/setmedical = input(usr, "Укажите новый медицинский статус для этого человека.", "Medical HUD", R.fields["p_stat"]) in list("*SSD*", "*Deceased*", "Physically Unfit", "Active", "Disabled", "Cancel")

							if(hasHUD(usr,"medical"))
								if(setmedical != "Cancel")
									R.fields["p_stat"] = setmedical
									modified = 1
									PDA_Manifest.Cut()

									spawn()
										if(ishuman(usr))
											var/mob/living/carbon/human/U = usr
											U.handle_regular_hud_updates()
										if(isrobot(usr))
											var/mob/living/silicon/robot/U = usr
											U.handle_regular_hud_updates()

			if(!modified)
				to_chat(usr, "<span class='warning'>Человек с таким именем не найден в базе данных.</span>")

	if (href_list["medrecord"])
		if(hasHUD(usr,"medical"))
			var/perpname = get_visible_name(TRUE)
			var/read = 0
			for (var/datum/data/record/E in data_core.general)
				if (E.fields["name"] == perpname)
					for (var/datum/data/record/R in data_core.medical)
						if (R.fields["id"] == E.fields["id"])
							if(hasHUD(usr,"medical"))
								to_chat(usr, "<b>Name:</b> [R.fields["name"]]	<b>Blood Type:</b> [R.fields["b_type"]]")
								to_chat(usr, "<b>DNA:</b> [R.fields["b_dna"]]")
								to_chat(usr, "<b>Minor Disabilities:</b> [R.fields["mi_dis"]]")
								to_chat(usr, "<b>Details:</b> [R.fields["mi_dis_d"]]")
								to_chat(usr, "<b>Major Disabilities:</b> [R.fields["ma_dis"]]")
								to_chat(usr, "<b>Details:</b> [R.fields["ma_dis_d"]]")
								to_chat(usr, "<b>Notes:</b> [R.fields["notes"]]")
								to_chat(usr, "<a href='byond://?src=\ref[src];medrecordComment=`'>\[View Comment Log\]</a>")
								read = 1

			if(!read)
				to_chat(usr, "<span class='warning'>Человек с таким именем не найден в базе данных.</span>")

	if (href_list["medrecordComment"])
		if(hasHUD(usr,"medical"))
			var/perpname = get_visible_name(TRUE)
			var/read = 0
			for (var/datum/data/record/E in data_core.general)
				if (E.fields["name"] == perpname)
					for (var/datum/data/record/R in data_core.medical)
						if (R.fields["id"] == E.fields["id"])
							if(hasHUD(usr,"medical"))
								read = 1
								var/counter = 1
								while(R.fields[text("com_[]", counter)])
									to_chat(usr, text("[]", R.fields[text("com_[]", counter)]))
									counter++
								if (counter == 1)
									to_chat(usr, "No comment found")
								to_chat(usr, "<a href='byond://?src=\ref[src];medrecordadd=`'>\[Add comment\]</a>")

			if(!read)
				to_chat(usr, "<span class='warning'>Человек с таким именем не найден в базе данных.</span>")

	if (href_list["medrecordadd"])
		if(hasHUD(usr,"medical"))
			var/perpname = get_visible_name(TRUE)
			for (var/datum/data/record/E in data_core.general)
				if (E.fields["name"] == perpname)
					for (var/datum/data/record/R in data_core.medical)
						if (R.fields["id"] == E.fields["id"])
							if(hasHUD(usr,"medical"))
								var/t1 = sanitize(input("Add Comment:", "Med. records", null, null)  as message)
								if ( !(t1) || usr.incapacitated() || !(hasHUD(usr,"medical")) )
									return
								var/counter = 1
								while(R.fields[text("com_[]", counter)])
									counter++
								if(ishuman(usr))
									var/mob/living/carbon/human/U = usr
									R.fields[text("com_[counter]")] = text("Made by [U.get_authentification_name()] ([U.get_assignment()]) on [worldtime2text()], [time2text(world.realtime, "DD/MM")]/[game_year]<BR>[t1]")
								if(isrobot(usr))
									var/mob/living/silicon/robot/U = usr
									R.fields[text("com_[counter]")] = text("Made by [U.name] ([U.modtype] [U.braintype]) on [worldtime2text()], [time2text(world.realtime, "DD/MM")]/[game_year]<BR>[t1]")

	if (href_list["lookitem"])
		var/obj/item/I = locate(href_list["lookitem"])
		usr.examinate(I)

	if (href_list["lookmob"])
		var/mob/M = locate(href_list["lookmob"])
		usr.examinate(M)
	..()
	return


///eyecheck()
/mob/living/carbon/human/eyecheck()
	if(blinded)
		return FLASHES_FULL_PROTECTION
	var/protection = 0
	for(var/obj/item/I in get_all_slots())
		if(I.slot_equipped in I.flash_protection_slots)
			protection += I.flash_protection
	return protection

/mob/living/carbon/human/IsAdvancedToolUser()
	return 1//Humans can use guns and such


/mob/living/carbon/human/abiotic(full_body = 0)
	if(full_body && ((l_hand && !(l_hand.flags & ABSTRACT)) || (r_hand && !(r_hand.flags & ABSTRACT)) || (back || wear_mask || head || shoes || w_uniform || wear_suit || glasses || l_ear || r_ear || gloves)))
		return TRUE

	if((l_hand && !(l_hand.flags & ABSTRACT)) || (r_hand && !(r_hand.flags & ABSTRACT)))
		return TRUE

	return FALSE


/mob/living/carbon/human/proc/check_dna()
	dna.check_integrity(src)
	return

/mob/living/carbon/human/get_species()
	return species.name

/mob/living/carbon/human/proc/play_xylophone()
	if(!src.xylophone)
		visible_message("<span class='warning'>[src] begins playing his ribcage like a xylophone. It's quite spooky.</span>","<span class='notice'>You begin to play a spooky refrain on your ribcage.</span>","<span class='warning'>You hear a spooky xylophone melody.</span>")
		var/song = pick('sound/effects/xylophone1.ogg','sound/effects/xylophone2.ogg','sound/effects/xylophone3.ogg')
		playsound(src, song, VOL_EFFECTS_INSTRUMENT)
		xylophone = 1
		spawn(1200)
			xylophone=0
	return

/mob/living/carbon/human/vomit(punched = FALSE, masked = FALSE, vomit_type = DEFAULT_VOMIT, stun = TRUE, force = FALSE)
	var/mask_ = masked
	if(HAS_TRAIT(src, TRAIT_NO_VOMIT))
		return FALSE

	if(wear_mask && (wear_mask.flags & MASKCOVERSMOUTH))
		mask_ = TRUE

	return ..(punched, mask_, vomit_type, stun, force)


/mob/living/carbon/human/proc/force_vomit(mob/living/carbon/human/H)
	if(H.species.flags[IS_SYNTHETIC])
		to_chat(src, "<span class='warning'>Wait... Where is the mouth?</span>")
		return

	if((H.head && (H.head.flags & HEADCOVERSMOUTH)) || (H.wear_mask && (H.wear_mask.flags & MASKCOVERSMOUTH)))
		to_chat(src, "<span class='warning'>You can't slide your fingers through THAT...</span>")
		return

	if(src != H)
		visible_message("<span class='notice'>[src] is sliding \his fingers into [H]'s mouth.</span>", "<span class='notice'>You are sliding your fingers into [H]'s mouth.</span>")
		shoving_fingers = TRUE
		if(is_busy() || !do_after(src, 3 SECONDS, target = H))
			return
		if(!shoving_fingers)
			return

	if(src != H)
		visible_message("<span class='warning'>[src] put \his fingers into [H]'s mouth and begins to press on.</span>", "<span class='notice'>You put your fingers into [H]'s mouth and begin to press on.</span>")
	else
		visible_message("<span class='warning'>[src] put \his fingers into \his own mouth.</span>", "<span class='notice'>You put your fingers into your own mouth.</span>")
		shoving_fingers = TRUE

	if(HAS_TRAIT(src, TRAIT_NO_VOMIT))
		shoving_fingers = FALSE
		return

	var/stage = 0

	for(var/i in 1 to 10)
		if(!shoving_fingers) // They bit us or something.
			return
		if(!is_busy() && do_after(src, 7, target = H))
			if(stage < 3)
				if(prob(30))
					switch(stage)
						if(0)
							to_chat(H, "<span class='notice'>You feel nauseous.</span>")
						if(1)
							to_chat(H, "<span class='warning'>Your stomach feels uneasy.</span>")
						if(2)
							to_chat(H, "<span class='warning'>You feel something coming up your throat!</span>")
					stage++
			else
				if(!prob((reagents.total_volume * 9) + 10))
					H.visible_message("<span class='warning'>[H] convulses in place, gagging!</span>", "<span class='warning'>You try to throw up, but it gets stuck in your throat!</span>")
					H.adjustOxyLoss(3)
					H.adjustHalLoss(5)
					return FALSE
				H.vomit()
		else
			break

	shoving_fingers = FALSE

/mob/living/carbon/human/proc/invoke_vomit_async()
	set waitfor = FALSE

	if(HAS_TRAIT(src, TRAIT_NO_VOMIT))
		return // Machines, golems, shadowlings, skeletons, dionaea and abductors don't throw up.

	if(!lastpuke)
		lastpuke = TRUE
		visible_message("<B>[src]</B> looks kinda like unhealthy.","<span class='warning'>You feel nauseous...</span>")
		sleep(15 SECONDS) //15 seconds until second warning
		to_chat(src, "<span class='warning'>You feel like you are about to throw up!</span>")
		sleep(10 SECONDS) //and you have 10 more for mad dash to the bucket
		vomit()
		sleep(35 SECONDS) //wait 35 seconds before next volley
		lastpuke = FALSE

/mob/living/carbon/human/proc/morph()
	set name = "Morph"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(MORPH in mutations))
		src.verbs -= /mob/living/carbon/human/proc/morph
		return

	var/new_facial = input("Please select facial hair color.", "Character Generation",rgb(r_facial,g_facial,b_facial)) as color
	if(new_facial)
		r_facial = HEX_VAL_RED(new_facial)
		g_facial = HEX_VAL_GREEN(new_facial)
		b_facial = HEX_VAL_BLUE(new_facial)

	var/new_hair = input("Please select hair color.", "Character Generation",rgb(r_hair,g_hair,b_hair)) as color
	if(new_facial)
		r_hair = HEX_VAL_RED(new_hair)
		g_hair = HEX_VAL_GREEN(new_hair)
		b_hair = HEX_VAL_BLUE(new_hair)

	var/new_eyes = input("Please select eye color.", "Character Generation",rgb(r_eyes,g_eyes,b_eyes)) as color
	if(new_eyes)
		r_eyes = HEX_VAL_RED(new_eyes)
		g_eyes = HEX_VAL_GREEN(new_eyes)
		b_eyes = HEX_VAL_BLUE(new_eyes)

	var/new_tone = input("Выберите цвет кожи", "Character Preference") in global.skin_tones_by_ru_name
	var/datum/skin_tone/T = global.skin_tones_by_ru_name[new_tone]
	s_tone = T.name

	// hair
	var/list/all_hairs = subtypesof(/datum/sprite_accessory/hair)
	var/list/hairs = list()

	// loop through potential hairs
	for(var/x in all_hairs)
		var/datum/sprite_accessory/hair/H = new x // create new hair datum based on type x
		hairs.Add(H.name) // add hair name to hairs
		qdel(H) // delete the hair after it's all done

	var/new_style = input("Please select hair style", "Character Generation",h_style)  as null|anything in hairs

	// if new style selected (not cancel)
	if (new_style)
		h_style = new_style

	// facial hair
	var/list/all_fhairs = subtypesof(/datum/sprite_accessory/facial_hair)
	var/list/fhairs = list()

	for(var/x in all_fhairs)
		var/datum/sprite_accessory/facial_hair/H = new x
		fhairs.Add(H.name)
		qdel(H)

	new_style = input("Please select facial style", "Character Generation",f_style)  as null|anything in fhairs

	if(new_style)
		f_style = new_style

	var/new_gender = tgui_alert(usr, "Please select gender.", "Character Generation", list("Male", "Female"))
	if (new_gender)
		if(new_gender == "Male")
			gender = MALE
		else
			gender = FEMALE
	regenerate_icons(update_body_preferences = TRUE)
	check_dna()

	visible_message("<span class='notice'>\The [src] morphs and changes [get_visible_gender() == MALE ? "his" : get_visible_gender() == FEMALE ? "her" : "their"] appearance!</span>", "<span class='notice'>You change your appearance!</span>", "<span class='warning'>Oh, god!  What the hell was that?  It sounded like flesh getting squished and bone ground into a different shape!</span>")

/mob/living/carbon/human/proc/remotesay() //#Z2
	set name = "Project mind"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		reset_view(0)
		remoteview_target = null
		return

	if(!(REMOTE_TALK in src.mutations))
		src.verbs -= /mob/living/carbon/human/proc/remotesay
		return

	var/list/names = list()
	var/list/creatures = list()
	var/list/namecounts = list()

	var/turf/src_turf = get_turf(src)
	if(!src_turf)
		return

	for(var/mob/living/carbon/M as anything in carbon_list)
		var/name = M.real_name
		if(name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		var/turf/temp_turf = get_turf(M)
		if(!temp_turf || temp_turf.z != src_turf.z)
			continue
		creatures[name] += M

	var/mob/target = input ("Who do you want to project your mind to ?") as null|anything in creatures
	if(isnull(target))
		return

	var/say = sanitize(input("What do you wish to say"))
	if(!say)
		return
	var/mob/T = creatures[target]
	if(REMOTE_TALK in T.mutations)
		to_chat(T, "<span class='notice'>You hear [src.real_name]'s voice: [say]</span>")
	else
		to_chat(T, "<span class='notice'>You hear a voice that seems to echo around the room: [say]</span>")
	to_chat(usr, "<span class='notice'>You project your mind into [T.real_name]: [say]</span>")
	to_chat(observer_list, "<i>Telepathic message from <b>[src]</b> to <b>[T]</b>: [say]</i>")
	log_say("Telepathic message from [key_name(src)] to [key_name(T)]: [say]")

/mob/living/carbon/human/proc/remoteobserve()
	set name = "Remote View"
	set category = "Superpower"

	if(stat!=CONSCIOUS)
		remoteview_target = null
		reset_view(0)
		return

	if(!(REMOTE_VIEW in src.mutations))
		remoteview_target = null
		reset_view(0)
		src.verbs -= /mob/living/carbon/human/proc/remoteobserve
		return

	if(client.eye != client.mob)
		remoteview_target = null
		reset_view(0)
		return

	if(getBrainLoss() >= 100) //#Z2
		to_chat(src, "Too hard to concentrate... Better stop trying!")
		adjustBrainLoss(7)
		if(getBrainLoss() >= 125) return

	var/list/names = list()
	var/list/creatures = list()
	var/list/namecounts = list()
	var/count = 0
	var/target = null	   //Chosen target.

	for(var/mob/living/carbon/human/M as anything in human_list) //#Z2 only carbon/human for now
		var/name = M.real_name
		if(!(REMOTE_TALK in src.mutations))
			count++
			name = "([count])"
		else
			if(name in names)
				namecounts[name]++
				name = "[name] ([namecounts[name]])"
			else
				names.Add(name)
				namecounts[name] = 1
		var/turf/temp_turf = get_turf(M)
		if(!temp_turf)
			continue
		if((!is_station_level(temp_turf.z) && !is_mining_level(temp_turf.z) || temp_turf.z != src.z) || M.stat!=CONSCIOUS) //Not on mining or the station. Or dead #Z2 + target on the same Z level as player
			continue
		creatures[name] += M

	target = input ("Who do you want to project your mind to ?") as null|anything in creatures

	if (!target)//Make sure we actually have a target
		return
	if(getBrainLoss() >= 100)
		to_chat(src, "Too hard to concentrate...")
		return
	if (target && (creatures[target] != src))
		adjustBrainLoss(4)
		remoteview_target = creatures[target]
		reset_view(creatures[target])
	else
		remoteview_target = null
		reset_view(0) //##Z2

/mob/living/carbon/human/proc/get_visible_gender()
	if(wear_suit && wear_suit.flags_inv & HIDEJUMPSUIT && ((head && head.flags_inv & HIDEMASK) || wear_mask))
		return NEUTER
	return gender

/mob/living/carbon/human/proc/increase_germ_level(n)
	if(gloves)
		gloves.germ_level += n
	else
		germ_level += n

/mob/living/carbon/human/proc/is_lung_ruptured()
	var/obj/item/organ/internal/lungs/IO = organs_by_name[O_LUNGS]
	return IO.is_bruised()

/mob/living/carbon/human/proc/rupture_lung()
	var/obj/item/organ/internal/lungs/IO = organs_by_name[O_LUNGS]

	if(!IO.is_bruised())
		custom_pain("You feel a stabbing pain in your chest!", 1)
		IO.damage = IO.min_bruised_damage

/*
/mob/living/carbon/human/verb/simulate()
	set name = "sim"
	//set background = 1

	var/damage = input("Wound damage","Wound damage") as num

	var/germs = 0
	var/tdamage = 0
	var/ticks = 0
	while (germs < 2501 && ticks < 100000 && round(damage/10)*20)
		log_misc("VIRUS TESTING: [ticks] : germs [germs] tdamage [tdamage] prob [round(damage/10)*20]")
		ticks++
		if (prob(round(damage/10)*20))
			germs++
		if (germs == 100)
			to_chat(world, "Reached stage 1 in [ticks] ticks")
		if (germs > 100)
			if (prob(10))
				damage++
				germs++
		if (germs == 1000)
			to_chat(world, "Reached stage 2 in [ticks] ticks")
		if (germs > 1000)
			damage++
			germs++
		if (germs == 2500)
			to_chat(world, "Reached stage 3 in [ticks] ticks")
	to_chat(world, "Mob took [tdamage] tox damage")
*/
//returns 1 if made bloody, returns 0 otherwise

/mob/living/carbon/human/add_blood(mob/living/carbon/human/M)
	if (!..())
		return 0
	//if this blood isn't already in the list, add it
	if(blood_DNA[M.dna.unique_enzymes])
		return 0 //already bloodied with this blood. Cannot add more.
	blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
	hand_dirt_datum = new(dirt_overlay)

	update_inv_slot(SLOT_GLOVES) // handles bloody hands overlays and updating
	verbs += /mob/living/carbon/human/proc/bloody_doodle
	return 1 //we applied blood to the item

/mob/living/carbon/human/add_dirt_cover(dirt_datum, update_hands_slot = TRUE)
	. = ..()
	if (!.)
		return
	if(update_hands_slot) // incase this proc was called by atom/proc/add_blood which will update gloves slot by itself to remove doublecall, -
		update_inv_slot(SLOT_GLOVES) // - also it will runtime cause bloody hands isnt fully initialized yet and no idea why add_blood also adds dirt at the same time, not to mention both systems pretty much same thing in the end (legacy times when dirt was overlay?).

// returns associative list (implant = bodypart)
/mob/living/carbon/human/get_visible_implants(class = 0)

	var/list/visible_implants = list()
	for(var/obj/item/organ/external/BP in bodyparts)
		for(var/obj/item/weapon/O in BP.embedded_objects)
			if(!istype(O,/obj/item/weapon/implant) && O.w_class > class)
				visible_implants[O] = BP

	return(visible_implants)

/mob/living/carbon/human/proc/handle_embedded_objects()

	for(var/obj/item/organ/external/BP in bodyparts)
		if(BP.status & ORGAN_SPLINTED) //Splints prevent movement.
			continue
		for(var/obj/item/weapon/O in BP.embedded_objects)
			if(!istype(O,/obj/item/weapon/implant) && prob(5)) //Moving with things stuck in you could be bad.
				// All kinds of embedded objects cause bleeding.
				var/msg = null
				switch(rand(1,3))
					if(1)
						msg ="<span class='warning'>A spike of pain jolts your [BP.name] as you bump [O] inside.</span>"
					if(2)
						msg ="<span class='warning'>Your movement jostles [O] in your [BP.name] painfully.</span>"
					if(3)
						msg ="<span class='warning'>[O] in your [BP.name] twists painfully as you move.</span>"
				to_chat(src, msg)

				BP.take_damage(rand(1,3), 0, 0)
				if(!BP.is_robotic()) //There is no blood in protheses.
					if(!reagents.has_reagent("metatrombine")) // metatrombine just prevents bleeding, not toxication
						BP.status |= ORGAN_BLEEDING
					adjustToxLoss(rand(1,3))

/mob/living/carbon/human/verb/check_pulse()
	set category = "Object"
	set name = "Check pulse"
	set desc = "Approximately count somebody's pulse. Requires you to stand still at least 6 seconds."
	set src in view(1)
	var/self = 0

	if(usr.incapacitated())
		return

	if(usr == src)
		self = 1
	if(!self)
		usr.visible_message("<span class='notice'>[usr] kneels down, puts \his hand on [src]'s wrist and begins counting their pulse.</span>",\
		"You begin counting [src]'s pulse")
	else
		usr.visible_message("<span class='notice'>[usr] begins counting their pulse.</span>",\
		"You begin counting your pulse.")

	if(src.pulse)
		to_chat(usr, "<span class='notice'>[self ? "You have a" : "[src] has a"] pulse! Counting...</span>")
	else
		to_chat(usr, "<span class='warning'>[src] has no pulse!</span>")//it is REALLY UNLIKELY that a dead person would check his own pulse
		return

	to_chat(usr, "Don't move until counting is finished.")
	var/time = world.time
	sleep(60)
	if(usr.l_move_time >= time)	//checks if our mob has moved during the sleep()
		to_chat(usr, "You moved while counting. Try again.")
	else
		to_chat(usr, "<span class='notice'>[self ? "Your" : "[src]'s"] pulse is [get_pulse(GETPULSE_HAND)].</span>")

/mob/living/carbon/human/proc/set_species(new_species, force_organs = TRUE, default_colour = FALSE)
	var/datum/species/old_species = species

	if(!new_species)
		if(dna.species)
			new_species = dna.species
		else
			new_species = HUMAN
	else
		dna.species = new_species

	if(species)
		if(species.name == new_species)
			return FALSE

		if(species.language)
			remove_language(species.language)

		if(species.additional_languages)
			for(var/A in species.additional_languages)
				remove_language(A)

		if(client?.prefs.language)
			remove_language(client.prefs.language)

	species = all_species[new_species]

	if(old_species)
		old_species.on_loose(src, new_species)

	maxHealth = species.total_health

	if(force_organs || !bodyparts.len)
		species.create_organs(src, deleteOld = TRUE)
	full_prosthetic = null

	if(species.language)
		add_language(species.language, LANGUAGE_NATIVE)

	if(species.additional_languages)
		for(var/A in species.additional_languages)
			add_language(A, species.additional_languages[A])

	typing_indicator_type = species.typing_indicator_type

	species.on_gain(src)

	for(var/datum/quirk/Q in roundstart_quirks)
		if(SSquirks.quirk_blacklist_species[Q.name] && (species.name in SSquirks.quirk_blacklist_species[Q.name]))
			qdel(Q)

	regenerate_icons(update_body_preferences = TRUE)

	if(species)
		return TRUE
	else
		return FALSE

// Unlike set_species(), this proc simply changes owner's specie and thats it.
// todo: why we need to support two set species procedures just because of abductors, 
// merge it with the one above and add args to toggle behavior
/mob/living/carbon/human/proc/set_species_soft(new_species)
	if(species.name == new_species)
		return

	species.on_loose(src)

	species = all_species[new_species]
	maxHealth = species.total_health

	species.on_gain(src)

	regenerate_icons(update_body_preferences = TRUE)

/mob/living/carbon/human/proc/bloody_doodle()
	set category = "IC"
	set name = "Write in blood"
	set desc = "Use blood on your hands to write a short message on the floor or a wall, murder mystery style."

	if(incapacitated())
		return

	if(usr != src)
		return 0 //something is terribly wrong

	if(!dirty_hands_transfers)
		verbs -= /mob/living/carbon/human/proc/bloody_doodle

	if(src.gloves)
		to_chat(src, "<span class='warning'>[src.gloves] мешают вам это сделать.</span>")
		return

	var/max_length = dirty_hands_transfers * 30 //tweeter style
	var/message = sanitize(input(src, "Напишите сообщение. Оно не должно быть более [max_length] символов.", "Писание кровью", ""))

	if(message)
		var/turf/simulated/T = get_step(src, dir)
		if(!istype(T)) //to prevent doodling out of mechs and lockers
			to_chat(src, "<span class='warning'>Вы не можете здесь рисовать.</span>")
			return

		var/num_doodles = 0
		for(var/obj/effect/decal/cleanable/blood/writing/W in T)
			num_doodles++
		if(num_doodles > 4)
			to_chat(src, "<span class='warning'>Недостаточно места для еще одной надписи.</span>")
			return

		var/used_blood_amount = round(length(message) / 30, 1)
		dirty_hands_transfers = max(0, dirty_hands_transfers - used_blood_amount) //use up some blood

		if(length_char(message) > max_length)
			message = "[copytext_char(message, 1, max_length+1)]~"
			to_chat(src, "<span class='warning'>Вам не хватило крови дописать.</span>")

		var/obj/effect/decal/cleanable/blood/writing/W = new(T)
		W.basedatum = new(hand_dirt_datum)
		W.update_icon()
		W.message = message
		W.add_fingerprint(src)

/mob/living/carbon/human/verb/skills_menu()
	set category = "IC"
	set name = "Skills Menu"
	var/list/tables_data = list(
		"Engineering related skills" = list(
			/datum/skill/engineering,
			/datum/skill/construction,
			/datum/skill/atmospherics
			),
		"Medical skills" = list(
			/datum/skill/medical,
			/datum/skill/surgery,
			/datum/skill/chemistry
			),
		"Combat skills" = list(
			/datum/skill/melee,
			/datum/skill/firearms,
			/datum/skill/police,
			/datum/skill/combat_mech
			),
		"Civilian skills" = list(
			/datum/skill/command,
			/datum/skill/research,
			/datum/skill/civ_mech
			)
	)
	var/dat = {"
		<style>
			.skill_slider {
				width: 100%;
				position: relative;
				padding: 0;
			}
			table {
				line-height: 5px;
				width: 100%;
				border-collapse: collapse;
				border: 1px solid;
				padding: 0;
			}
			td {
				width: 25%;
			}
			td:nth-child(2n+0) {
				width: 65%;
			}
			td:nth-child(3n+0) {
				width: 10%;
			}
			caption {
				line-height: normal;
				color: white;
				background-color: #444;
				font-weight: bold;
			}
			.container{
				text-align: center;
				width: 100%;
			}
		</style>
		"}
	dat += {"
		<div class = "container">
			<button type="submit" value="1" onclick="setMaxSkills()">Set skills values to maximum</button>
			<button type="submit" value="1" onclick="AskHelp()">Ask others for help</button>
		</div>
	"}
	for(var/category in tables_data)
		dat += {"
			<table>
				<caption>[category]</caption>
		"}

		var/list/sliders_data = tables_data[category]

		for(var/datum/skill/s as anything in sliders_data)
			var/datum/skill/skill = global.all_skills[s]
			var/slider_id = skill.name
			var/slider_value = mind.skills.get_value(s)
			var/slider_min_value = SKILL_LEVEL_MIN
			var/slider_max_value = mind.skills.get_max(s)
			var/rank_list = skill.custom_ranks
			var/rank_list_element = ""
			for(var/rank in rank_list)
				rank_list_element += "[rank]\n"
			if(slider_max_value == slider_min_value)
				continue
			var/slider_hint = "Hint: [skill.hint]\n\nSkill ranks:\n[rank_list_element]"
			dat += {"
				<tr>
					<td>
						[slider_id] <span title="[slider_hint]">(?)</span>:
					</td>
					<td>
						<input type="range" class="skill_slider" min="[slider_min_value]" max="[slider_max_value]" value="[slider_value]" id="[slider_id]" onchange="updateSkill('[slider_id]')" >
					</td>
					<td>
						<p><b><center><a href='byond://?src=\ref[src];skill=[slider_id]&value=[slider_value]'><span id="[slider_id]_value">[slider_value]</span></a></center></b></p>
					</td>
				</tr>
			"}

		dat += {"
			</table>
		"}

	dat +={"
		<p><span id="notice">&nbsp;</span></p>
		<script>
			var skillUpdating = false;
			function updateSkill(slider_id) {
				if (!skillUpdating) {
					skillUpdating = true;
					setTimeout(function() {
						setSkill(slider_id);
					}, 300);
				}
			}
			function setSkill(slider_id) {
				var element =  document.getElementById(slider_id);
				var value = element.value;
				window.location = 'byond://?src=\ref[src];skill=' + slider_id + '&value=' + value;
				skillUpdating = false;

				document.getElementById(slider_id + "_value").innerHTML = value;
			}
			function setMaxSkills() {
				window.location  = 'byond://?src=\ref[src];set_max_skills=1';
				setTimeout("location.reload(true);", 100);
			}
			function AskHelp()
			{
				window.location  = 'byond://?src=\ref[src];request_help=1';
				setTimeout("location.reload(true);", 100);
			}
		</script>
		"}
	var/style = CSS_THEME_DARK
	if (mind.antag_roles.len)
		style = CSS_THEME_SYNDICATE
	var/datum/browser/popup = new(usr, "mob\ref[src]", "Skills menu", 620, 500, null, style)
	popup.set_content(dat)
	popup.open()

/mob/living/carbon/human/proc/update_skills(href_list)
	var/skill_name = href_list["skill"]
	var/value = text2num(href_list["value"])
	if(!isnum(value) || !istext(skill_name))
		return
	if(!mind)
		return
	for(var/skill_type in all_skills)
		var/datum/skill/skill = all_skills[skill_type]
		if(skill.name == skill_name)
			mind.skills.choose_value(skill_type, value)
			return


/mob/living/carbon/human/verb/examine_ooc()
	set name = "Examine OOC"
	set category = "OOC"
	set src in oview()

	if(!usr || !src)	return

	to_chat(usr, "<font color='purple'>OOC-info: [src]</font>")
	if(metadata)
		to_chat(usr, "<font color='purple'>[metadata]</font>")
	else
		to_chat(usr, "<font color='purple'>Nothing of interest...</font>")

/mob/living/carbon/try_inject(mob/living/user, error_msg, instant, stealth, pierce_armor)
	if(istype(user))
		if(user.is_busy())
			return

		if(!user.IsAdvancedToolUser())
			if(error_msg)
				to_chat(user, "<span class='warning'>You have no idea, how to use this!</span>")
			return FALSE

		if (HULK in user.mutations) // TODO - meaty fingers or something like that.
			if(error_msg)
				to_chat(user, "<span class='warning'>You don't have the dexterity to do this!</span>")
			return FALSE

		var/hunt_injection_port = FALSE

		switch(check_pierce_protection(target_zone = user.get_targetzone()))
			if(NOLIMB)
				if(error_msg)
					to_chat(user, "<span class='warning'>[src] has no such body part, try to inject somewhere else.</span>")
				return FALSE
			if(NOPIERCE)
				if(!pierce_armor)
					if(error_msg)
						to_chat(user, "<span class='alert'>There is no exposed flesh or thin material [user.get_targetzone() == BP_HEAD ? "on their head" : "on their body"] to inject into.</span>")
					return FALSE
			if(PHORONGUARD)
				if(!pierce_armor)
					if(user.a_intent == INTENT_HARM)
						if(error_msg)
							to_chat(user, "<span class='alert'>There is no exposed flesh or thin material [user.get_targetzone() == BP_HEAD ? "on their head" : "on their body"] to inject into.</span>")
						return FALSE
					hunt_injection_port = TRUE

		if(isSynthetic(user.get_targetzone()))
			if(error_msg)
				to_chat(user, "<span class='warning'>You are trying to inject [src]'s synthetic body part!</span>")
			return FALSE
		var/injection_time
		if(user != src)
			//untrained 8 seconds, novice 6.8, trained 5.6, pro 4.4, expert 3.2 and master 2
			injection_time = apply_skill_bonus(user, SKILL_TASK_TOUGH, list(/datum/skill/medical = SKILL_LEVEL_NONE), multiplier = -0.15) //-15% for each medical level
		else
			//it is much easier to prick yourself than another person
			injection_time = apply_skill_bonus(user, SKILL_TASK_AVERAGE, list(/datum/skill/medical = SKILL_LEVEL_NONE), multiplier = -0.15)
		if(!instant)
			if(hunt_injection_port) // takes additional time
				if(!stealth && user != src)
					user.visible_message("<span class='danger'>[user] begins hunting for an injection port on [src]'s suit!</span>")
				if(!do_mob(user, src, injection_time / 2, TRUE))
					return FALSE

			if(!stealth)
				if(user != src)
					user.visible_message("<span class='danger'>[user] is trying to inject [src]!</span>")

			if(!do_mob(user, src, injection_time, TRUE))
				return FALSE

		if(!stealth)
			if(user != src)
				user.visible_message("<span class='warning'>[user] injects [src] with the syringe!</span>")
		else
			to_chat(user, "<span class'notice'>You inject [src] with the injector.</span>")
			to_chat(src, "<span class='warning'>You feel a tiny prick!</span>")

	return TRUE

/mob/living/carbon/human/has_brain()
	if(organs_by_name[O_BRAIN])
		var/obj/item/organ/internal/IO = organs_by_name[O_BRAIN]
		if(istype(IO))
			return TRUE
	return FALSE

/mob/living/carbon/human/has_eyes()
	if(organs_by_name[O_EYES])
		var/obj/item/organ/internal/IO = organs_by_name[O_EYES]
		if(istype(IO))
			return TRUE
	return FALSE

/mob/living/carbon/human/is_nude(maximum_coverage = 0, pos_slots = list(src.head, src.shoes, src.neck, src.mouth, src.wear_suit, src.w_uniform, src.belt, src.gloves, src.glasses)) // Expands our pos_slots arg.
	return ..()

/mob/living/carbon/human/proc/electrocution_animation(anim_duration)
	new /obj/effect/electrocute(null, src, anim_duration)

/mob/living/carbon/human/proc/get_skeleton_appearance()
	var/mutable_appearance/MA = new()
	MA.appearance_flags = KEEP_TOGETHER
	for(var/obj/item/organ/external/BP in bodyparts)
		if(BP.is_stump || BP.is_robotic() || !BP.species.skeleton)
			continue
		var/skeleton_state = BP.get_icon_state(gender_state = FALSE, fat_state = FALSE, pump_state = FALSE) // there is no fat or pumped skeletons
		MA.add_overlay(mutable_appearance(species.skeleton, skeleton_state))
	MA = update_height(MA)
	return MA

/mob/living/carbon/human/proc/get_nude_appearance()
	var/mutable_appearance/MA = new()
	MA.appearance_flags = KEEP_TOGETHER
	for(var/obj/item/organ/external/BP in bodyparts)
		if(BP.is_stump)
			continue
		// or we can use BP.generate_appearances() right away, but it will generate hairs too
		var/mutable_appearance/nude_appearance = mutable_appearance(BP.icon, BP.get_icon_state())
		nude_appearance.color = BP.get_skin_color()
		MA.add_overlay(nude_appearance)
	MA = update_height(MA)
	return MA

/mob/living/carbon/human/proc/should_have_organ(organ_check)

	if(HAS_TRAIT(src, ELEMENT_TRAIT_SKELETON))
		return FALSE

	var/obj/item/organ/external/BP
	if(organ_check in list(O_HEART, O_LUNGS))
		BP = bodyparts_by_name[BP_CHEST]
	else if(organ_check in list(O_LIVER, O_KIDNEYS))
		BP = bodyparts_by_name[BP_GROIN]

	if(BP && BP.is_robotic())
		return FALSE
	return species.has_organ[organ_check]

/mob/living/carbon/human/can_eat(flags = DIET_ALL)
	return species && (species.dietflags & flags)

/mob/living/carbon/human/get_taste_sensitivity()
	if (HAS_TRAIT(src, TRAIT_AGEUSIA))
		return TASTE_SENSITIVITY_NO_TASTE
	if(species)
		return species.taste_sensitivity
	else
		return 1

// does not skip because of mob_oxy_mod as mod is only for damage
/mob/living/carbon/human/is_skip_breathe()
	if(..())
		return TRUE
	if(HAS_TRAIT(src, TRAIT_NO_BREATHE))
		return TRUE
	if(!should_have_organ(O_LUNGS))
		return TRUE
	if(reagents.has_reagent("lexorin"))
		return TRUE
	if(istype(loc, /obj/machinery/atmospherics/components/unary/cryo_cell))
		return TRUE
	if(ismob(loc))
		return TRUE
	return FALSE

/mob/living/carbon/human/CanObtainCentcommMessage()
	return istype(l_ear, /obj/item/device/radio/headset) || istype(r_ear, /obj/item/device/radio/headset)

/mob/living/carbon/human/make_dizzy(amount)
	if(species.flags[IS_SYNTHETIC])
		return
	dizziness = min(1000, dizziness + amount)	// store what will be new value
													// clamped to max 1000
	if(dizziness > 100 && !is_dizzy)
		INVOKE_ASYNC(src, TYPE_PROC_REF(/mob, dizzy_process))

/mob/living/carbon/human/make_jittery(amount)
	if(species.flags[IS_SYNTHETIC])
		return
	jitteriness = min(1000, jitteriness + amount)	// store what will be new value
													// clamped to max 1000
	if(jitteriness > 30 && !is_jittery)
		INVOKE_ASYNC(src, TYPE_PROC_REF(/mob, jittery_process))
	. = jitteriness

/mob/living/carbon/human/is_facehuggable()
	return species.flags[FACEHUGGABLE] && stat != DEAD && !(locate(/obj/item/alien_embryo) in contents)

/mob/living/carbon/human/verb/remove_bandages()
	set category = "IC"
	set name = "Remove bandages"
	set desc = "Remove your own bandages"

	if(stat == DEAD)
		to_chat(usr, "<span class='notice'>There is no point in doing so with the dead body.</span>")
		return
	if(!ishuman(usr) || usr.incapacitated())
		return
	var/list/wounds
	var/has_visual_bandages = FALSE // We need this var because wounds might have healed by themselfs

	for(var/obj/item/organ/external/BP in bodyparts)
		if(BP.bandaged)
			has_visual_bandages = TRUE
			for(var/datum/wound/W in BP.wounds)
				if(W.bandaged)
					LAZYADD(wounds, W)

	if(wounds || has_visual_bandages)
		visible_message("<span class='danger'>[usr] is trying to remove [src == usr ? "their" : "[src]'s"] bandages!</span>")
		if(do_mob(usr, src, HUMAN_STRIP_DELAY))
			for(var/datum/wound/W in wounds)
				if(W.bandaged)
					W.bandaged = 0
			update_bandage()
			attack_log += "\[[time_stamp()]\] <font color='orange'>Had their bandages removed by [usr.name] ([usr.ckey]).</font>"
			usr.attack_log += "\[[time_stamp()]\] <font color='red'>Removed [name]'s ([ckey]) bandages.</font>"

/mob/living/carbon/human/proc/perform_cpr(mob/living/carbon/human/user)
	if(HAS_TRAIT(src, TRAIT_NO_BLOOD)) // this checks for ipc/dionea/etc., but probably we should check for can_breathe and lungs
		return

	if(world.time - timeofdeath >= DEFIB_TIME_LIMIT)
		to_chat(user, "<span class='notice'>It seems [src] is far too gone to be reanimated... Your efforts are futile.</span>")
		return

	if(check_pierce_protection(target_zone = BP_CHEST))
		to_chat(user, "<span class='warning'>You have to open up [src]'s chest to perform CPR!.</span>")
		return

	if(user.is_busy(src))
		return

	var/obj/item/organ/internal/heart/Heart = organs_by_name[O_HEART]
	var/obj/item/organ/internal/heart/Lungs = organs_by_name[O_LUNGS]

	var/fail_damage = apply_skill_bonus(user, 20, list(/datum/skill/medical = SKILL_LEVEL_NONE),  multiplier = -0.20)
	var/needed_massages = 12
	var/obj/item/organ/external/BP = get_bodypart(Heart.parent_bodypart)
	if(HAS_TRAIT(src, TRAIT_FAT))
		needed_massages = 20
	if(Lungs && !Lungs.is_bruised())
		adjustOxyLoss(-1.5)

	if(!Heart || Heart.heart_status == HEART_NORMAL)
		return

	if(Heart.heart_status == HEART_FAILURE)
		if(do_mob(user, src, 4 SECONDS))
			visible_message("<span class='danger'>[user] is trying perform a heart massage on [src]!</span>")

			massages_done_right = 0

			if((health > config.health_threshold_dead) || (!suiciding))
				INVOKE_ASYNC(src, TYPE_PROC_REF(/mob/living/carbon/human, return_to_body_dialog))
				Heart.heart_fibrillate()
				to_chat(user, "<span class='notice'>You feel an irregular heartbeat coming form [src]'s body. It is in need of defibrillation you assume!</span>")
			else
				to_chat(user, "<span class='warning'>[src]'s body seems to be too weak, you do not feel a heart beat.</span>")

			last_massage = world.time
		return

	visible_message("<span class='danger'>[user] is trying perform CPR on [src]!</span>")

	if(massages_done_right > needed_massages)
		if(health < config.health_threshold_dead)
			to_chat(user, "<span class='warning'>[src]'s heart did not start to beat!</span>")
		else
			to_chat(user, "<span class='warning'>[src]'s heart starts to beat!</span>")
			reanimate_body()
			stat = UNCONSCIOUS
			massages_done_right = 0
			Heart.heart_normalize()

	else if(massages_done_right < -2)
		to_chat(user, "<span class='warning'>[src]'s heart stopped!</span>")
		Heart.damage += 2
		massages_done_right = 0
		Heart.heart_stop()

	else if(Heart.damage < 50)
		if(last_massage > world.time - MASSAGE_RHYTM_RIGHT - MASSAGE_ALLOWED_ERROR && last_massage < world.time - MASSAGE_RHYTM_RIGHT + MASSAGE_ALLOWED_ERROR)
			massages_done_right++
			to_chat(user, "<span class='notice'>You've hit right to the [src]'s heart beat!</span>")
		else
			massages_done_right--
			to_chat(user, "<span class='warning'>You've skipped a beat.</span>")
			if ((BP.body_zone == BP_CHEST && op_stage.ribcage != 2) || BP.open < 2)
				apply_damage(fail_damage, BRUTE, BP.body_zone)

	else
		to_chat(user, "<span class='warning'>It seems [src]'s [Heart] is too squishy... It doesn't beat at all!</span>")

	last_massage = world.time

/mob/living/carbon/human/proc/return_to_body_dialog()
	// just give a sound notification if already in the body
	if (client)
		playsound_local(null, 'sound/misc/mario_1up.ogg', VOL_NOTIFICATIONS, vary = FALSE, ignore_environment = TRUE)
		return

	// pluvians if they in the spirit form
	if(ispluvian(src))
		for(var/mob/living/carbon/human/pluvian_spirit/spirit in player_list)
			if(spirit.my_corpse == src && spirit.client)
				spirit.playsound_local(null, 'sound/misc/mario_1up.ogg', VOL_NOTIFICATIONS, vary = FALSE, ignore_environment = TRUE)
				var/answer = tgui_alert(spirit,"You have been reanimated. Do you want to return to body?","Reanimate", list("Yes","No"))
				if(answer == "Yes")
					spirit.mind.transfer_to(spirit.my_corpse)
					for(var/spell in spirit.spells_to_remember)
						spirit.my_corpse.AddSpell(spell)
					for(var/obj/item/I in spirit.my_corpse.contents)
						I.add_item_actions(spirit.my_corpse)
					spirit.my_corpse.hud_used.set_parallax(PARALLAX_CLASSIC)
					message_admins("Pluvian [key_name_admin(spirit.my_corpse)] is living saint now")
					log_admin("Pluvian [key_name(spirit.my_corpse)] is living saint now")
					for(var/obj/item/W in spirit)
						spirit.drop_from_inventory(W)
					qdel(spirit)
					global.pluvia_religion.bless(src)
				return

	// default behavior - search for the ghost from the mind datum and ask if he want to reenter
	if(mind)
		for(var/mob/dead/observer/ghost in player_list)
			if(ghost.mind == mind && ghost.can_reenter_corpse)
				ghost.playsound_local(null, 'sound/misc/mario_1up.ogg', VOL_NOTIFICATIONS, vary = FALSE, ignore_environment = TRUE)
				var/answer = tgui_alert(ghost,"You have been reanimated. Do you want to return to body?","Reanimate", list("Yes","No"))
				if(answer == "Yes")
					ghost.reenter_corpse()
				break

/mob/living/carbon/human/proc/reanimate_body()
	var/deadtime = world.time - timeofdeath
	tod = null
	timeofdeath = 0
	dead_mob_list -= src

	if(deadtime > DEFIB_TIME_LOSS)
		// damage for every second above DEFIB_TIME_LOSS till DEFIB_TIME_LIMIT
		// 60 is often used as threshold for brainloss to trigger funny interactions
		adjustBrainLoss(LERP(0, 60, (deadtime - DEFIB_TIME_LOSS)/(DEFIB_TIME_LIMIT - DEFIB_TIME_LOSS))) 

	med_hud_set_health()

/mob/living/carbon/human/can_inject(mob/user, def_zone, show_message = TRUE, penetrate_thick = FALSE)
	. = TRUE

	// If targeting the head, see if the head item is thin enough.
	// If targeting anything else, see if the wear suit is thin enough.
	if(!penetrate_thick)
		if(check_pierce_protection(target_zone = def_zone))
			if(show_message)
				to_chat(user, "<span class='alert'>There is no exposed flesh or thin material [user.get_targetzone() == BP_HEAD ? "on their head" : "on their body"] to inject into.</span>")
			return FALSE

	if(isSynthetic(def_zone))
		if(show_message)
			to_chat(user, "<span class='alert'>There is no exposed flesh or thin material [user.get_targetzone() == BP_HEAD ? "on their head" : "on their body"] to inject into.</span>")
		return FALSE

	return TRUE

/mob/living/carbon/human/update_size_class()

	var/new_w_class = initial(w_class)

	if(SMALLSIZE in mutations)
		new_w_class -= 1

	if(HAS_TRAIT_FROM(src, TRAIT_FAT, OBESITY_TRAIT))
		new_w_class += 1

	w_class = new_w_class

	return w_class

#undef MASSAGE_RHYTM_RIGHT
#undef MASSAGE_ALLOWED_ERROR

/mob/living/carbon/human/proc/AdjustWetClothes(amount)
	wet_clothes += amount
	if(wet_clothes <= 0)
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "wet_clothes")
		return

	if(species.flags[IS_SYNTHETIC])
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "wet_clothes", /datum/mood_event/dangerous_clothes, -wet_clothes * 2)
		return
	if(get_species() in list(SKRELL, DIONA, PODMAN))
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "wet_clothes", /datum/mood_event/refreshing_clothes, wet_clothes)
		return
	SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "wet_clothes", /datum/mood_event/wet_clothes, -wet_clothes)

/mob/living/carbon/human/proc/AdjustDirtyClothes(amount)
	dirty_clothes += amount
	if(dirty_clothes <= 0)
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "dirty_clothes")
		return

	SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "dirty_clothes", /datum/mood_event/dirty_clothes, -dirty_clothes)

/mob/living/carbon/human/proc/mood_item_equipped(datum/source, obj/item/I, slot)
	SIGNAL_HANDLER

	if(I.slot_equipped)
		return

	if(I.wet)
		AdjustWetClothes(1)
		RegisterSignal(I, list(COMSIG_ITEM_MAKE_DRY), PROC_REF(mood_item_make_dry))
	else
		RegisterSignal(I, list(COMSIG_ITEM_MAKE_WET), PROC_REF(mood_item_make_wet))

	if(I.dirt_overlay)
		AdjustDirtyClothes(1)
		RegisterSignal(I, list(COMSIG_ATOM_CLEAN_BLOOD), PROC_REF(mood_item_clean_blood))
	else
		RegisterSignal(I, list(COMSIG_ATOM_ADD_DIRT), PROC_REF(mood_item_add_dirt))

	RegisterSignal(I, list(COMSIG_ITEM_DROPPED), PROC_REF(mood_item_dropped))

/mob/living/carbon/human/proc/mood_item_dropped(datum/source, mob/living/user)
	SIGNAL_HANDLER

	var/obj/item/I = source

	if(I.wet)
		AdjustWetClothes(-1)
		UnregisterSignal(I, list(COMSIG_ITEM_MAKE_DRY))
	else
		UnregisterSignal(I, list(COMSIG_ITEM_MAKE_WET))

	if(I.dirt_overlay)
		AdjustDirtyClothes(-1)
		UnregisterSignal(I, list(COMSIG_ATOM_CLEAN_BLOOD))
	else
		UnregisterSignal(I, list(COMSIG_ATOM_ADD_DIRT))

	UnregisterSignal(I, list(COMSIG_ITEM_DROPPED))

/mob/living/carbon/human/proc/mood_item_add_dirt(datum/source, datum/dirt_cover/dirt_datum)
	SIGNAL_HANDLER

	var/obj/item/I = source

	AdjustDirtyClothes(1)

	RegisterSignal(I, list(COMSIG_ATOM_CLEAN_BLOOD), PROC_REF(mood_item_clean_blood))
	UnregisterSignal(I, list(COMSIG_ATOM_ADD_DIRT))

/mob/living/carbon/human/proc/mood_item_clean_blood(datum/source)
	SIGNAL_HANDLER

	var/obj/item/I = source

	AdjustDirtyClothes(-1)

	RegisterSignal(I, list(COMSIG_ATOM_ADD_DIRT), PROC_REF(mood_item_add_dirt))
	UnregisterSignal(I, list(COMSIG_ATOM_CLEAN_BLOOD))

/mob/living/carbon/human/proc/mood_item_make_wet(datum/source)
	SIGNAL_HANDLER

	var/obj/item/I = source

	AdjustWetClothes(1)

	RegisterSignal(I, list(COMSIG_ITEM_MAKE_DRY), PROC_REF(mood_item_make_dry))
	UnregisterSignal(I, list(COMSIG_ITEM_MAKE_WET))

/mob/living/carbon/human/proc/mood_item_make_dry(datum/source)
	SIGNAL_HANDLER

	var/obj/item/I = source

	AdjustWetClothes(-1)

	RegisterSignal(I, list(COMSIG_ITEM_MAKE_WET), PROC_REF(mood_item_make_wet))
	UnregisterSignal(I, list(COMSIG_ITEM_MAKE_DRY))

/mob/living/carbon/human/proc/attack_heart(damage_prob, heal_prob)
	var/obj/item/organ/internal/heart/Heart = organs_by_name[O_HEART]
	if(!Heart)
		return
	switch(Heart.heart_status)
		if(HEART_NORMAL)
			if(prob(damage_prob))
				Heart.heart_fibrillate()
		if(HEART_FIBR)
			if(prob(damage_prob))
				Heart.heart_stop()
			if(prob(heal_prob))
				Heart.heart_normalize()
		if(HEART_FAILURE)
			if(prob(heal_prob))
				Heart.heart_fibrillate()


/mob/living/carbon/human/proc/PutDisabilityMarks()
	var/obj/item/weapon/card/id/card = locate(/obj/item/weapon/card/id, src)
	if(!card)
		return
	for(var/datum/quirk/Q in roundstart_quirks)
		if(Q.disability)
			card.disabilities += Q.name

/mob/living/carbon/human/handle_drunkenness()
	. = ..()
	if(drunkenness >= DRUNKENNESS_PASS_OUT)
		var/obj/item/organ/internal/liver/IO = organs_by_name[O_LIVER]
		if(istype(IO))
			IO.take_damage(0.1, 1)
		adjustToxLoss(0.1)

// TO-DO: make it so it algo triggers a random mild virus symptom because that's funny? ~Luduk
/mob/living/carbon/human/proc/trigger_allergy(reagent, volume)
	if(!allergies)
		return

	if(!allergies[reagent])
		return

	if(reagents.has_reagent("inaprovaline"))
		reagents.remove_reagent("inaprovaline", volume)
		return

	allergies[reagent] += volume

	var/effect_coeff = 0.0

	switch(allergies[reagent])
		if(ALLERGY_UNDISCOVERED to ALLERGY_DISCOVERED)
			effect_coeff = 0.1
		if(ALLERGY_DISCOVERED to ALLERGY_LETHAL)
			effect_coeff = 0.5
			allergies[reagent] = ALLERGY_LETHAL
			to_chat(src, "<span class='danger'>AAAH THE RASH IS UNBEARABLE!</span>")
		if(ALLERGY_LETHAL to INFINITY)
			effect_coeff = 2.0
			adjustOxyLoss(effect_coeff)
			if(next_allergy_message < world.time)
				next_allergy_message = world.time + 10 SECONDS
				to_chat(src, "<span class='userdanger'>I THINK I'M DYING!</span>")

	adjustToxLoss(effect_coeff)

	adjust_bodytemperature(10 * effect_coeff * TEMPERATURE_DAMAGE_COEFFICIENT, max_temp = BODYTEMP_NORMAL + 20)

/mob/living/carbon/human/get_pumped(bodypart)
	var/obj/item/organ/external/BP = get_bodypart(bodypart)
	if(!BP)
		return 0

	return BP.pumped

/mob/living/carbon/human/clean_blood()
	. = ..()
	if(gloves)
		gloves.clean_blood()
		gloves.germ_level = 0
	else
		dirty_hands_transfers = 0
		QDEL_NULL(hand_dirt_datum)
		update_inv_slot(SLOT_GLOVES)
		germ_level = 0

/mob/living/carbon/human/pickup_ore()
	var/turf/simulated/floor/F = get_turf(src)
	var/obj/item/weapon/storage/bag/ore/B
	for(var/obj/item/weapon/storage/bag/ore/bag in list(l_store , r_store, l_hand, r_hand, belt, s_store))
		B = bag
		if(B.max_storage_space < B.storage_space_used() + SIZE_TINY)
			continue
		F.attackby(B, src)
		break

/mob/living/carbon/human/proc/randomize_appearance()
	gender = pick(MALE, FEMALE)

	name = random_name(gender, species.name)
	real_name = name

	s_tone = random_skin_tone()

	h_style = random_hair_style(gender, species)
	var/list/hair_color = random_hair_color()
	r_hair = hair_color[1]
	g_hair = hair_color[2]
	b_hair = hair_color[3]

	if(prob(25))
		grad_style = random_gradient_style()
		var/list/grad_color = random_hair_color()
		r_grad = grad_color[1]
		g_grad = grad_color[2]
		b_grad = grad_color[3]

	f_style = random_facial_hair_style(gender, species.name)
	r_facial = r_hair
	g_facial = g_hair
	b_facial = b_hair

	var/list/eye_color = random_eye_color()
	r_eyes = eye_color[1]
	g_eyes = eye_color[2]
	b_eyes = eye_color[3]

	underwear = rand(1,underwear_m.len)
	undershirt = rand(1,undershirt_t.len)
	socks = rand(1, socks_t.len)
	backbag = rand(2, backbaglist.len)

	use_skirt = pick(TRUE, FALSE)

	var/datum/species/S = all_species[species.name]
	age = rand(S.min_age, S.max_age)

	regenerate_icons(update_body_preferences = TRUE) 

/mob/living/carbon/human/get_blood_datum()
	if(HAS_TRAIT(src, ELEMENT_TRAIT_SLIME))
		return /datum/dirt_cover/blue_blood
	
	if(species.blood_datum_path)
		return species.blood_datum_path

	return /datum/dirt_cover/red_blood

/mob/living/carbon/human/get_flesh_color()
	if(HAS_TRAIT(src, ELEMENT_TRAIT_SLIME))
		return "#05fffb"

	if(species.flesh_color)
		return species.flesh_color

	return "#ffffff"

/mob/living/carbon/get_trail_state()
	return "trails_1"

/mob/living/carbon/human/get_trail_state()
	if(blood_amount() > 0)
		return ..()
