const vec3 lightColor = vec3(16.86, 8.76 +2., 3.2 + .5);

float map(vec3 p, inout settings setts)
{

    vec3 pos_earth = texture(iChannel1, vec2(0.0)).xyz;

    vec3 pos_mars = texture(iChannel1, vec2(0.3)).xyz;

    vec3 pos_jupiter = texture(iChannel1, vec2(0.6)).xyz;

    vec3 pos_saturn = texture(iChannel1, vec2(0.9)).xyz;

    float sun = world_sdf(p, vec3(0.0, 0.0, 0.0), iTime, settings(SUN, DIFFUSE_POINT_SOFT_SHADOWS));

    float earth = world_sdf(p, pos_earth, iTime, settings(EARTH, DIFFUSE_POINT_SOFT_SHADOWS));

    float mars = world_sdf(p, pos_mars, iTime, settings(MARS, DIFFUSE_POINT_SOFT_SHADOWS));

    float jupiter = world_sdf(p, pos_jupiter, iTime, settings(JUPITER, DIFFUSE_POINT_SOFT_SHADOWS));

    float saturn = world_sdf(p, pos_saturn, iTime, settings(SATURN, DIFFUSE_POINT_SOFT_SHADOWS));

    float m = min(earth, sun);

    m = min(m, mars);

    m = min(m, jupiter);

    m = min(m, saturn);

    return m;
}

vec3 computeNormal(vec3 p, settings setts)
{
    vec2 h = vec2(EPSILON, 0.0);

    return normalize(vec3(map(p + h.xyy, setts) - map(p - h.xyy, setts),
                          map(p + h.yxy, setts) - map(p - h.yxy, setts),
                          map(p + h.yyx, setts) - map(p - h.yyx, setts)));

}
bool sphere_tracing(ray r,
               		int max_iter,
               		settings setts,
               		out vec3 hit_loc,
               		out int iters)
{
    //hit_loc = r.origin + r.direction * (-r.origin.y / r.direction.y);
    //iters = 1;
    //return true;

    // TODO: implement sphere tracing

    // it should work as follows:
    //
    // while (hit has not occured && iteration < max_iters)
    //     set the step size to be the SDF
    //     march step size forwards
    //     if a collision occurs (SDF < EPSILON)
    //         return hit location and iteration count
    // return false


    int i = 0;

    while (i < max_iter) {

        float SDF = map(r.origin, setts);

        r.origin = r.origin + SDF * r.direction;

        if (SDF < EPSILON) {


            hit_loc = r.origin;

            iters = i;

            return true;

        }

        i++;

    }

    iters = max_iter;

    return false;
}

float soft_shadow(ray r,
                  int max_iter,
               	  settings setts,
                  float k)
{

    int i = 0;

    float step_size = 0.0;

    float dist = 0.0;

    float ratio = 1.0;

    while (i < max_iter) {

        float SDF = map(r.origin, setts);

        r.origin = r.origin + SDF * normalize(r.direction);

        step_size = length(normalize(r.direction) * SDF);

        dist += step_size;

        if (SDF < EPSILON) {

            return ratio;

        }

        ratio = min(ratio, step_size/dist * k);

        i++;

    }

    return ratio;
}

vec3 shade(vec3 p, int iters, settings setts)
{
    if (setts.shade_mode == GRID)
    {
    	float res = 0.2;
    	float one = abs(mod(p.x, res) - res / 2.0);
    	float two = abs(mod(p.y, res) - res / 2.0);
    	float three = abs(mod(p.z, res) - res / 2.0);
    	float interp = min(one, min(two, three)) / res;

        return mix( vec3(0.2, 0.5, 1.0), vec3(0.1, 0.1, 0.1), smoothstep(0.0,0.05,abs(interp)) );
    }
    else if (setts.shade_mode == COST)
    {
        return vec3(float(iters) / float(cost_norm));
    }
    else if (setts.shade_mode == NORMAL)
    {
        return 0.5 * vec3(computeNormal(p, setts) + 1.0);
    }

    else if (setts.shade_mode == DIFFUSE_POINT_SOFT_SHADOWS)
    {
        vec3 light_pos = vec3(0.0, 15.0, 0.0);
        vec3 light_intensity = vec3(1000.0);
        vec3 surface_color = vec3(0.5);
        float shadow_k = 0.5;

        vec3 LightVector = light_pos - p;

        float dist = pow(length(LightVector), 2.0);

        vec3 NNormal = computeNormal(p, setts);

        vec3 NLight = normalize(LightVector);

        float LambertVal = max(0.0, dot(NNormal, NLight));

        vec3 color = surface_color * light_intensity/dist * LambertVal;

        return color * soft_shadow(ray(p+EPSILON*NNormal, NLight), 1000, setts, shadow_k);
    }
    else if (setts.shade_mode == DIFFUSE_DIR_SOFT_SHADOWS)
    {
        vec3 light_dir = normalize(vec3(-1.0, -1.0, 0.0));
        vec3 light_color = vec3(0.8);
        vec3 surface_color = vec3(0.5);
        float shadow_k = 1.0;

        vec3 LightVector = -light_dir;

        float dist = pow(length(LightVector), 2.0);

        vec3 NNormal = computeNormal(p, setts);

        vec3 NLight = normalize(LightVector);

        float LambertVal = max(0.0, dot(NNormal, NLight));

        vec3 color = surface_color * light_color/dist * LambertVal;

        int iters = 0;

        vec3 hit_loc = vec3(0.0);

        return color * soft_shadow(ray(p+EPSILON*NNormal, NLight), 1000, setts, shadow_k);

    }

    return vec3(0.0);
}

vec3 render(settings setts, vec2 fragCoord)
{

    camera cam = camera_const(vec3(-20.0, 10.0, -150.0),
    				          vec3(0.0, 0.0, 0.0),
                              vec3(0.0, 1.0, 0.0),
                              20.0,
                              640.0 / 360.0,
                              0.0,
                              sqrt(27.0));


    vec2 uv = fragCoord/iResolution.xy;
    ray r = camera_get_ray(cam, uv);

    int max_iter = 1000;

    vec3 col = vec3(0.0);

    vec3 hit_loc;
    int iters;
    bool hit;

    if (sphere_tracing(r, max_iter, setts, hit_loc, iters))
    {
        col = shade(hit_loc, iters, setts);
    }

    if (setts.shade_mode == FINAL_SCENE_REFLECT)
    {
        float reflection_coefficient = 0.15;

        vec3 norm = normalize(computeNormal(hit_loc, setts));

        if(sphere_tracing(ray(hit_loc+EPSILON*norm, reflect(normalize(r.direction), norm)), max_iter, setts, hit_loc, iters)) {
        	col += reflection_coefficient * shade(hit_loc, iters, setts);

        }
    }

    return pow(col, vec3(1.0 / 2.2));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    vec3 col = render(render_settings, fragCoord);

    if (fragCoord.y > 5.0) {

        fragColor = vec4(col, 1.0);

    }

    else {

    	fragColor = texture(iChannel1, uv);

    }

   // fragColor = vec4(col, 1.0);
}
