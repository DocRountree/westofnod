# Birds: the plan

Built so far: `scripts/creatures/bird_flight.gd` (the flight arithmetic), `tools/creatures/bird_flight_table.gd`
(prints the table below), and the near-bird tier of the rig and motors (`scripts/creatures/bird.gd`,
`shaders/render/bird_rig.gdshaderinc`, `bird.gdshader`) with its first bird, the wild turkey (`wild_turkey.gd`):
you asked for the turkey before the robin, so it was built first. Then the peregrine falcon and Cooper's hawk (`raptor.gd` and its two
species), with the stoop, the dash, soaring and perching. Not built yet: the flock tier (compute shader,
low-detail meshes), bounding, hovering, soaring, perching. This is what the first bird should be built to, so
that the second through the fiftieth are a page of numbers each.

Sized by five birds that span the range: ruby-throated hummingbird (3 g), house finch (21 g), American robin (77 g),
red-tailed hawk (1.1 kg), wild turkey (6 kg).

## The short answer

| | How many | What |
|---|---|---|
| Skeleton | **1** | One avian joint layout, 22 joints, posed in the vertex shader (as the ants are), not a `Skeleton3D` |
| Proportion sets | **4** for these five | hummingbird, perching bird (finch and robin), hawk, gamebird |
| Motors | **3** | flight, ground (hop or walk), perch; plus a head stabiliser all three share |
| Wingbeat styles | **5** | hover, steady flapping, bounding, flap-and-glide, soaring; all one stroke model with different numbers |
| Flock sim | **1** | a compute shader on the krill's pattern, feeding the same bird shader |

## One skeleton

Every bird from a hummingbird to a turkey has the same bones in the same order; only the lengths differ. So one
layout, with a table of lengths per proportion set:

| Part | Joints | Notes |
|---|---|---|
| Body | 1 | a bird's trunk is rigid: one joint |
| Neck | 4 | hummingbird and finch use 2, hawk 3, turkey 4; unused ones have zero length (herons later: raise the cap) |
| Head, lower bill | 2 | |
| Tail | 1 | the fan's spread and twist are numbers, not joints |
| Wing, each side | 3 | upper arm, forearm, hand. Elbow and wrist are linked in a real wing: one "extension" number folds both |
| Leg, each side | 4 | thigh, shin, tarsus, toes (grip is one number) |

**Feathers are not joints.** Each flight feather is a card rooted along the hand (primaries) or forearm
(secondaries), and its direction is blended in the vertex shader between "along the hand" and "back from the
forearm". That one rule makes the fan open as the wing extends and the primaries slide under the secondaries as it
folds, with no per-feather data. Body feathers are drawn by the skin's shader in overlapping rows, the way the
snail's tubercles and the mammals' coats are.

**Why in the shader, not `Skeleton3D`** (which `MammalSkin` uses): a bird has to look identical whether it is the one
robin on the lawn or one of 3,000 in a flock, and it changes between those states constantly. If the wing's linkage
lives in one shader include, the near bird and the flock bird cannot disagree. A near bird feeds it about 30 numbers
through per-instance uniforms (computed on the CPU: foot placement, head aim); a flock bird feeds it 8 packed numbers
from the compute shader and the shader derives the rest from the wingbeat's phase.

