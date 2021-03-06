
// Called when the item is in the active hand, and clicked; alternately, there is an 'activate held object' verb or you can hit pagedown.
/obj/item/proc/attack_self(mob/user)
	return

// No comment
/atom/proc/attackby(obj/item/W, mob/user, params)
	return
/atom/movable/attackby(obj/item/W, mob/user, params)
	user.do_attack_animation(src)
	if(W && !(W.flags&NOBLUDGEON))
		visible_message("<span class='danger'>[src] has been hit by [user] with [W].</span>")

/mob/living/attackby(obj/item/I, mob/user, params)
	if(istype(I) && ismob(user))
		I.attack(src, user)

		if(ishuman(user))	//When abductor will hit someone from stelth he will reveal himself
			var/mob/living/carbon/human/H = user
			if(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit/armor/abductor/vest))
				for(var/obj/item/clothing/suit/armor/abductor/vest/V in list(H.wear_suit))
					if(V.stealth_active)
						V.DeactivateStealth()

		if(butcher_results && stat == DEAD)
			if(buckled && istype(buckled, /obj/structure/kitchenspike))
				var/sharpness = is_sharp(I)
				if(sharpness)
					to_chat(user, "<span class='notice'>You begin to butcher [src]...</span>")
					playsound(loc, 'sound/weapons/slice.ogg', 50, 1, -1)
					if(do_mob(user, src, 80/sharpness))
						harvest(user)

// Proximity_flag is 1 if this afterattack was called on something adjacent, in your square, or on your person.
// Click parameters is the params string from byond Click() code, see that documentation.
/obj/item/proc/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	return


/obj/item/proc/attack(mob/living/M, mob/living/user, def_zone)

	if (!istype(M)) // not sure if this is the right thing...
		return 0
	var/messagesource = M
	if (can_operate(M))        //Checks if mob is lying down on table for surgery
		if (do_surgery(M,user,src))
			return 0

	// Knifing
	if(edge)
		for(var/obj/item/weapon/grab/G in M.grabbed_by)
			if(G.assailant == user && G.state >= GRAB_NECK && world.time >= (G.last_action + 20) && user.zone_sel.selecting == "head")
				var/protected = 0
				if(ishuman(M))
					var/mob/living/carbon/human/AH = M
					if(AH.is_in_space_suit())
						protected = 1
				if(!protected)
					//TODO: better alternative for applying damage multiple times? Nice knifing sound?
					M.apply_damage(20, BRUTE, "head", 0, sharp=sharp, edge=edge)
					M.apply_damage(20, BRUTE, "head", 0, sharp=sharp, edge=edge)
					M.apply_damage(20, BRUTE, "head", 0, sharp=sharp, edge=edge)
					M.adjustOxyLoss(60) // Brain lacks oxygen immediately, pass out
					playsound(loc, 'sound/effects/throat_cutting.ogg', 50, 1, 1)
					flick(G.hud.icon_state, G.hud)
					G.last_action = world.time
					user.visible_message("<span class='danger'>[user] slit [M]'s throat open with \the [name]!</span>")
					user.attack_log += "\[[time_stamp()]\]<font color='red'> Knifed [M.name] ([M.ckey]) with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])</font>"
					M.attack_log += "\[[time_stamp()]\]<font color='orange'> Got knifed by [user.name] ([user.ckey]) with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])</font>"
					msg_admin_attack("[key_name(user)] knifed [key_name(M)] with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])" )
					return

	if (istype(M,/mob/living/carbon/brain))
		messagesource = M:container
	if (hitsound)
		playsound(loc, hitsound, 50, 1, -1)
	/////////////////////////
	user.lastattacked = M
	M.lastattacker = user
	user.do_attack_animation(M)

	user.attack_log += "\[[time_stamp()]\]<font color='red'> Attacked [M.name] ([M.ckey]) with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])</font>"
	M.attack_log += "\[[time_stamp()]\]<font color='orange'> Attacked by [user.name] ([user.ckey]) with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)])</font>"
	msg_admin_attack("[key_name(user)] attacked [key_name(M)] with [name] (INTENT: [uppertext(user.a_intent)]) (DAMTYE: [uppertext(damtype)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)" )

	//spawn(1800)            // this wont work right
	//	M.lastattacker = null
	/////////////////////////

	var/power = force
	if(HULK in user.mutations)
		power *= 2

	if(!istype(M, /mob/living/carbon/human))
		if(istype(M, /mob/living/carbon/slime))
			var/mob/living/carbon/slime/slime = M
			if(prob(25))
				to_chat(user, "\red [src] passes right through [M]!")
				return

			if(power > 0)
				slime.attacked += 10

			if(slime.Discipline && prob(50))	// wow, buddy, why am I getting attacked??
				slime.Discipline = 0

			if(power >= 3)
				if(istype(slime, /mob/living/carbon/slime/adult))
					if(prob(5 + round(power/2)))

						if(slime.Victim)
							if(prob(80) && !slime.client)
								slime.Discipline++
						slime.Victim = null
						slime.anchored = 0

						spawn()
							if(slime)
								slime.SStun = 1
								sleep(rand(5,20))
								if(slime)
									slime.SStun = 0

						spawn(0)
							if(slime)
								slime.canmove = 0
								step_away(slime, user)
								if(prob(25 + power))
									sleep(2)
									if(slime && user)
										step_away(slime, user)
								slime.canmove = 1

				else
					if(prob(10 + power*2))
						if(slime)
							if(slime.Victim)
								if(prob(80) && !slime.client)
									slime.Discipline++

									if(slime.Discipline == 1)
										slime.attacked = 0

								spawn()
									if(slime)
										slime.SStun = 1
										sleep(rand(5,20))
										if(slime)
											slime.SStun = 0

							slime.Victim = null
							slime.anchored = 0


						spawn(0)
							if(slime && user)
								step_away(slime, user)
								slime.canmove = 0
								if(prob(25 + power*4))
									sleep(2)
									if(slime && user)
										step_away(slime, user)
								slime.canmove = 1


		var/showname = "."
		if(user)
			showname = " by [user]."
		if(!(user in viewers(M, null)))
			showname = "."

		for(var/mob/O in viewers(messagesource, null))
			if(attack_verb.len)
				O.show_message("\red <B>[M] has been [pick(attack_verb)] with [src][showname] </B>", 1)
			else
				O.show_message("\red <B>[M] has been attacked with [src][showname] </B>", 1)

		if(!showname && user)
			if(user.client)
				to_chat(user, "\red <B>You attack [M] with [src]. </B>")



	if(istype(M, /mob/living/carbon/human))
		return M:attacked_by(src, user, def_zone)	//make sure to return whether we have hit or miss
	else
		switch(damtype)
			if("brute")
				if(istype(src, /mob/living/carbon/slime))
					M.adjustBrainLoss(power)

				else

					M.take_organ_damage(power)
					if (prob(33)) // Added blood for whacking non-humans too
						var/turf/location = M.loc
						if (istype(location, /turf/simulated))
							location:add_blood_floor(M)
			if("fire")
				if (!(COLD_RESISTANCE in M.mutations))
					M.take_organ_damage(0, power)
					to_chat(M, "Aargh it burns!")
		M.updatehealth()
	add_fingerprint(user)
	return 1
