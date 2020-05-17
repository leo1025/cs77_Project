// Copyright © 2020 Wojciech Jarosz
// Based off of Andrew Kensler's blog: http://eastfarthing.com/blog/2015-04-21-noise/
float falloff(float t)
{
    float t2 = clamp(0.0, 1.0, abs(t));

    return 1.0 - smoothstep(0.0, 1.0, t2);
}

vec2 grad(vec2 cell, bool change)
{
    // 1D random angle
	float angle = radians(360.0*hash12(cell));

    float flow = change ? iTime*5. : 0.;
    // construct unit 2D vector with angle
    float s = sin(angle+flow);
    float c = cos(angle+flow);
    vec2 g = vec2(c, s);

    return g;
}

float bump(vec2 p, vec2 cell, bool change)
{
    float v = dot(p, grad(cell, change));

	return v * falloff(p.x) * falloff(p.y);
}

// signed noise
// return value in [-1,1]
float snoise(vec2 p, bool change)
{
    vec2 cell = floor(p);
    vec2 frac = p - cell;

    float result = 0.0;
    // add surflets from all 4 neighbors
    result += bump(frac-vec2(0.0,0.0), cell+vec2(0.0,0.0), change);
    result += bump(frac-vec2(1.0,0.0), cell+vec2(1.0,0.0), change);
    result += bump(frac-vec2(0.0,1.0), cell+vec2(0.0,1.0), change);
    result += bump(frac-vec2(1.0,1.0), cell+vec2(1.0,1.0), change);

    if (false)
      	result = abs(result);

    return result;
}

// fractional brownian motion
float fbm(vec2 p, float domainScale, float H, float octaves, bool change)
{
    float result = 0.0;
    float valueScale = 1.0;
    float valueScaleInc = pow(domainScale, -H);

    // scale by domainScale and rotate at each octave
    float s = sin(0.64);
    float c = cos(0.64);
    mat2 m = domainScale * mat2(c, s, -s, c);

    for (float octave = octaves; octave > 0.; --octave, p *= m, valueScale *= valueScaleInc)
    {
        float n = snoise(p, change);

        float fade = min(1.0, octave);
        result += fade * valueScale * n;
    }
    result = 0.5*result + 0.5;

    return result;
}

// multifractals
float multifrac(vec2 p, float domainScale, float H, float octaves, bool change)
{
    float result = 1.0;
    float valueScale = 1.0;
    float valueScaleInc = pow(domainScale, -H);

    // scale by domainScale and rotate at each octave
    float s = sin(0.64);
    float c = cos(0.64);
    mat2 m = domainScale * mat2(c, s, -s, c);

    // instead of summing noise, product it
    for (float octave = octaves; octave > 0.; --octave, p *= m, valueScale *= valueScaleInc)
    {
        float n = snoise(p, change) + 0.7;
        result *= valueScale * n;
    }

    return result;
}
// list of climate colors
const vec3 climates[] = vec3[]
    (
    vec3(1.0),// white
    vec3(.5, .39, .2),// dark tan brown
    vec3(.085, .2, .04),// dark green
    vec3(.065, .22, .04),// darkest green
    vec3(.2, .3, 0),// light green
    vec3(.5, .39, .2),// tan brown
    vec3(.5, .42, .28),// brown
    vec3(.6, .6, .1),// yellow
    vec3(.5, .42, .28),
    vec3(.5, .39, .2),
    vec3(.2, .3, 0),
    vec3(.065, .22, .04),
    vec3(.085, .2, .04),
    vec3(.5, .39, .2),
    vec3(1.0)
	);
// list of where the climates are based on latitude
const float bounds[] = float[](0.3, 0.32, 0.33,
                               0.4, 0.43, 0.465,
                               0.49, 0.5, 0.51,
                               0.535, 0.57, 0.6,
                               0.67, 0.68, 0.7);