**Proportion sets** (wing bones as shares of the wing's skeleton; counts are the real ones):

| Set | Upper arm : forearm : hand | Primaries / secondaries / tail | Feet |
|---|---|---|---|
| Hummingbird | 15 : 15 : 70 (nearly all hand; the wing never folds in flight) | 10 / 6 / 10 | tiny, perch only |
| Perching bird | 30 : 36 : 34 | 9 / 9 / 12 | three forward, one back, grip |
| Hawk | 32 : 38 : 30, long and broad, outer primaries slotted | 10 / 13 / 12 | talons |
| Gamebird | 34 : 34 : 32, short, round, cupped | 10 / 18 / 18 | long walking legs, spur |

A species is then: a proportion set scaled, a bill and tail shape, a palette (about 16 feather tracts: crown, nape,
back, throat, breast, flank, wing bars..., each with a colour and a pattern: plain, streaked, barred, spotted,
scaled), one row of flight numbers, and its behaviours.

## Three motors

1. **Flight.** One motor for all five, described below.
2. **Ground.** One two-legged motor with a gait number: both feet together (hop: finch), alternating (walk and run:
   turkey), either by speed (robin: runs, stops, hops). Hummingbirds have none; hawks walk badly on purpose.
3. **Perch.** Grip a branch or wire, sidle, turn round, cling. It also owns take-off (most small birds leave the
   perch by a leg jump, the first downstroke after) and landing (flare, tail fanned, legs forward; a hawk swoops up
   to its perch to arrive stalled).

Shared by all three: **the head stabiliser**. A bird's head holds still in space while its body moves under it. This
is the walking turkey's head-bob, the hovering hummingbird's fixed head, and the robin on a swaying twig. It is the
single cheapest thing that makes a model read as a bird, so it goes in first.

Each motor answers to `pilot.gd` like every other creature.

## Flight that differs by size, from the same laws

Do not tune five flights by hand. Give each species three measurements (mass, span, wing area) and let
`BirdFlight` work out the rest:

| Bird | Wing loading N/m² | Beats/s | Slowest level flight m/s | Travelling m/s | Glide ratio | Turn radius at 30° bank m | Body heave per beat | Roll °/s |
|---|---|---|---|---|---|---|---|---|
| Hummingbird | 26 | 53 (measured; the law gives half) | hovers | 5 to 12 | 7 | 6 | none | 1,700 |
| House finch | 23 | 13 | 4.8 | 5.6 | 7 | 5 | 4 mm | 940 |
| American robin | 38 | 11 | 6.2 | 7.8 | 9 | 9 | 5 mm | 870 |
| Red-tailed hawk | 51 | 4 | 7.2 | 10.4 | 13 | 13 | 37 mm | 330 |
| Wild turkey | 147 | 6 | 12.3 | 19.8 | 10 | 46 | 18 mm | 590 |

Wing areas are my estimates and the beat rates are from Pennycuick's scaling law, good to about a fifth; check each
against footage when its bird is built. The pattern is already right: the finch flicks and the hawk leans, the hawk's
body visibly rises and falls with each beat and the finch's does not, the turkey needs a 46 m circle and must fly
fast or not at all.

**One rule that does most of the work: run the motor in wingbeats, not seconds.** Turn-in, reaction time, how fast
the bank changes: all scaled by the beat rate. Small birds then look quick and nervous and big ones stately with no
further tuning.

### The stroke (one model, five styles)

The wing's path is set by a handful of numbers, and most of them follow from how far the bird travels per beat (the
"advance ratio": 0 hovering, about 1 at travelling speed):

| Number | Slow or hovering | At speed |
|---|---|---|
| Stroke plane | near level: wings sweep fore and aft | near upright: wings beat up and down |
| Body angle | 45 to 60° nose-up | 5 to 15° |
| Sweep of the stroke | wide (hummingbird about 150°) | narrower (hawk 60 to 90°) |
| Tail | fanned and lowered | closed |

Because these blend with speed, take-off, landing and slow flight come for free from the same motor: any bird
slowing to land tips up, widens its stroke and fans its tail.

What differs by kind of bird is the **upstroke**:

- **Hummingbird:** wing stays fully extended and flips over, so the upstroke lifts too. Figure-eight tip path.
- **Small perching birds:** wing folds almost shut on the upstroke (about a third of its span), flicks open for the
  downstroke.
- **Hawk and other large birds:** wing stays mostly spread (two thirds or more), swept back a little.
- **Gamebird:** shallow, fast, stiff beats on cupped wings.

And the **rhythm** (a scheduler over the stroke):

| Style | Who | What happens |
|---|---|---|
| Hover | hummingbird | continuous, can hold still, fly backward or sideways |
| Steady flapping | robin; everything on take-off | continuous |
| Bounding | finch, most birds under about 300 g | a burst of beats, then wings shut tight and the bird is a thrown stone. `BirdFlight.bound_drop` gives the real dip: 8 cm for a quarter second shut, 30 cm for half a second. The undulating path is physics, not an animation curve |
| Flap-and-glide | hawk in transit, larger birds | a few beats, then wings held spread |
| Soaring | hawk | no beats. Needs rising air (below) |
| Burst-and-glide | turkey | explosive climb at full power for a few seconds, then a long glide on set wings; it cannot sustain flapping |

### Effects worth having, in order of how much they show

1. **Bank into turns.** Bank angle from turn rate (`bank_for`). Free, and it is what makes a wheeling flock flash
   light and dark.
