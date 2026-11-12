class_name BirdFlight
extends RefCounted
## The air a bird flies in, as numbers: what a bird of a given weight, span
## and wing area must do to fly (how often it beats, how slow it can go, how
## it glides, how tightly it turns), from the same few laws at every size,
## so a hummingbird and a turkey differ because their numbers do, not
## because each was tuned by hand. No bird is made here (docs/birds.md: the
## plan they'll be made to); the motors that will fly them ask this.
##
## m: its mass (kg); b: its span (m, tip to tip); s: its wings' area (m2,
## both, with the body between them). Speeds m/s, through the air.

const G := 9.81
const RHO := 1.225 ## kg/m3, the air near the ground
const CL_MAX := 1.6 ## the most lift a wing gives, slotted, flared
const CD0 := 0.03 ## its drag with no lift, on the wings' area (the body's with it): a big bird's
const K_IND := 1.15 ## how far short of a perfect wing (the drag of making lift)


## Its weight on its wings (N/m2): everything about how fast it must fly.
static func wing_loading(m: float, s: float) -> float:
	return m * G / s


## Span squared over area: long thin wings (a gull's) high, short broad
## ones (a turkey's) low.
static func aspect_ratio(b: float, s: float) -> float:
	return b * b / s


## Beats a second, flying level at its own pace (Pennycuick 1996: from its
## weight, span, area and the air; within a fifth for most birds; a
## hummingbird hovering beats about twice this: give it its own).
static func wingbeat_hz(m: float, b: float, s: float) -> float:
	return pow(m, 0.375) * sqrt(G) * pow(b, -23.0 / 24.0) * pow(s, -1.0 / 3.0) * pow(RHO, -0.375)


## The slowest it can fly level on spread wings (below this it must flap
## hard, hover if it can, or come down). n: the load on it (1 level; more
## in a turn).
static func stall_speed(m: float, s: float, n := 1.0) -> float:
	return sqrt(2.0 * n * m * G / (RHO * s * CL_MAX))


# its drag D = A v2 + B / v2 (the air pushed aside; the air pushed down)
static func _a(m: float, s: float) -> float:
	return 0.5 * RHO * s * CD0 * maxf(1.0, pow(m, -0.25)) # (a small bird's air is stickier: more drag for its size)


static func _b(m: float, b: float, n := 1.0) -> float:
	return 2.0 * K_IND * m * m * G * G * n * n / (RHO * PI * b * b)


## The speed it glides farthest at (and flaps cheapest per metre: about its
## travelling pace).
static func best_glide_speed(m: float, b: float, s: float) -> float:
	return pow(_b(m, b) / _a(m, s), 0.25)


## Metres forward for each metre down, gliding at its best.
static func glide_ratio(m: float, b: float, s: float) -> float:
	return m * G / (2.0 * sqrt(_a(m, s) * _b(m, b)))


## The speed it sinks slowest at (circling in a thermal), never below its
## stall.
static func min_sink_speed(m: float, b: float, s: float, bank := 0.0) -> float:
	var n := 1.0 / cos(bank)
	return maxf(pow(_b(m, b, n) / (3.0 * _a(m, s)), 0.25), stall_speed(m, s, n) * 1.05)


## How fast it sinks (m/s) gliding at v, banked (rad): rising air faster
## than this carries it up.
static func sink_rate(m: float, b: float, s: float, v: float, bank := 0.0) -> float:
	var n := 1.0 / cos(bank)
	return (_a(m, s) * v * v * v + _b(m, b, n) / v) / (m * G)


## The radius (m) of a level turn at v, banked.
static func turn_radius(v: float, bank: float) -> float:
	return v * v / (G * maxf(tan(bank), 1e-4))


## The bank (rad) that turns it at `rate` (rad/s) at v: wings level flying
## straight, tipped into every turn (what makes a wheeling flock flash).
static func bank_for(v: float, rate: float) -> float:
	return atan(v * rate / G)


## How far its body rises and falls each beat (m), flapping: nothing to
## see on a finch, a slow heave on a hawk. down: the share of the beat that
## is downstroke; up_lift: how much of its weight the upstroke still
## carries (none hovering on a folded upstroke; half or so at speed).
static func heave(hz: float, down := 0.5, up_lift := 0.5) -> float:
	return G * (1.0 - down) * (1.0 - up_lift) / (hz * hz * 8.0 * down)


## How fast it can roll into a turn (rad/s) at v: by its span, so a finch
## flicks over where a hawk leans.
static func roll_rate(v: float, b: float) -> float:
	return 0.7 * v / b


## Bounding (a finch's flight: a burst of beats, then its wings shut, a
## shell through the air): how far it drops below the top of each bound (m)
## for `shut` s with its wings closed; and the push up it needs while it
## flaps (m/s2) to stay level over the whole, flapping `flap` s.
static func bound_drop(shut: float) -> float:
	return G * shut * shut / 8.0


static func bound_climb(flap: float, shut: float) -> float:
	return G * shut / flap


## How far it travels in one beat, in wing lengths swept (the advance
## ratio): 0 hovering, about 1 and over at speed. What its stroke looks
## like follows this (docs/birds.md): low, the wings sweep level, fore and
## aft, the body upright; high, they beat up and down, the body level.
static func advance_ratio(v: float, hz: float, b: float, sweep := 2.0) -> float:
	return v / (2.0 * sweep * hz * b * 0.5)
