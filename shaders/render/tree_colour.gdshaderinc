// The trees' foliage colour, shared by the trees and their flat far crowns:
// grey-silver palo santo and scrub in the arid lowlands, green Scalesia
// forest in the humid highlands (humid: the masks' G channel at the tree).
vec3 tree_colour(float seed, float humid) {
	vec3 arid = mix(vec3(0.42, 0.42, 0.36), vec3(0.50, 0.48, 0.40), seed);
	vec3 green = mix(vec3(0.13, 0.27, 0.09), vec3(0.22, 0.34, 0.11), seed);
	return mix(arid, green, smoothstep(0.15, 0.7, humid));
}
