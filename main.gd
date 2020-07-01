extends Control

var main_timer = Timer.new()

enum {
	HAPPY_LIFE, HAPPY_WEEK, HAPPY_DAY, HAPPY_NOW,
	PHYSICAL, ENERGY, COMFORT, HUNGER, HYGIENE, BLADDER,
	MENTAL, ALERTNESS, STRESS, ENVIRONMENT, SOCIAL, ENTERTAINED
}

var rng = RandomNumberGenerator.new()

var motive_state = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var old_motive_state = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

var timer_update_seconds = 1
var clock_speed = 120 # amount of seconds increased per timer_update_seconds
var clock_epoch = 0

const DAYTICKS = 720
const WEEKTICKS = 5040

func srand(upper):
	#rng.set_seed(_seed)
	rng.randomize()
	return randi() % (upper + 1)

# https://www.reddit.com/r/godot/comments/ecd4xc/how_do_i_get_a_node_in_a_path_independent_way/
func setup_motive_state_init():
	motive_state[ENERGY] = 70
	motive_state[ALERTNESS] = 20
	motive_state[HUNGER] = -40

func clear_motive_state():
	for i in range(motive_state.size()):
		#print(motive[i])
		motive_state[i] = 0

func _simulate_frame():
	# energy
	if self.motive_state[ENERGY] > 0:
		if self.motive_state[ALERTNESS] > 0:
			self.motive_state[ENERGY] -= self.motive_state[ALERTNESS] / 100
		else:
			self.motive_state[ENERGY] -= (self.motive_state[ALERTNESS] / 100) * ((100 - self.motive_state[ENERGY]) / 50)
	else:
		if self.motive_state[ALERTNESS] > 0:
			self.motive_state[ENERGY] -= (self.motive_state[ALERTNESS] / 100) * ((100 + self.motive_state[ENERGY]) / 50)
		else:
			self.motive_state[ENERGY] -= self.motive_state[ALERTNESS] / 100
	# - i had some food
	if self.motive_state[HUNGER] > self.old_motive_state[HUNGER]:
		self.motive_state[ENERGY] += ((self.motive_state[HUNGER] - self.old_motive_state[HUNGER]) / 4)

	# comfort
	if self.motive_state[BLADDER] < 0:
		self.motive_state[COMFORT] += self.motive_state[BLADDER] / 10
		
	if self.motive_state[HYGIENE] < 0:
		self.motive_state[COMFORT] += self.motive_state[HYGIENE] / 20
		
	if self.motive_state[HUNGER] < 0:
		self.motive_state[COMFORT] += self.motive_state[HUNGER] / 10
	
	self.motive_state[COMFORT] -= (self.motive_state[COMFORT] * self.motive_state[COMFORT] * self.motive_state[COMFORT]) / 10000
	
	# hunger
	var hunger_step = ((self.motive_state[ALERTNESS] + 100)/200) * ((self.motive_state[HUNGER] + 100)/100)
	self.motive_state[HUNGER] -= hunger_step
	
	if self.motive_state[STRESS] < 0:
		self.motive_state[HUNGER] += (self.motive_state[STRESS] / 100) * ((self.motive_state[HUNGER] + 100)/100)
	
	if self.motive_state[HUNGER] < -99:
		OS.alert("You have starved to death!", "Hunger")
		self.motive_state[HUNGER] = 80

	# hygiene
	if self.motive_state[ALERTNESS] > 0:
		self.motive_state[HYGIENE] -= .3
	else:
		self.motive_state[HYGIENE] -= .1

	if self.motive_state[HYGIENE] < -97:
		OS.alert("You smell very bad, mandatory bath", "Hygiene")
		self.motive_state[HYGIENE] = 80

	# bladder
	if self.motive_state[ALERTNESS] > 0:
		self.motive_state[BLADDER] -= .4
	else:
		self.motive_state[BLADDER] -= .2
	if self.motive_state[HUNGER] > self.old_motive_state[HUNGER]:
		self.motive_state[BLADDER] -= (self.motive_state[HUNGER] - self.old_motive_state[HUNGER]) / 4
	if self.motive_state[BLADDER] < -97:
		if self.motive_state[ALERTNESS] < 0:
			OS.alert("You have wet your bed", "Bladder")
		else:
			OS.alert("You have soiled the carpet", "Bladder")
		self.motive_state[BLADDER] = 90
	
	# alertness
	var alerttem = 0
	if self.motive_state[ALERTNESS] > 0:
		alerttem = (100 - self.motive_state[ALERTNESS]) / 50
	else:
		alerttem = (self.motive_state[ALERTNESS] + 100) / 50
	
	if self.motive_state[ENERGY] > 0:
		if self.motive_state[ALERTNESS] > 0:
			self.motive_state[ALERTNESS] += (self.motive_state[ENERGY] / 100) * alerttem
		else:
			self.motive_state[ALERTNESS] += (self.motive_state[ENERGY] / 100)
	else:
		if self.motive_state[ALERTNESS] > 0:
			self.motive_state[ALERTNESS] += (self.motive_state[ENERGY] / 100)
		else:
			self.motive_state[ALERTNESS] += (self.motive_state[ENERGY] / 100) * alerttem

	self.motive_state[ALERTNESS] += (self.motive_state[ENTERTAINED] / 300) * alerttem
	
	if self.motive_state[BLADDER] < -50:
		self.motive_state[ALERTNESS] -= (self.motive_state[BLADDER] / 100) * alerttem
		
	# stress
	self.motive_state[STRESS] += self.motive_state[COMFORT] / 10
	self.motive_state[STRESS] += self.motive_state[ENTERTAINED] / 10
	self.motive_state[STRESS] += self.motive_state[ENVIRONMENT] / 15
	self.motive_state[STRESS] += self.motive_state[SOCIAL] / 20
	
	if self.motive_state[ALERTNESS] < 0:
		self.motive_state[STRESS] = self.motive_state[STRESS] / 3
	
	self.motive_state[STRESS] -= (self.motive_state[STRESS] * self.motive_state[STRESS] * self.motive_state[STRESS]) / 10000
	
	if self.motive_state[STRESS] < 0:
		if (srand(30) - 100) > self.motive_state[STRESS]:
			if (srand(30) - 100) > self.motive_state[STRESS]:
				OS.alert("You have lost your temper", "Stress")
				self.motive_state[STRESS] = 20
	
	# environment
	# social
	# enterained
	if self.motive_state[ALERTNESS] < 0:
		self.motive_state[ENTERTAINED] = self.motive_state[ENTERTAINED] / 2
		
	# physical
	var physical_temp = 0
	physical_temp = self.motive_state[ENERGY]
	physical_temp = self.motive_state[COMFORT]
	physical_temp = self.motive_state[HUNGER]
	physical_temp = self.motive_state[HYGIENE]
	physical_temp = self.motive_state[BLADDER]
	physical_temp = physical_temp / 5
	
	if physical_temp > 0:
		physical_temp = 100 - physical_temp
		physical_temp = (physical_temp * physical_temp) / 100
		physical_temp = 100 - physical_temp
	else:
		physical_temp = 100 + physical_temp
		physical_temp = (physical_temp * physical_temp) / 100
		physical_temp = physical_temp - 100

	self.motive_state[PHYSICAL] = physical_temp
	
	# mental
	var mental_temp = 0
	mental_temp = self.motive_state[STRESS]
	mental_temp = self.motive_state[STRESS]
	mental_temp = self.motive_state[ENVIRONMENT]
	mental_temp = self.motive_state[SOCIAL]
	mental_temp = self.motive_state[ENTERTAINED]
	mental_temp = mental_temp / 5
	
	if mental_temp > 0:
		mental_temp = 100 - mental_temp
		mental_temp = (mental_temp * mental_temp) / 100
		mental_temp = 100 - mental_temp
	else:
		mental_temp = 100 + mental_temp
		mental_temp = (mental_temp * mental_temp) / 100
		mental_temp = mental_temp - 100

	self.motive_state[MENTAL] = physical_temp
	
	# happiness
	self.motive_state[HAPPY_NOW] = (self.motive_state[PHYSICAL] + self.motive_state[MENTAL]) / 2
	self.motive_state[HAPPY_DAY] =  ((self.motive_state[HAPPY_DAY] * (DAYTICKS - 1)) + self.motive_state[HAPPY_NOW]) / DAYTICKS
	self.motive_state[HAPPY_WEEK] = ((self.motive_state[HAPPY_WEEK] * (WEEKTICKS - 1)) + self.motive_state[HAPPY_NOW]) / WEEKTICKS
	self.motive_state[HAPPY_LIFE] = ((self.motive_state[HAPPY_LIFE] * 9) + self.motive_state[HAPPY_WEEK]) / 10 
	
	# check for over/under
	for _x in range(0, 16):
		if self.motive_state[_x] > 100:
			self.motive_state[_x] = 100
		if self.motive_state[_x] < -100:
			self.motive_state[_x] = -100
		self.old_motive_state[_x] = self.motive_state[_x]

