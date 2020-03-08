void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    if (iFrame < 60) {

    	fragColor = vec4(10.0, 0.0, 0.0, 1.0);

    }

    else if(fragCoord.x == 5.0 && fragCoord.y == 5.0) {

            vec4 tex = texture(iChannel1, fragCoord);

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

            fragColor = vec4(new_pos, s);

        }


    else {

        fragColor = texture(iChannel1, fragCoord);

    }


}