// with HUGE help from Chapter 15 - Fractal Solid Textures: Some Examples
// by F. Kenton Musgrave
// from Texturing and Modeling: A Procedural Approach ed. 3
vec3 earth(vec2 uv)
{
	vec2 p = uv*vec2(iResolution.x/iResolution.y,1.0)*4.0;
    // use iTime to rotate the texture and use mod to wrap it around
    p.x = mod(p.x + iTime/2.0, iResolution.x/iResolution.y*4.0);

    float fbmH = 0.7;
    float fbmOctaves = mix(0.0, 8.0, 0.9);
    float multiH = 0.0;
    float multiOctaves = mix(0.0, 8.0, 0.7);

    // acquire perlin noise for fbm or multifractals
    float fbmF = fbm(p, 2.0, fbmH, fbmOctaves, false);
    float multiF = multifrac(p, 2.0, multiH, multiOctaves, false);

    vec3 res = vec3(0.0);

    // CREATE ICE CAPS
    // (to hide UV mapping distortions)
    if(uv.y < 0.3 || uv.y > 0.7){
       	// rough up the coastline of the ice caps
        // using noise to make it seem more natural
        if ((uv.y > 0.25 && uv.y < 0.3) || (uv.y > 0.7 && uv.y < 0.75)){

            // weight noise towards snow so
            // coastline seems more jagged and less ocean focused

            // if noise is less than threshold
            // make it the ocean
            if(fbmF < 0.45){
                // smoothstep the sea depth
                float depth = smoothstep(0.0, 0.45, fbmF);
                // multiply the depth with blue to make
                // deep parts VERY dark
                // and other parts normally blue
                return depth*vec3(0.0, 0.0, 0.5);
            }
            // else make it snow
            else{
                return vec3(1.0);
            }
        }
        // make anything closer to the poles snow/white
        else{
        	return vec3(1.0);
        }
   	}

    // CREATE OCEAN
    if (fbmF < 0.5){
        // smoothstep the sea depth
        float depth = smoothstep(0.0, 0.5, fbmF);
        // multiply the depth with blue to make
        // deep parts VERY dark
        // and other parts normally blue
        res = depth*vec3(0.0, 0.0, 0.5);
    }

    // CREATE LAND
    else{
        // creating a gradient of color
        // (from dandymcgee of https://www.shadertoy.com/view/ttfXWX)

        // Add up all of the gradient climates affecting the current fragment
        for (int i = 0; i < 15; i++)
        {
            // use step to determine if current edge zone is valid
            // step function = 0.0 if uv.y is less than bounds[i], 1.0 otherwise
            float mask = (1.0 - step(uv.y, bounds[i])) * step(uv.y, bounds[i+1]);

            // Calculate gradient within current area
            // by getting the position uv.y relative to its bounds
            // and then dividing it by the bound area
            float gradient = (uv.y - bounds[i]) / (bounds[i+1] - bounds[i]);

            // Mix climates at the two edges of this area, then mask it to prevent leaking climates
            res += mask * mix(climates[i], climates[i+1], gradient);
        }
        // add climate based on the "altitude" of the underlying perlin noise

   		// smoothstep fbmF result from sealevel to mountain peak (0.5 to 1.0)
        float altitude = smoothstep(0.5, 1.0, fbmF);
        // multiply smoothstepped altitude to the index # of different climates and round it
        int altTerra = 7 - int(round(7.0 * altitude));
        // get climate of alt and add it as shade
        res += climates[altTerra];

        // muddle the colors a bit to make it look nicer
        // using inverse multiF and varying the current color by it
        res*= 1.0 - multiF;



		// CREATING RIVERS/LAKES

        // create a shifted turbulent noise so the "river" squiggles
        // appear on land as well (usually they would be situated in the oceans)
        float movScale = 4.0*0.8;
        vec2 newPos = vec2(p.x + iResolution.x/iResolution.y*movScale, p.y + movScale);

        // make sure shifted turbulence is within the texture
        newPos.x = mod(newPos.x, iResolution.x/iResolution.y*4.0);
    	newPos.y = mod(newPos.y, 4.0);

        float turb = abs(2.0*fbm(newPos, 2.0, fbmH, fbmOctaves, false)-1.0);

        // if the turbulent value is below a certain threshold
        // make it water
        if(turb < 0.035){
            res = vec3(0.0, 0.0, 1.0);
        }
    }
    return res;
}

