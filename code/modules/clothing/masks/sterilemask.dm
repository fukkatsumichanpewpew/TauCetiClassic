/obj/item/clothing/mask/sterile
	name = "sterile mask"
	desc = "Стерильная маска, предназначенная для предотвращения распространения заболеваний."
	icon_state = "sterileup"
	item_state = "m_mask"
	item_state_world = "sterile"
	w_class = SIZE_TINY
	flags = MASKCOVERSMOUTH
	body_parts_covered = 0
	armor = list(melee = 0, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 25, rad = 0)

/datum/action/item_action/hands_free/adjust_mask
	name = "Adjust mask"

/obj/item/clothing/mask/sterile/attack_self(mob/user)

	if(!user.incapacitated())
		if(!src.hanging)
			src.hanging = !src.hanging
			gas_transfer_coefficient = 0.90
			flags &= ~(MASKCOVERSMOUTH)
			icon_state = "[initial(icon_state)]down"
			to_chat(usr, "Вы опустили маску на шею.")

		else
			src.hanging = !src.hanging
			gas_transfer_coefficient = 0.90
			permeability_coefficient = 0.01
			flags |= MASKCOVERSMOUTH
			icon_state = "[initial(icon_state)]up"
			to_chat(user, "Вы натянули маску на лицо, закрывая его целиком.")
		update_inv_mob()
		update_item_actions()