func simulate_motives():
	# manage clock
	self.clock_epoch += (self.clock_speed)
	if self.clock_speed == 0:
		return
	
	# perform simulation
	var minutes_passed = int(floor((self.clock_speed / 60) / 2))
	for _x in range(0, minutes_passed):
		# print(x)
		_simulate_frame()

func update_simulation_inputs():
	self.clock_speed = find_node("SpeedHSlider").value

func update_clock_display():
	var days_elapsed = int(floor(self.clock_epoch / 86400)) # 86400 == seconds in a day
	var seconds_today = self.clock_epoch - (days_elapsed * 86400)
	var minutes_today = seconds_today / 60
	
	find_node("DebugTimeLabel").text = "Active @ epoch: %d; day: %d; second: %d" % [self.clock_epoch, days_elapsed, seconds_today]
	
	var display_hours_today = int(floor(minutes_today / 60))
	var display_minutes_today = minutes_today - (display_hours_today * 60)

	if display_hours_today > 11:
		find_node("TimeDesignationLabel").text = "PM"
		if display_hours_today > 12:
			display_hours_today = display_hours_today - 12
	else:
		find_node("TimeDesignationLabel").text = "AM"
		if display_hours_today == 0:
			display_hours_today = 12

	if display_minutes_today < 10:
		find_node("MinuteLabelValue").text = "0%d" % display_minutes_today
	else:
		find_node("MinuteLabelValue").text = "%d" % display_minutes_today

	find_node("HourLabelValue").text = str(display_hours_today)

