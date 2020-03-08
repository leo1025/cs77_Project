// pre-defined constants
#define EPSILON 1e-4
#define PI 3.1415926535897932384626433832795

// scene type
#define SUN 0
#define BOX 1
#define CYLINDER 2
#define CONE 3
#define EARTH 4
#define MARS 5
#define JUPITER 6
#define SATURN 6

// shade mode
#define GRID 0
#define COST 1
#define NORMAL 2
#define DIFFUSE_POINT 3
#define DIFFUSE_POINT_HARD_SHADOWS 4
#define DIFFUSE_DIR_HARD_SHADOWS 5
#define DIFFUSE_POINT_SOFT_SHADOWS 6
#define DIFFUSE_DIR_SOFT_SHADOWS 7
#define FINAL_SCENE_REFLECT 8

//
// Render Settings
//
struct settings
{
    int sdf_func;
    int shade_mode;
};

settings render_settings = settings(BOX, DIFFUSE_POINT_SOFT_SHADOWS); // initial object

//float anim_speed = 0.35;
float anim_speed = 0.35;
int cost_norm = 200;

//
// Ray
//

struct ray
{
    vec3 origin;            // this is the origin of the ray
    vec3 direction;         // this is the direction the ray is pointing in
};

//
// Camera
//

struct camera
{
    vec3 origin;            // this is the origin of your camera
    vec3 lower_left_corner; // this is the location of the lower-left corner of the image in relation to the origin
    vec3 horizontal;        // this is the horizontal extents of the image the camera sees
    vec3 vertical;          // this is the vertical extents of the image the camera sees
    vec3 u;
    vec3 v;
    float lens_radius;      // the radius of the lens
};

camera camera_const(vec3 lookfrom,
                    vec3 lookat,
                    vec3 up,
                    float fov,
                    float aspect,
                    float aperture,
                    float focal_dist)
{
    camera cam;

    vec3 w;

    cam.lens_radius = aperture / 2.0;

    float theta = fov * PI / 180.0;
    float half_height = tan(theta / 2.0);
    float half_width = aspect * half_height;
    cam.origin = lookfrom;
    w = normalize(lookfrom - lookat);
    cam.u = normalize(cross(up, w));
    cam.v = cross(w, cam.u);
    cam.lower_left_corner = cam.origin - half_width * cam.u * focal_dist - half_height * cam.v * focal_dist - w * focal_dist;
    cam.horizontal = 2.0 * half_width * cam.u * focal_dist;
    cam.vertical = 2.0 * half_height * cam.v * focal_dist;

    return cam;
}

ray camera_get_ray(camera cam, vec2 uv)
{
    ray r;

    r.origin = cam.origin;
    r.direction = normalize(cam.lower_left_corner + uv.x * cam.horizontal +
                            uv.y * cam.vertical - cam.origin);

    return r;
}

// returns the signed distance to a sphere from position p
float sdSphere(vec3 p, float r)
{
 	return length(p) - r;
}

float world_sdf(vec3 p, vec3 obj_pos, float time, settings setts)
{
    if (setts.sdf_func == SUN)
    {
        return sdSphere(p - obj_pos, 3.0f);
    }

    if (setts.sdf_func == EARTH)
    {
        return sdSphere(p - obj_pos, 1.5f);
    }

    if (setts.sdf_func == MARS)
    {
        return sdSphere(p - obj_pos, 1.5f);
    }

    if (setts.sdf_func == JUPITER)
    {
        return sdSphere(p - obj_pos, 1.5f);
    }

    if (setts.sdf_func == SATURN)
    {
        return sdSphere(p - obj_pos, 1.5f);
    }

    return 1.f;
}

void polar_domain_repetition(inout vec2 p, float repetitions)
{

    float angle = 2.0*PI/repetitions;

    float r = sqrt(pow(p.x, 2.0) + pow(p.y, 2.0));

    float theta = atan(p.y/p.x);

    float modulous = mod(theta + angle/2.0, angle) - angle/2.0;

    p = vec2(r * cos(modulous), r * sin(modulous));

}
// Ray tracing in one weekend basecode for Dartmouth CS 77/177
// by Wojciech Jarosz, 2019
// adapted from on https://www.shadertoy.com/view/XlycWh

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
