#define LAMBERT_INT 20
#define DIELECTRIC_INT 30
#define DIFFUSE_INT 40
#define PI 3.1415926538

#define SUN 0
#define EARTH 3

#define DELTA 5e-5

// Source for Earth information
// https://nssdc.gsfc.nasa.gov/planetary/factsheet/earthfact.html

#define EARTH_SEMIMAJOR_AXIS 10.0
#define EARTH_SEMIMINOR_AXIS 10.0

// defining a distance of 10 as AU

struct ray
{
    vec3 origin;
    vec3 direction;
};

struct material {
    vec3 albedo;
	int mat_type;
    float mat_dep;
};

struct planet_info {

    vec4 col; // w=planet id
    vec4 pos; // xyz. w=sign

};

struct hit_record {

    float t;

    vec3 p;

    float u;

    float v;

    vec3 normal;

    material mat;

    float id;

    vec4 pos; // xyz. w=sign

};


struct sphere {

    vec3 center;

    float radius;

    material mat;

    float s;
};

struct box {

	float x0;
    float x1;
    float y0;
    float y1;

    float k;

    material mat;
};

struct camera {

    vec3 lower_left_corner;
    vec3 horizontal;
    vec3 vertical;
    vec3 origin;
    vec3 u, v, w;
    float lens_radius;

};

sphere generate_scene(int gen_num) {


    if(gen_num == 0) { // sun

    	return sphere(vec3(0.0, 0.0, 0.0), 2.0, material(vec3(10.0, 10.0, 10.0), DIFFUSE_INT, 0.0), 0.0);

    }

    else if(gen_num == 1) { // earth

        vec4 tex = texture(iChannel0, vec2(0.0));

        vec3 curr_pos = tex.xyz; // only send xzw

        float s = tex.w;

        float k = 1.0;

        float Cx = (EARTH_SEMIMAJOR_AXIS - k) / 2.0;

        vec2 F = vec2(-k/2.0, 0.0);

        vec3 next_pos = get_next_pos(vec3(curr_pos.xz, s),
                                    EARTH_SEMIMAJOR_AXIS,
                                    EARTH_SEMIMINOR_AXIS,
                                    Cx,
                                    DELTA,
                                    AT,
                                    F);

        vec3 new_pos = vec3(next_pos.x, curr_pos.y, next_pos.y);

        s = next_pos.z;

    	return sphere(new_pos, 0.5, material(vec3(0.1, 0.1, 0.5), LAMBERT_INT, 0.0), 0.0);

    }
}

camera get_camera (vec3 lookfrom, vec3 lookat, vec3 vup, float vfov, float aspect, float aperture, float focus_dist) {

    camera new_cam;

    new_cam.lens_radius = aperture/2.0;

	float theta = vfov*PI/180.0;

    float half_height = tan(theta/2.0);

    float half_width = aspect * half_height;

    new_cam.origin = lookfrom;

    new_cam.w = normalize(lookfrom - lookat);

    new_cam.u = normalize(cross(vup, new_cam.w));

    new_cam.v = cross(new_cam.w, new_cam.u);

    new_cam.lower_left_corner = vec3(-half_width, -half_height, -1.0);

    new_cam.lower_left_corner = new_cam.origin - half_width*focus_dist*new_cam.u - half_height*focus_dist*new_cam.v - focus_dist*new_cam.w;

    new_cam.horizontal = 2.0*focus_dist*half_width*new_cam.u;

    new_cam.vertical  = 2.0*focus_dist*half_height*new_cam.v;

    return new_cam;
}

float schlick(float cosine, float ref_idx) {

    float r0 = (1.0-ref_idx) / (1.0+ref_idx);

    r0 = r0*r0;

    return r0 + (1.0-r0)*pow((1.0-cosine), 5.0);

}

bool does_refract(inout vec3 v, inout vec3 n, inout float ni_over_nt, inout vec3 refracted) {

    vec3 uv = normalize(v);

    float dt = dot(uv, n);

    float discriminant = 1.0 - ni_over_nt*ni_over_nt*(1.0-dt*dt);

    if(discriminant > 0.0) {

    	refracted = ni_over_nt*(uv - n*dt) - n*sqrt(discriminant);

        return true;

    } else {

    	return false;

    }

}

vec3 emitted(material mat) {

	return mat.albedo;

}

bool material_scatter(inout ray r, inout hit_record rec, inout vec3 attuenation, inout ray scattered) {

    if (rec.mat.mat_type == LAMBERT_INT) {

        vec3 target = normalize(rec.normal + random_in_unit_sphere(g_seed));

        scattered = ray(rec.p, target);

        attuenation = rec.mat.albedo;

        return true;

    }

    else if (rec.mat.mat_type == DIELECTRIC_INT) {

        vec3 outward_normal;

        vec3 reflected = normalize(r.direction) - 2.0*dot(normalize(r.direction), rec.normal)*rec.normal;

        float ni_over_nt;

        attuenation = vec3(1.0, 1.0, 1.0);

        vec3 refracted;

        float reflect_prob;

        float cosine;

        if (dot(r.direction, rec.normal) > 0.0) {

        	outward_normal = -rec.normal;

            ni_over_nt = rec.mat.mat_dep;

            cosine = rec.mat.mat_dep * dot(r.direction, rec.normal) / length(r.direction);

        } else {

            outward_normal = rec.normal;

            ni_over_nt = 1.0/rec.mat.mat_dep;

            cosine = -dot(r.direction, rec.normal) / length(r.direction);

        }

        if (does_refract(r.direction, outward_normal, ni_over_nt, refracted)) {

        	reflect_prob = schlick(cosine, rec.mat.mat_dep);

        } else {

        	reflect_prob = 1.0;

        }

        if (rand1(g_seed) < reflect_prob) {

            scattered = ray(rec.p, reflected);

        } else {

        	scattered = ray(rec.p, refracted);

        }

        return true;

    }
}