func _ready():
	#setup initial motive state
	setup_motive_state_init()
	
	# draw first UI update manually outside of timer or events
	update_simulation_inputs()
	update_clock_display()
	update_display()
	_on_SpeedHSlider_value_changed(find_node("SpeedHSlider").value)
	
	# setup main game timer
	self.main_timer.set_wait_time(self.timer_update_seconds)
	self.main_timer.connect("timeout", self, "_on_main_timer_timeout")
	add_child(main_timer)
	self.main_timer.start()

func update_display():
	find_node("EnergyProgressBar").value = motive_state[ENERGY]
	find_node("AlertnessProgressBar").value = motive_state[ALERTNESS]
	find_node("HungerProgressBar").value = motive_state[HUNGER]
	find_node("ComfortProgressBar").value = motive_state[COMFORT]
	find_node("StressProgressBar").value = motive_state[STRESS]
	find_node("HappyLifeProgressBar").value = motive_state[HAPPY_LIFE]
	find_node("HappyNowProgressBar").value = motive_state[HAPPY_NOW]
	find_node("HappyWeekProgressBar").value = motive_state[HAPPY_WEEK]
	find_node("HappyDayProgressBar").value = motive_state[HAPPY_DAY]
	find_node("PhysicalProgressBar").value = motive_state[PHYSICAL]
	find_node("EnvironmentProgressBar").value = motive_state[ENVIRONMENT]
	find_node("EntertainedProgressBar").value = motive_state[ENTERTAINED]
	find_node("SocialProgressBar").value = motive_state[SOCIAL]
	find_node("BladderProgressBar").value = motive_state[BLADDER]
	find_node("HygieneProgressBar").value = motive_state[HYGIENE]
	find_node("MentalProgressBar").value = motive_state[MENTAL]
	
func _on_main_timer_timeout():
	update_simulation_inputs()
	update_clock_display()
	simulate_motives()
	update_display()
	
func _on_SpeedHSlider_value_changed(value):
	find_node("SpeedLabelValue").text = str(value)
