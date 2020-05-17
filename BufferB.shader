void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 col;

    vec2 uv = fragCoord / iResolution.xy;

    // During first 3 seconds, set positions of at their nearest point on their semi-major axis.

    if (iTime < 3.0) {

        if(uv.x < 0.20) {


            col = vec4( -((EARTH_SEMIMAJOR_AXIS - 1.0) / 2.0 + EARTH_SEMIMAJOR_AXIS), 0.0, 0.0, 1.0);

        }

        else if(uv.x < 0.4 && uv.x >= 0.20) {

        	col = vec4( -((MARS_SEMIMAJOR_AXIS - 1.0) / 2.0 + MARS_SEMIMAJOR_AXIS), 0.0, 0.0, 1.0);

        }

        else if(uv.x < 0.6 && uv.x >= 0.4) {

        	col = vec4( -((JUPITER_SEMIMAJOR_AXIS - 1.0) / 2.0 + JUPITER_SEMIMAJOR_AXIS), 0.0, 0.0, 1.0);

        }

        else if(uv.x < 0.8 && uv.x >= 0.6) {

        	col = vec4( -((SATURN_SEMIMAJOR_AXIS - 1.0) / 2.0 + SATURN_SEMIMAJOR_AXIS), 0.0, 0.0, 1.0);

        }

        else {

        	col = vec4(-20.0, 10.0, -120.0, 1.0);

        }

    }

    else{

        // Afterwards, calculate new position of planets.
        // Grab current position on defined section, calculate, and update.
        if(uv.x < 0.20) {

            vec4 tex = texture(iChannel1, uv);

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

            col = vec4(new_pos, s);

        }
        else if (uv.x >= 0.2 && uv.x < 0.4){

             vec4 tex = texture(iChannel1, uv);

            vec3 curr_pos = tex.xyz; // only send xzw

            float s = tex.w;

            float k = 1.0;

            float Cx = (MARS_SEMIMAJOR_AXIS - k) / 2.0;

            vec2 F = vec2(-k/2.0, 0.0);

            vec3 next_pos = get_next_pos(vec3(curr_pos.xz, s),
                                            MARS_SEMIMAJOR_AXIS,
                                            MARS_SEMIMINOR_AXIS,
                                            Cx,
                                            DELTA,
                                            AT,
                                            F);

            vec3 new_pos = vec3(next_pos.x, curr_pos.y, next_pos.y);

            s = next_pos.z;

            col = vec4(new_pos, s);

        }
        else if (uv.x >= 0.4 && uv.x < 0.6){

             vec4 tex = texture(iChannel1, uv);

            vec3 curr_pos = tex.xyz; // only send xzw

            float s = tex.w;

            float k = 1.0;

            float Cx = (JUPITER_SEMIMAJOR_AXIS - k) / 2.0;

            vec2 F = vec2(-k/2.0, 0.0);

            vec3 next_pos = get_next_pos(vec3(curr_pos.xz, s),
                                            JUPITER_SEMIMAJOR_AXIS,
                                            JUPITER_SEMIMINOR_AXIS,
                                            Cx,
                                            DELTA,
                                            AT,
                                            F);

            vec3 new_pos = vec3(next_pos.x, curr_pos.y, next_pos.y);

            s = next_pos.z;

            col = vec4(new_pos, s);

        }
        else if (uv.x >= 0.6 && uv.x < 0.8){

             vec4 tex = texture(iChannel1, uv);

            vec3 curr_pos = tex.xyz; // only send xzw

            float s = tex.w;

            float k = 1.0;

            float Cx = (SATURN_SEMIMAJOR_AXIS - k) / 2.0;

            vec2 F = vec2(-k/2.0, 0.0);

            vec3 next_pos = get_next_pos(vec3(curr_pos.xz, s),
                                            SATURN_SEMIMAJOR_AXIS,
                                            SATURN_SEMIMINOR_AXIS,
                                            Cx,
                                            DELTA,
                                            AT,
                                            F);

            vec3 new_pos = vec3(next_pos.x, curr_pos.y, next_pos.y);

            s = next_pos.z;

            col = vec4(new_pos, s);

        }

        // Key listener, adjust camera position.

        else if (uv.x > 0.8) {

            col = texture(iChannel1, uv);

            if (isKeyDown(KEY_UP)) {

            	col += vec4(0.0, 0.0, 1.0, 0.0);

            }
            if (isKeyDown(KEY_LEFT)) {

            	col += vec4(1.0, 0.0, 0.0, 0.0);

            }
            if (isKeyDown(KEY_RIGHT)) {

            	col += vec4(-1.0, 0.0, 0.0, 0.0);

            }
            if (isKeyDown(KEY_DOWN)) {

            	col += vec4(0.0, 0.0, -1.0, 0.0);

            }
            if (isKeyDown(KEY_0)) {

            	col += vec4(0.0, 1.0, 0.0, 0.0);

            }
            if (isKeyDown(KEY_1)) {

            	col += vec4(0.0, -1.0, 0.0, 0.0);

            }

        }

        else {

        	vec4 tex = texture(iChannel1, uv);

            col = tex;

        }

    }

    fragColor = col;
}