2. **Wing blur.** Above about 25 beats/s the wing cannot be drawn as a wing at 60 frames a second; draw a
   translucent fan through the stroke, as the hummingbird moth already does. Between about 10 and 25 beats/s (the
   finch) there are only 3 to 5 frames per beat and the wing will strobe: blend toward the blur by beats per frame
   and jitter the phase a little.
3. **Feathers bending under load.** The outer primaries curve up on the downstroke and in a hard turn; a soaring
   hawk's slotted "fingers" stay bent up. One number per bird (load), bent in the shader along each feather.
4. **Wing twist.** Leading edge down on the downstroke, up on the upstroke, more toward the tip.
5. **Body heave** on large birds, with the head held steady against it.
6. **Soaring on real lift.** A lift field the hawk motor reads: thermals as drifting columns over sunlit open ground
   by day, and wind deflected up by slopes from the height map. With `sink_rate` the hawk then circles at the
   right radius (about 13 m), climbs when the air rises faster than 0.9 m/s, and glides between. There is no global
   wind in the game yet; this needs one.
7. **Landing gear:** alula raised and tail fanned in the flare, legs tucked in flight.
8. Later: wing sound (the hummingbird's hum is its beat rate), wing claps, iridescence on a gorget.

## Flocks on the GPU

Three tiers, one shader:

| Tier | How many | Simulated | Drawn |
|---|---|---|---|
| Near | up to about 20 around the player, or any bird doing something particular (feeding, at a nest) | CPU motor, like a deer | full mesh, about 3,000 to 5,000 triangles, every flight feather a card |
| Flock | hundreds to thousands | compute shader | `MultiMesh`, about 400 triangles: body, wing surfaces with the feather edge cut in, slots on a hawk |
| Far | the rest: distant flocks, a hawk high up | same compute shader | `MultiMesh`, 24 triangles, then a 2-triangle speck |

A bird is promoted when it lands near the player and demoted when it leaves; because both tiers use the same wing
rig the swap does not show.

**The simulation** copies what already works for the krill (`krill_swarm.glsl`): a hashed neighbour grid, each bird
steered from its neighbours, transforms written straight into the `MultiMesh` buffers, split into near and far by
distance from the camera. Differences for birds:

- **Seven nearest neighbours, not everything within a radius.** That is what real starling flocks do, and it keeps
  a flock together whether it is tight or strung out.
- **A flight model, not just boids.** Each bird's wanted direction is passed through its species' limits (speed
  range, bank, climb) and its rhythm scheduler runs per bird with its own phase, so a finch flock is a cloud of
  individually bounding birds rather than a rigid shape.
- **Ground and trees.** The compute shader samples the same height map the terrain uses; perches and roosts are
  goal points handed to it.
- **Threats.** A few threat points (a hawk, the player) that birds turn from; the turn passes neighbour to
  neighbour, which is the ripple you see cross a real flock.
- **Perched is a flock state too:** wings folded in the same shader, so a wire of 200 birds is still one draw call.

Start with the krill's read-back (one frame behind; at 5,000 birds that is about 400 KB a frame, which is fine). If
flocks ever need to be much larger, the same state can be written to a texture the bird shader reads directly and
never come back to the CPU at all; lay the state out as plain `vec4`s from the start so that move is cheap.

Per flock bird the shader gets 8 numbers: wingbeat phase, stroke strength (0 gliding, 1 flapping, negative folded),
load, a random seed and size; tail spread, legs, perched, and one spare. Everything else it derives.

## Build order

1. **American robin** first. It is the middle of the range and uses every system once: steady flapping, hop and
   run, perching, the head stabiliser. Build it as a near bird only.
2. **House finch:** same proportion set. Adds bounding flight and the flock tier.
3. **Red-tailed hawk:** adds soaring and the lift field, talons, and the flock's threat response.
4. **Hummingbird:** adds hovering and the blur; the flower logic is the hummingbird moth's.
5. **Wild turkey:** adds the walking gait in earnest, burst-and-glide, and display (strut, fanned tail).

## Open questions for you

- **Which finch?** I assumed house finch. An American goldfinch is the showier bounder.
- **Which thrush?** I assumed American robin.
- **Wind:** soaring needs a world wind direction and strength. Should that be one global value, or vary over the map?