vec3 gas(vec2 uv, vec3 color){
    vec2 p = uv*vec2(iResolution.x/iResolution.y,1.0)*4.0;

    // use iTime to rotate the texture and use mod to wrap it around
    p.x = mod(p.x + iTime, iResolution.x/iResolution.y*4.0);

    // calculate twistng variable based
    // on magnitude of uv vector but squared

    // this creates something similar to a coriolis effect
    float twist;
    if (uv.x < 0.5){
    	twist = length(uv) * length(uv);
    }
    else{
        vec2 adjusted = vec2(1.0 - uv.x, uv.y);
        twist = length(adjusted) * length(adjusted);
    }
    float angle = 0.6 * 2.0 * PI * twist;
    vec2 newPos = vec2(p.x*cos(angle) - p.y*sin(angle), p.x*sin(angle) + p.y*sin(angle));

    // make sure new position is within bounds
    newPos.x = mod(newPos.x, iResolution.x/iResolution.y*4.0);
    newPos.y = mod(newPos.y, 4.0);

    float fbmH = 0.65;
    float fbmOctaves = mix(0.0, 8.0, 0.9);
    float multiH = 0.0;
    float multiOctaves = mix(0.0, 8.0, 0.7);

    // acquire perlin noise for fbm or multifractals
    float fbmF = fbm(newPos, 2.0, fbmH, fbmOctaves, true);
    float multiF = multifrac(newPos, 2.0, multiH, multiOctaves, true);

    // apply color to gas
    vec3 res = color * fbmF;
    return res;
}

vec3 moon(vec2 uv, vec3 color){
    vec2 p = uv*vec2(iResolution.x/iResolution.y,1.0)*4.0;

    // use iTime to rotate the texture and use mod to wrap it around
    p.x = mod(p.x + iTime, iResolution.x/iResolution.y*4.0);

    float fbmH = 0.3;
    float fbmOctaves = mix(0.0, 8.0, 1.0);
    float multiH = 0.0;
    float multiOctaves = mix(0.0, 8.0, 0.7);

    // acquire perlin noise for fbm or multifractals
    float fbmF = fbm(p, 2.0, fbmH, fbmOctaves, false);
    float multiF = multifrac(p, 2.0, multiH, multiOctaves, false);

    // Start texture off with normal grey
    vec3 res = vec3(0.6);

    // Divide texture into highlands
    // and maria (lunar lowlands)
    if(fbmF > 0.45){
        // add onto grey if highland
        res += vec3(0.7)*fbmF;
    }
    else{
        // multiply with grey if maria
        res *= vec3(0.7) + vec3(0.1)*fbmF;
    }
    res *= color;

    // CREATE CRATER
    // uses a predetermined center
    vec2 center = vec2(0.95, 0.405)*vec2(iResolution.x/iResolution.y,1.0)*4.0;
    vec2 c2p = p - center;
    float dist = length(c2p);
    float gradi;
    // the central peak
    if(dist < 0.03){
        gradi = smoothstep(0.03, 0.0, dist);
        res += vec3(0.6) * gradi;
        res += res*fbmF;
    }
    // rim
    else if(dist > 0.1 && dist < 0.14){
        if(dist < 0.19){
            gradi = smoothstep(0.1, 0.12, dist);
            res += vec3(0.4)*gradi;
        }
        else{
            gradi = smoothstep(0.14, 0.12, dist);
            res += vec3(0.4)*gradi*gradi;
        }
        res += res*fbmF;
    }

    // create pre-determined crater rays
    float slope = c2p.y/c2p.x;
    if(dist > 0.13 && dist < 0.6 && slope < 1.05 && slope > 0.95){
        res += vec3(0.4);
        res += res*fbmF;
    }
    else if(dist > 0.13 && dist < 0.5 && slope < 0.45 && slope > 0.35){
        res += vec3(0.4);
        res += res*fbmF;
    }
    else if(dist > 0.13 && dist < 0.6 && slope < -0.95 && slope > -1.05){
        res += vec3(0.4);
        res += res*fbmF;
    }
    else if(dist > 0.13 && dist < 0.4 && slope < 0.025 && slope > -0.025){
        res += vec3(0.4);
        res += res*fbmF;
    }
    else if(dist > 0.13 && dist < 0.4 && p.x < (center.x+0.01) && p.x > (center.x-0.01)){
        res += vec3(0.4);
    }

	// use shifted turbulence to make crater more varied
    if (dist > 0.13 && dist < 0.5){
        // use a gradient to gradually lessen the amount of noise
        // near the edge
        gradi = smoothstep(0.5, 0.13, dist);
        res += vec3(1.5)* abs(fbmF*2.0 - 0.5) * gradi;
    }

    // muddle up the colors with multifractals
    res *= 1.0 - multiF;

	return res;
}
// -----------------------------------------------------------------------
// #######################################################################
// -----------------------------------------------------------------------
const vec3 lightColor = vec3(16.86, 8.76 +2., 3.2 + .5);

