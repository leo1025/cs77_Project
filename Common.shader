// Ray tracing in one weekend basecode for Dartmouth CS 77/177
// by Wojciech Jarosz, 2019
// adapted from on https://www.shadertoy.com/view/XlycWh

#define EPSILON 1e-3
#define MAX_FLOAT 1e5
#define MAX_RECURSION 50

#define AT 1.0

#define DELTA 5e-5

// Source for Earth information
// https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html

#define EARTH_SEMIMAJOR_AXIS 10.0
#define EARTH_SEMIMINOR_AXIS 10.0

#define MARS_SEMIMAJOR_AXIS 15.0
#define MARS_SEMIMINOR_AXIS 15.0

#define JUPITER_SEMIMAJOR_AXIS 50.0
#define JUPITER_SEMIMINOR_AXIS 50.0

#define SATURN_SEMIMAJOR_AXIS 95.0
#define SATURN_SEMIMINOR_AXIS 95.0
//
// Hash functions by Nimitz:
// https://www.shadertoy.com/view/Xt3cDn
//

float g_seed = 0.;

uint base_hash(uvec2 p) {
    p = 1103515245U*((p >> 1U)^(p.yx));
    uint h32 = 1103515245U*((p.x)^(p.y>>3U));
    return h32^(h32 >> 16);
}

void init_rand(in vec2 frag_coord, in float time) {
    g_seed = float(base_hash(floatBitsToUint(frag_coord)))/float(0xffffffffU)+time;
}


float rand1(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    return float(n)/float(0xffffffffU);
}

vec2 rand2(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec2 rz = uvec2(n, n*48271U);
    return vec2(rz.xy & uvec2(0x7fffffffU))/float(0x7fffffff);
}

vec3 rand3(inout float seed) {
    uint n = base_hash(floatBitsToUint(vec2(seed+=.1,seed+=.1)));
    uvec3 rz = uvec3(n, n*16807U, n*48271U);
    return vec3(rz & uvec3(0x7fffffffU))/float(0x7fffffff);
}


vec2 random_in_unit_disk(inout float seed) {
    vec2 h = rand2(seed) * vec2(1.,6.28318530718);
    float phi = h.y;
    float r = sqrt(h.x);
	return r * vec2(sin(phi),cos(phi));
}

vec3 random_in_unit_sphere(inout float seed) {
    vec3 h = rand3(seed) * vec3(2.,6.28318530718,1.)-vec3(1,0,0);
    float phi = h.y;
    float r = pow(h.z, 1./3.);
	return r * vec3(sqrt(1.-h.x*h.x)*vec2(sin(phi),cos(phi)),h.x);
}

float euclidean_dist (vec2 P, vec2 Q) {

	return sqrt(pow(P.x - Q.x, 2.0) + pow(P.y - Q.y, 2.0));

}

float area_run (vec2 P, vec2 Q, vec2 F) {

	float base = euclidean_dist(P, Q);

    float height = sqrt(pow(euclidean_dist(P, F), 2.0) - pow(base / 2.0, 2.0));

    return base * height / 2.0;

}

float get_y (float x, float a, float b, float Cx, float s) {

	return s * (b/a) * sqrt(pow(a, 2.0) - pow((x - Cx), 2.0));

}

vec3 get_next_pos (vec3 P, float a, float b, float Cx, float delta, float A_t, vec2 F) {

	float area = 0.0;

    float x = P.x;

    float y = 0.0;

    float s = P.z;

    while (area < A_t) {

    	x = x + s * delta;

        if (x < (Cx - a)) {

        	x = Cx - a;

        }

        else if (x > (Cx + a)) {

        	x = Cx + a;

        }

        y = get_y(x, a, b, Cx, s);

        if ((y == 0.0) || (s < 0.0 && y > 0.0) || (s > 0.0 && y < 0.0)) {

        	s = -s;

        }

        area = area_run(P.xy, vec2(x, y), F);

    }

    return vec3(x, y, s);

}
