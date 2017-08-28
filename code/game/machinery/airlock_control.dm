#define AIRLOCK_CONTROL_RANGE 5

// This code allows for airlocks to be controlled externally by setting an id_tag and comm frequency (disables ID access)
/obj/machinery/door/airlock
	var/id_tag
	var/suppres_next_status_send = FALSE


/obj/machinery/door/airlock/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption) return

	if(id_tag != signal.data["tag"] || !signal.data["command"]) return

	switch(signal.data["command"])
		if("open")
			suppres_next_status_send = TRUE
			open()

		if("close")
			suppres_next_status_send = TRUE
			close()

		if("unlock")
			unbolt()

		if("lock")
			bolt()

		if("secure_open")

			unbolt()

			sleep(2)
			suppres_next_status_send = TRUE
			open()

			bolt()

		if("secure_close")
			unbolt()

			sleep(2)
			suppres_next_status_send = TRUE
			close()

			bolt()

	send_status()

/obj/machinery/door/airlock/proc/send_status_if_allowed()
	if(suppres_next_status_send)
		suppres_next_status_send = FALSE
	else
		send_status()

/obj/machinery/door/airlock/proc/send_status()
	if(radio_connection)
		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.data["tag"] = id_tag
		signal.data["timestamp"] = world.time

		signal.data["door_status"] = density?("closed"):("open")
		signal.data["lock_status"] = locked?("locked"):("unlocked")

		radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)

/obj/machinery/door/airlock/Bumped(atom/AM)
	if(ishuman(AM) && prob(40) && src.density)
		var/mob/living/carbon/human/H = AM
		if(H.getBrainLoss() >= 60)
			playsound(src.loc, 'sound/effects/bang.ogg', 25, 1)
			if(!istype(H.head, /obj/item/clothing/head/helmet))
				visible_message("\red [H] headbutts the airlock.")
				var/obj/item/organ/external/BP = H.bodyparts_by_name[BP_HEAD]
				H.Stun(8)
				H.Weaken(5)
				BP.take_damage(10, 0)
			else
				visible_message("\red [H] headbutts the airlock. Good thing they're wearing a helmet.")
				H.Stun(8)
				H.Weaken(5)
			return
	..(AM)
	if(istype(AM, /obj/mecha))
		var/obj/mecha/mecha = AM
		if(density && radio_connection && mecha.occupant && (src.allowed(mecha.occupant) || src.check_access_list(mecha.operation_req_access)))
			var/datum/signal/signal = new
			signal.transmission_method = 1 //radio signal
			signal.data["tag"] = id_tag
			signal.data["timestamp"] = world.time

			signal.data["door_status"] = density?("closed"):("open")
			signal.data["lock_status"] = locked?("locked"):("unlocked")

			signal.data["bumped_with_access"] = 1

			radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)
	return

/obj/machinery/door/airlock/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	if(new_frequency)
		frequency = new_frequency
		radio_connection = radio_controller.add_object(src, frequency, RADIO_AIRLOCK)


/obj/machinery/door/airlock/initialize()
	if(frequency)
		set_frequency(frequency)

	update_icon()


/obj/machinery/door/airlock/New()
	..()

	if(radio_controller)
		set_frequency(frequency)

/obj/machinery/door/airlock/Destroy()
	if(frequency && radio_controller)
		radio_controller.remove_object(src,frequency)
	return ..()

/obj/machinery/airlock_sensor
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_sensor_off"
	name = "airlock sensor"

	anchored = 1
	power_channel = ENVIRON
	ghost_must_be_admin = TRUE

	var/id_tag
	var/master_tag
	frequency = 1379
	var/command = "cycle"


	var/on = 1
	var/alert = 0
	var/previousPressure

/obj/machinery/airlock_sensor/update_icon()
	if(on)
		if(alert)
			icon_state = "airlock_sensor_alert"
		else
			icon_state = "airlock_sensor_standby"
	else
		icon_state = "airlock_sensor_off"

/obj/machinery/airlock_sensor/attack_hand(mob/user)
	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.data["tag"] = master_tag
	signal.data["command"] = command

	radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)
	flick("airlock_sensor_cycle", src)

/obj/machinery/airlock_sensor/process()
	if(on)
		var/datum/gas_mixture/air_sample = return_air()
		var/pressure = round(air_sample.return_pressure(),0.1)

		if(abs(pressure - previousPressure) > 0.001 || previousPressure == null)
			var/datum/signal/signal = new
			signal.transmission_method = 1 //radio signal
			signal.data["tag"] = id_tag
			signal.data["timestamp"] = world.time
			signal.data["pressure"] = num2text(pressure)

			radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)

			previousPressure = pressure

			alert = (pressure < ONE_ATMOSPHERE*0.8)

			update_icon()

/obj/machinery/airlock_sensor/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = radio_controller.add_object(src, frequency, RADIO_AIRLOCK)

/obj/machinery/airlock_sensor/initialize()
	set_frequency(frequency)

/obj/machinery/airlock_sensor/New()
	..()
	if(radio_controller)
		set_frequency(frequency)

/obj/machinery/airlock_sensor/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src,frequency)
	return ..()

/obj/machinery/airlock_sensor/airlock_interior
	command = "cycle_interior"

/obj/machinery/airlock_sensor/airlock_exterior
	command = "cycle_exterior"

/obj/machinery/access_button
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "access_button_standby"
	name = "access button"

	layer = 3.3	//Above windows
	anchored = TRUE
	power_channel = ENVIRON
	ghost_must_be_admin = TRUE

	var/master_tag
	frequency = 1449
	var/command = "cycle"

	var/on = TRUE


/obj/machinery/access_button/update_icon()
	if(on)
		icon_state = "access_button_standby"
	else
		icon_state = "access_button_off"

/obj/machinery/access_button/attack_hand(mob/user)
	add_fingerprint(usr)
	if(!allowed(user))
		to_chat(user, "\red Access Denied")

	else if(radio_connection)
		var/datum/signal/signal = new
		signal.transmission_method = 1 //radio signal
		signal.data["tag"] = master_tag
		signal.data["command"] = command

		radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)
	flick("access_button_cycle", src)


/obj/machinery/access_button/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency, RADIO_AIRLOCK)


/obj/machinery/access_button/initialize()
	set_frequency(frequency)


/obj/machinery/access_button/New()
	..()

	if(radio_controller)
		set_frequency(frequency)

/obj/machinery/access_button/Destroy()
	if(radio_controller)
		radio_controller.remove_object(src, frequency)
	return ..()

/obj/machinery/access_button/airlock_interior
	frequency = 1379
	command = "cycle_interior"

/obj/machinery/access_button/airlock_exterior
	frequency = 1379
	command = "cycle_exterior"
