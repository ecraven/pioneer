local Color = import("Color")

local theme = {}

theme.colors = {
	reticuleCircle = Color(200, 200, 200),
	reticuleCircleDark = Color(150, 150, 150),
	frame = Color(200, 200, 200),
	frameDark = Color(120, 120, 120),
	transparent = Color(0, 0, 0, 0),
	navTarget = Color(237, 237, 112),
	navTargetDark = Color(160, 160, 50),
	combatTarget = Color(237, 112, 112),
	combatTargetDark = Color(160, 50, 50),
	-- navTarget = Color(0, 255, 0),
	-- navTargetDark = Color(0, 150, 0),
	navigationalElements = Color(200, 200, 200),
	deltaVCurrent = Color(150, 150, 150),
	deltaVManeuver = Color(168, 168, 255),
	deltaVRemaining = Color(250, 250, 250),
	deltaVTotal = Color(100, 100, 100, 200),
	brakeBackground = Color(100, 100, 100, 200),
	brakeLight = Color(200, 200, 200),
	brakeNow = Color(150, 200, 150),
	brakeOvershoot = Color(200, 150, 150),
	maneuver = Color(200, 150, 200),
	maneuverDark = Color(160, 50, 160),
}

theme.icons = {
   -- first row
   prograde = 0,
   retrograde = 1,
   radial_out = 2,
   radial_in = 3,
   antinormal = 4,
   normal = 5,
   frame = 6,
   maneuver = 7,
   forward = 8,
   backward = 9,
   down = 10,
   right = 11,
   up = 12,
   left = 13,
   bullseye = 14,
   square = 15,
   -- second row
   prograde_thin = 16,
   retrograde_thin = 17,
   radial_out_thin = 18,
   radial_in_thin = 19,
   antinormal_thin = 20,
   normal_thin = 21,
   frame_away = 22,
   direction = 24,
   direction_hollow = 25,
   direction_frame = 26,
   direction_frame_hollow = 27,
   direction_forward = 28,
   apoapsis = 29,
   periapsis = 30,
   semi_major_axis = 31,
   -- third row
   heavy_fighter = 32,
   medium_fighter = 33,
   light_fighter = 34,
   sun = 35,
   asteroid_hollow = 36,
   current_height = 37,
   current_periapsis = 38,
   current_line = 39,
   current_apoapsis = 40,
   eta = 41,
   altitude = 42,
   gravity = 43,
   eccentricity = 44,
   inclination = 45,
   longitude = 46,
   latitude = 47,
   -- fourth row
   heavy_courier = 48,
   medium_courier = 49,
   light_courier = 50,
   rocky_planet = 51,
   ship = 52, -- useless?
   landing_gear_up = 53,
   landing_gear_down = 54,
   ecm = 55,
   rotation_damping_on = 56,
   rotation_damping_off = 57,
   hyperspace = 58,
   hyperspace_off = 59,
   scanner = 60,
   message_bubble = 61,
   fuel = 63,
   -- fifth row
   heavy_passenger_shuttle = 64,
   medium_passenger_shuttle = 65,
   light_passenger_shuttle = 66,
   moon = 67,
   autopilot_set_speed = 68,
   autopilot_manual = 69,
   autopilot_fly_to = 70,
   autopilot_dock = 71,
   autopilot_hold = 72,
   autopilot_undock = 73,
   autopilot_undock_illegal = 74,
   autopilot_blastoff = 75,
   autopilot_blastoff_illegal = 76,
   autopilot_low_orbit = 77,
   autopilot_medium_orbit = 78,
   autopilot_high_orbit = 79,
   -- sixth row
   heavy_passenger_transport = 80,
   medium_passenger_transport = 81,
   light_passenger_transport = 82,
   gas_giant = 83,
   time_accel_stop = 84,
   time_accel_paused = 85,
   time_accel_1x = 86,
   time_accel_10x = 87,
   time_accel_100x = 88,
   time_accel_1000x = 89,
   time_accel_10000x = 90,
   pressure = 91,
   shield = 92,
   hull = 93,
   temperature = 94,
   -- seventh row
   heavy_cargo_shuttle = 96,
   medium_cargo_shuttle = 97,
   light_cargo_shuttle = 98,
   spacestation = 99,
   time_backward_100x = 100,
   time_backward_10x = 101,
   time_backward_1x = 102,
   time_center = 103,
   time_forward_1x = 104,
   time_forward_10x = 105,
   time_forward_100x = 106,
   filter_bodies = 107,
   filter_stations = 108,
   filter_ships = 109,
   -- eighth row
   heavy_freighter = 112,
   medium_freighter = 113,
   light_freighter = 114,
   starport = 115,
   -- ninth row
   view_internal = 128,
   view_external = 129,
   view_sidereal = 130,
   comms = 131,
   market = 132,
   bbs = 133,
   equipment = 134,
   repairs = 135,
   info = 136,
   personal_info = 137,
   personal = 138,
   rooster = 139,
   map = 140,
   sector_map = 141,
   system_map = 142,
   system_overview = 143,
   -- tenth row
   galaxy_map = 144,
   settings = 145,
   language = 146,
   controls = 147,
   sound = 148,
   new = 149,
   skull = 150,
   mute = 151,
   unmute = 152,
   music = 153,
   zoom_in = 154,
   zoom_out = 155,
   search_lens = 156,
   message = 157,
   message_open = 158,
   search_binoculars = 159,
   -- eleventh row
   planet_grid = 160,
   bookmarks = 161,
   unlocked = 162,
   locked = 163,
   label = 165,
   broadcast = 166,
   shield_other = 167,
   hud = 168,
   factory = 169,
   star = 170,
   -- TODO: manual / autopilot
	 -- dummy, until actually defined correctly
	 mouse_move_direction = 14
}

return theme