vec2 map(vec3 p, inout settings setts, bool notShadow)
{

    // Grab all planet positions from Buffer B
    vec3 pos_earth = texture(iChannel1, vec2(0.0)).xyz;

    vec3 pos_mars = texture(iChannel1, vec2(0.25)).xyz;

    vec3 pos_jupiter = texture(iChannel1, vec2(0.5)).xyz;

    vec3 pos_saturn = texture(iChannel1, vec2(0.75)).xyz;

    vec2 final;

    vec2 sun = vec2(world_sdf(p, vec3(0.0, 0.0, 0.0), iTime, settings(SUN, DIFFUSE_POINT_SOFT_SHADOWS)), 0.0);

    vec2 earth = vec2(world_sdf(p, pos_earth, iTime, settings(EARTH, DIFFUSE_POINT_SOFT_SHADOWS)), 1.0);

    // Prevents double shadowing from across space
    if (sun.x < earth.x && notShadow){
        final = sun;
    }
    else{
        final = earth;
    }

    vec2 mars = vec2(world_sdf(p, pos_mars, iTime, settings(MARS, DIFFUSE_POINT_SOFT_SHADOWS)), 2.0);

    if (mars.x < final.x){
        final = mars;
    }

    vec2 jupiter = vec2(world_sdf(p, pos_jupiter, iTime, settings(JUPITER, DIFFUSE_POINT_SOFT_SHADOWS)), 3.0);

    if(jupiter.x < final.x){
        final = jupiter;
    }

    vec2 saturn = vec2(world_sdf(p, pos_saturn, iTime, settings(SATURN, DIFFUSE_POINT_SOFT_SHADOWS)), 4.0);

    if(saturn.x < final.x){
        final = saturn;
    }

    // Returns hit if any
    return final;
}

vec3 computeNormal(vec3 p, settings setts)
{
    vec2 h = vec2(EPSILON, 0.0);

    return normalize(vec3(map(p + h.xyy, setts, true).x - map(p - h.xyy, setts, true).x,
                          map(p + h.yxy, setts, true).x - map(p - h.yxy, setts, true).x,
                          map(p + h.yyx, setts, true).x - map(p - h.yyx, setts, true).x));

}

