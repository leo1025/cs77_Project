// pre-defined constants
#define EPSILON 1e-4
#define PI 3.1415926535897932384626433832795

// scene type
#define SUN 0
#define TEMP_PLANET 1

// shade mode
#define GRID 0
#define COST 1
#define NORMAL 2
#define DIFFUSE_POINT 3
#define DIFFUSE_POINT_HARD_SHADOWS 4
#define DIFFUSE_DIR_HARD_SHADOWS 5
#define DIFFUSE_POINT_SOFT_SHADOWS 6
#define DIFFUSE_DIR_SOFT_SHADOWS 7

//
// Render Settings
//
struct settings
{
    int sdf_func;
    int shade_mode;
};

settings render_settings = settings(SUN, NORMAL);

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

float sdLine(in vec2 p, in vec2 a, in vec2 b)
{
    // TODO
    float t_scalar = dot((b - a), (a - p))/dot((b - a), (b - a));

    vec2 G_vec = a - (b - a) * t_scalar;

    float dot_product = dot((b - a), (G_vec - a));

    if (dot_product > 0.0 && dot_product < pow(length(b - a), 2.0)) {

        return length(G_vec - p);

    } else {

    	float dist_0 = length(p - a);

        float dist_1 = length(p - b);

        if (dist_0 > dist_1) {

        	return dist_1;

        }

        return dist_0;
    }
}

float opSmoothUnion(float d1, float d2, float k)
{
    float h = max(k - abs(d1 - d2), 0.0);

    return min(d1, d2) - (pow(h, 2.0)/(4.0 * k));
}

float opSmoothSubtraction(float d1, float d2, float k)
{
    float h = max(k - abs(-d1 - d2), 0.0);

    return max(-d1, d2) + (pow(h, 2.0)/(4.0 * k));
}

float opSmoothIntersection( float d1, float d2, float k )
{
    float h = max(k - abs(d1 - d2), 0.0);

    return max(d1, d2) + (pow(h, 2.0)/(4.0 * k));
}

float opRound(float d, float iso)
{
    return d - iso;
}

float world_sdf(vec3 p, float time, settings setts)
{
    if (setts.sdf_func == SUN) {

        return sdSphere(p - vec3(0.f, 0.f, 0.f), 1.5f);

    }

    if (setts.sdf_func == TEMP_PLANET) {

    	return sdSphere(p - vec3(1.f, 0.f, 0.f), 0.5f);

    }
}


// The animation which you see is of a 2D slice of a 3D object. The objects exist in [-1, 1] space
// and the slice is continuously moved along z=[-1,1] using a cosine. This method renders what the
// current z value is as a progress bar at the bottom of the animation for reference.
vec3 shade_progress_bar(vec2 p, vec2 res, float z)
{
    // have to take account of the aspect ratio
    float xpos = p.x * res.y / res.x;

    if (xpos > z - 0.01 && xpos < z + 0.01) return vec3(1.0);
    else return vec3(0.0);
}