ray get_ray(camera cam, float u, float v) {

    vec2 rd = cam.lens_radius*random_in_unit_disk(g_seed);

    vec3 offset = cam.u * rd.x + cam.v * rd.y;

    return ray(cam.origin + offset, cam.lower_left_corner + u*cam.horizontal + v*cam.vertical - cam.origin - offset);

}

bool hit_sphere(sphere s, ray r, float t_min, float t_max, inout hit_record rec) {

    vec3 origin_to_center = r.origin - s.center;

    float a = dot(r.direction, r.direction);

    float b = dot(origin_to_center, r.direction);

    float c = dot(origin_to_center, origin_to_center) - (s.radius * s.radius);

    float discriminant = (b*b) - (a*c);

    if (discriminant > 0.0) {

    	float temp = (-b - sqrt(b*b-a*c))/a;

        if(temp < t_max && temp > t_min) {

            rec.t = temp;
            rec.p = (r.origin + rec.t*r.direction);
            rec.normal = (rec.p - s.center)/s.radius;
            rec.mat = s.mat;
            rec.pos = vec4(s.center, s.s);

            return true;
        }

        temp = (-b + sqrt(b*b-a*c))/a;
        if (temp < t_max && temp > t_min) {

        	rec.t = temp;
            rec.p = (r.origin + rec.t*r.direction);
            rec.normal = (rec.p - s.center)/s.radius;
            rec.mat = s.mat;
            rec.pos = vec4(s.center, s.s);

            return true;
        }

    }
   	return false;
}


bool hit(ray r, float t_min, float t_max, inout hit_record rec) {

	hit_record temp_rec;
    bool hit_anything = false;
    float closest_so_far = t_max;

    sphere curr;

    for (int i = 0; i < 8; i++) {

        curr = generate_scene(i);

        if(hit_sphere(curr, r, t_min, closest_so_far, temp_rec)) {

            hit_anything = true;
            closest_so_far = temp_rec.t;
            rec = temp_rec;
            rec.id = float(i);
        }
    }

    return hit_anything;

}

planet_info color(ray r, int depth) {

    hit_record rec;

    planet_info pi;

    vec4 color_vec = vec4(vec3(1.0), 0.0);

    for(int i = 0; i < MAX_RECURSION; i++) {

        if (depth < 50 && hit(r, 0.001, MAX_FLOAT, rec)) {

            ray scattered;

            vec3 attuenation;

            vec4 emitted = vec4(10.0, 10.0, 10.0, -1.0);

            if (material_scatter(r, rec, attuenation, scattered)) {

                r = scattered;

                depth += 1;

            	color_vec = emitted + color_vec*vec4(attuenation, 1.0);

                color_vec.w = rec.id;

                pi.col = color_vec;
                pi.pos = rec.pos;

            } else {

                pi.col = emitted;
            	pi.pos = vec4(-1.0);

                return pi;

            }

        } else {

            pi.col = vec4(0.0);
            pi.pos = vec4(-1.0);

            return pi;
        }
    }

    return pi;

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    camera cam = get_camera(vec3(0.0, 0, 20.0), vec3(0.0, 2.0, 0.0), vec3(0.0, 1.0, 0.0), 100.0, iResolution.x/iResolution.y, 0.0, length(vec3(3.0, 3.0,3.0) -  vec3(2.0, 1.4, 2.0)));

    vec3 col;

    planet_info ret;

    init_rand(fragCoord, iTime);

    for(int s = 0; s < 100; s++) {

        float u = float(fragCoord.x + rand1(g_seed))/iResolution.x;
        float v = float(fragCoord.y + rand1(g_seed))/iResolution.y;

        ray rout = get_ray(cam, u, v);

        ret = color(rout, 0);

        col += ret.col.xyz;

    }

    col = col/100.0;

    col = pow(col, vec3(1.0/2.2));


    if (fragCoord.x > 20.0 || fragCoord.y > 20.0) {

        fragColor = vec4(col, 1.0);

    }

    //else if (fragCoord.x == 0.0 && fragCoord.y == 0.0 && ret.col.w == 1.0) {

    //	fragColor = ret.pos;

    //}

    else {

    	fragColor = texture(iChannel0, uv);

    }

    if (iFrame < 1) {

    	fragColor = vec4(10.0, 0.0, 0.0, 1.0);

    }
}