bool sphere_tracing(ray r,
               		int max_iter,
               		settings setts,
               		out vec3 hit_loc,
               		out int iters,
                    out float id)
{
    int i = 0;

    while (i < max_iter) {

        vec2 res = map(r.origin, setts, true);
        float SDF = res.x;

        r.origin = r.origin + SDF * r.direction;

        if (SDF < EPSILON) {


            hit_loc = r.origin;

            iters = i;

            id = res.y;

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
                  float k,
                  float dist2sun)
{

    int it = 0;
    float totalD = 0.0;
    float ratio = 1.0;
    float currRatio;
    float s = map(r.origin, setts, false).x;
    vec3 loc = r.origin;

    while(it < max_iter && totalD < dist2sun){
        // get the current location
        loc = loc + normalize(r.direction) * s;

        // add the stepsize to the total distance traversed
        totalD += length(normalize(r.direction) * s);

        // get the current ratio
        currRatio = length(normalize(r.direction) * s)/totalD * k;

        // get the smaller ratio
        ratio = min(currRatio, ratio);

        // if something gets hit, return the ratio
        s = map(loc, setts, false).x;
        if(s < EPSILON){
            return ratio;
        }
        it++;
    }
    // if nothing gets hit, send out the ratio anyway
    return min(ratio, 1.0);


}

vec3 shade(vec3 p, int iters, settings setts, float id)
{
    vec3 light_pos = vec3(0.0, 0.0, 0.0);
    vec3 light_intensity = vec3(7000.0);
    vec3 surface_color = vec3(0.5);
    float shadow_k = 0.5;

    vec3 LightVector = light_pos - p;

    float dist = pow(length(LightVector), 2.0);

    vec3 NNormal = computeNormal(p, setts);

    vec3 NLight = normalize(LightVector);

    float LambertVal = max(0.0, dot(NNormal, NLight));

    if(id == 0.0){
        return vec3(10.0);
    }
    // ID definitions to collect texture color
    else if(id == 1.0){
        float r = EARTHR;
        vec3 o2p = normalize(r*NNormal);
        vec2 nUV = vec2(0.5 + atan(o2p.z, o2p.x)/(2.0*PI), 0.5 - asin(o2p.y)/PI);

        surface_color = earth(nUV);
    }
    else if(id == 2.0){
        float r = MARSR;
        vec3 o2p = normalize(r*NNormal);
        vec2 nUV = vec2(0.5 + atan(o2p.z, o2p.x)/(2.0*PI), 0.5 - asin(o2p.y)/PI);

        surface_color = moon(nUV, vec3(0.9, 0.2, 0.2));
    }
    else if(id == 3.0){
        float r = JUPITERR;
        vec3 o2p = normalize(r*NNormal);
        vec2 nUV = vec2(0.5 + atan(o2p.z, o2p.x)/(2.0*PI), 0.5 - asin(o2p.y)/PI);

        surface_color = gas(nUV, vec3(2.5, 1.0, 0.3));
    }
    else if(id == 4.0){
        float r = SATURNR;
        vec3 o2p = normalize(r*NNormal);
        vec2 nUV = vec2(0.5 + atan(o2p.z, o2p.x)/(2.0*PI), 0.5 - asin(o2p.y)/PI);

        surface_color = gas(nUV, vec3(1.5, 1.0, 0.3));
    }

    vec3 color = surface_color * light_intensity/dist * LambertVal;

    return color * soft_shadow(ray(p+EPSILON*NNormal, NLight), 1000, setts, shadow_k, length(LightVector));
}

vec3 render(settings setts, vec2 fragCoord)
{
    // Grab camera position from buffer B
    vec3 cam_pos = texture(iChannel1, vec2(1.0)).xyz;

    camera cam = camera_const(cam_pos,
    				          cam_pos + vec3(20.0, -10.0, 120.0)
                              ,
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
    float id;

    // Hit found, calculate shadows and shading
    if (sphere_tracing(r, max_iter, setts, hit_loc, iters, id))
    {
        col = shade(hit_loc, iters, setts, id);
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

        // Shows how the images are stored as color, viewed under the main image.
    	fragColor = texture(iChannel1, uv);

    }
}
