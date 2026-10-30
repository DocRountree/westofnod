#[compute]
#version 450

// Landscape evolution for one island: tectonic uplift against fluvial incision
// (the stream power law, E = K A^m S^n with m = 0.5, n = 1) plus hillslope
// diffusion, iterated to near steady state. The river network and drainage
// basins are not drawn by hand: they emerge from this simulation.
//
// After Schott et al. 2023, "Large-scale terrain authoring through interactive
// erosion simulation": each iteration is two fully parallel passes.
//   stage 0  ERODE       semi-implicit stream power step toward the downslope
//                        neighbours, diffusion, talus cap; pits are raised to
//                        their lowest neighbour so depressions fill and spill.
//                        Also stores the multiple-flow-direction weights.
//   stage 1  ACCUMULATE  drainage area = own cell + weighted inflow from the
//                        neighbours. One Jacobi step per iteration: area
//                        propagates one cell downstream per iteration and
//                        converges along with the terrain.
// Ocean cells (uplift < 0) are fixed at sea level and swallow all flow.

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer H0 { float v[]; } h0;
layout(set = 0, binding = 1, std430) restrict buffer H1 { float v[]; } h1;
layout(set = 0, binding = 2, std430) restrict buffer A0 { float v[]; } a0;
layout(set = 0, binding = 3, std430) restrict buffer A1 { float v[]; } a1;
layout(set = 0, binding = 4, std430) restrict readonly buffer Up { float v[]; } up;
layout(set = 0, binding = 5, std430) restrict buffer Wt { float v[]; } wt; // 8 per cell

layout(push_constant, std430) uniform Params {
	int stage;
	int n;
	int parity; // read buffers [parity], write [1 - parity]
	float dt;
	float dx;
	float kd;     // hillslope diffusivity
	float talus;  // max slope
	float p_mfd;  // flow concentration exponent
} pc;

const ivec2 OFF[8] = ivec2[](ivec2(1, 0), ivec2(1, 1), ivec2(0, 1), ivec2(-1, 1),
		ivec2(-1, 0), ivec2(-1, -1), ivec2(0, -1), ivec2(1, -1));

float hget(int i) { return pc.parity == 0 ? h0.v[i] : h1.v[i]; }
float aget(int i) { return pc.parity == 0 ? a0.v[i] : a1.v[i]; }
void hset(int i, float x) { if (pc.parity == 0) h1.v[i] = x; else h0.v[i] = x; }
void aset(int i, float x) { if (pc.parity == 0) a1.v[i] = x; else a0.v[i] = x; }

bool inside(ivec2 c) { return c.x >= 0 && c.y >= 0 && c.x < pc.n && c.y < pc.n; }

void main() {
	ivec2 c = ivec2(gl_GlobalInvocationID.xy);
	if (!inside(c)) return;
	int i = c.y * pc.n + c.x;
	float u = up.v[i];

	if (pc.stage == 0) {
		if (u < 0.0) {
			hset(i, 0.0);
			for (int k = 0; k < 8; k++) wt.v[i * 8 + k] = 0.0;
			return;
		}
		float h = hget(i);
		float s[8];
		float best = 0.0;
		float hr = h;
		float dr = pc.dx;
		float hmin = 1e9;
		float sum = 0.0;
		float lap = -4.0 * h;
		for (int k = 0; k < 8; k++) {
			ivec2 nc = c + OFF[k];
			float hn = inside(nc) ? hget(nc.y * pc.n + nc.x) : 0.0;
			float d = (k & 1) == 1 ? pc.dx * 1.41421356 : pc.dx;
			float sl = (h - hn) / d;
			s[k] = sl;
			hmin = min(hmin, hn);
			if (sl > best) {
				best = sl;
				hr = hn;
				dr = d;
			}
			if (sl > 0.0) sum += pow(sl, pc.p_mfd);
			if ((k & 1) == 0) lap += hn;
		}
		float A = aget(i);
		float hn;
		if (best <= 0.0) {
			hn = hmin + 0.002 * pc.dx; // pit: fill toward the spill point
			for (int k = 0; k < 8; k++) wt.v[i * 8 + k] = 0.0;
		} else {
			// Incision is shared among all downslope neighbours by the flow
			// weights (not just the steepest one), which keeps valleys from
			// snapping to the eight grid directions. Semi-implicit in h.
			float sc = 0.0;
			float sh = 0.0;
			for (int k = 0; k < 8; k++) {
				float w = s[k] > 0.0 ? pow(s[k], pc.p_mfd) / sum : 0.0;
				wt.v[i * 8 + k] = w;
				float d = (k & 1) == 1 ? pc.dx * 1.41421356 : pc.dx;
				float ck = w * sqrt(A) * pc.dt / d;
				sc += ck;
				sh += ck * (h - s[k] * d); // ck * neighbour height
			}
			hn = (h + pc.dt * u + sh) / (1.0 + sc);
			hn += pc.dt * pc.kd * lap / (pc.dx * pc.dx);
			hn = clamp(hn, hr + 1e-4 * dr, hr + pc.talus * dr);
		}
		hset(i, hn);
		return;
	}

	if (pc.stage == 1) {
		if (u < 0.0) {
			aset(i, 0.0);
			return;
		}
		float A = pc.dx * pc.dx;
		for (int k = 0; k < 8; k++) {
			ivec2 nc = c + OFF[k];
			if (!inside(nc)) continue;
			int j = nc.y * pc.n + nc.x;
			A += aget(j) * wt.v[j * 8 + ((k + 4) & 7)];
		}
		aset(i, A);
	}
}
