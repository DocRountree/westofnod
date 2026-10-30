#[compute]
#version 450

// Hydraulic and thermal erosion on a regular grid: the "virtual pipes" shallow
// water model with sediment transport (Mei, Decaudin & Hu 2007), plus pairwise
// thermal slumping. Runs after the stream power landscape has set the relief;
// this is what carves gullies, builds alluvial fans, and drops sediment where
// rivers meet the sea (deltas). Cells at or below sea level hold water up to
// sea level: they are the sink every drainage basin empties into.
//
//   stage 0  FLUX       outflow through the four pipes, scaled so a cell
//                       never sends more water than it has
//   stage 1  WATER      depth from the net flux, rain, evaporation; velocity
//   stage 2  EROSION    transport capacity ~ slope x speed; erode below it,
//                       deposit above it. Terrain B[0] -> B[1], sediment S[1] -> S[0]
//   stage 3  ADVECT     sediment carried back along the velocity, S[0] -> S[1]
//   stage 4  THERMAL    material above the talus angle slides to lower
//                       neighbours (pairwise, so it is conserved), B[1] -> B[0]

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer Terr { float v[]; } B;  // 2N: two halves
layout(set = 0, binding = 1, std430) restrict buffer Water { float v[]; } D; // N
layout(set = 0, binding = 2, std430) restrict buffer Sed { float v[]; } S;   // 2N
layout(set = 0, binding = 3, std430) restrict buffer Flux { vec4 v[]; } F;   // N: +x, -x, +z, -z
layout(set = 0, binding = 4, std430) restrict buffer Vel { vec2 v[]; } V;    // N
layout(set = 0, binding = 5, std430) restrict readonly buffer Rain { float v[]; } R; // N: rain rate

layout(push_constant, std430) uniform Params {
	int stage;
	int n;
	float dt;
	float l;         // cell size (m)
	float kc;        // sediment capacity
	float ks;        // dissolving rate
	float kd;        // deposition rate
	float ke;        // evaporation rate
	float talus;     // thermal: max stable slope
	float kt;        // thermal: rate
	float pad0;
	float pad1;
} pc;

const float G = 9.81;

int idx(ivec2 c) {
	c = clamp(c, ivec2(0), ivec2(pc.n - 1));
	return c.y * pc.n + c.x;
}

float b0(ivec2 c) { return B.v[idx(c)]; }
float b1(ivec2 c) { return B.v[pc.n * pc.n + idx(c)]; }

void main() {
	ivec2 c = ivec2(gl_GlobalInvocationID.xy);
	if (c.x >= pc.n || c.y >= pc.n) return;
	int i = idx(c);
	int N = pc.n * pc.n;
	bool edge = c.x == 0 || c.y == 0 || c.x == pc.n - 1 || c.y == pc.n - 1;

	if (pc.stage == 0) {
		float h = b0(c) + D.v[i];
		const ivec2 o[4] = ivec2[](ivec2(1, 0), ivec2(-1, 0), ivec2(0, 1), ivec2(0, -1));
		vec4 f = F.v[i];
		vec4 nf;
		for (int k = 0; k < 4; k++) {
			ivec2 nc = c + o[k];
			float hn = b0(nc) + D.v[idx(nc)];
			nf[k] = max(0.0, f[k] + pc.dt * G * pc.l * (h - hn)); // pipe area l^2, length l
		}
		float sum = nf.x + nf.y + nf.z + nf.w;
		float k = sum > 0.0 ? min(1.0, D.v[i] * pc.l * pc.l / (sum * pc.dt)) : 0.0;
		F.v[i] = edge ? vec4(0.0) : nf * k;
		return;
	}

	if (pc.stage == 1) {
		vec4 f = F.v[i];
		float fin_l = F.v[idx(c + ivec2(-1, 0))].x; // left neighbour's +x
		float fin_r = F.v[idx(c + ivec2(1, 0))].y;  // right neighbour's -x
		float fin_d = F.v[idx(c + ivec2(0, -1))].z;
		float fin_u = F.v[idx(c + ivec2(0, 1))].w;
		float inflow = fin_l + fin_r + fin_d + fin_u;
		float outflow = f.x + f.y + f.z + f.w;
		float d0 = D.v[i];
		float d1 = max(d0 + pc.dt * (R.v[i] + (inflow - outflow) / (pc.l * pc.l)), 0.0);
		d1 *= 1.0 - pc.ke * pc.dt;
		float b = b0(c);
		if (b <= 0.0 || edge) {
			// The sea: water stands at sea level, still.
			D.v[i] = max(-b, 0.0);
			V.v[i] = vec2(0.0);
			return;
		}
		float dm = max(0.5 * (d0 + d1), 1e-3);
		float wx = 0.5 * (fin_l - f.y + f.x - fin_r);
		float wz = 0.5 * (fin_d - f.w + f.z - fin_u);
		vec2 vel = vec2(wx, wz) / (pc.l * dm);
		float sp = length(vel);
		if (sp > 12.0) vel *= 12.0 / sp;
		D.v[i] = d1;
		V.v[i] = vel;
		return;
	}

	if (pc.stage == 2) {
		float b = b0(c);
		vec2 g = vec2(b0(c + ivec2(1, 0)) - b0(c - ivec2(1, 0)), b0(c + ivec2(0, 1)) - b0(c - ivec2(0, 1))) / (2.0 * pc.l);
		float sin_a = length(g) / sqrt(1.0 + dot(g, g));
		float d = D.v[i];
		// Capacity grows with slope and speed, and fades in very shallow film flow
		// so rain alone doesn't strip the hillsides.
		float cap = pc.kc * max(sin_a, 0.02) * length(V.v[i]) * smoothstep(0.0, 0.2, d);
		float s = S.v[N + i];
		if (s < cap) {
			float e = min(pc.ks * (cap - s) * pc.dt, 0.5); // at most half a metre per step
			b -= e;
			s += e;
		} else {
			float dep = pc.kd * (s - cap) * pc.dt;
			b += dep;
			s -= dep;
		}
		B.v[N + i] = b;
		S.v[i] = s;
		return;
	}

	if (pc.stage == 3) {
		vec2 p = vec2(c) - V.v[i] * pc.dt / pc.l;
		p = clamp(p, vec2(0.0), vec2(pc.n - 1));
		ivec2 q = ivec2(floor(p));
		vec2 f = p - vec2(q);
		float a = S.v[idx(q)];
		float bb = S.v[idx(q + ivec2(1, 0))];
		float cc = S.v[idx(q + ivec2(0, 1))];
		float dd = S.v[idx(q + ivec2(1, 1))];
		S.v[N + i] = edge ? 0.0 : mix(mix(a, bb, f.x), mix(cc, dd, f.x), f.y);
		return;
	}

	if (pc.stage == 4) {
		float b = b1(c);
		float delta = 0.0;
		const ivec2 o[8] = ivec2[](ivec2(1, 0), ivec2(-1, 0), ivec2(0, 1), ivec2(0, -1),
				ivec2(1, 1), ivec2(-1, -1), ivec2(1, -1), ivec2(-1, 1));
		for (int k = 0; k < 8; k++) {
			float dist = k < 4 ? pc.l : pc.l * 1.41421356;
			float dh = b - b1(c + o[k]);
			float excess = abs(dh) - pc.talus * dist;
			if (excess > 0.0) {
				delta -= sign(dh) * excess * pc.kt * 0.0625; // pairwise, symmetric
			}
		}
		B.v[i] = b + delta;
		return;
	}
}
