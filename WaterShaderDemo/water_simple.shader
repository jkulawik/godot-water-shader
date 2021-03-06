/*
NOTE: this shader was based on the following two:
https://github.com/godot-extended-libraries/godot-realistic-water
https://github.com/paddy-exe/Godot-3D-Stylized-Water
*/

shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec2 scroll_speed = vec2(0.05, 0.05);
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float specular: hint_range(0.0, 1.0);
uniform float metallic: hint_range(0.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0);
uniform float proximity_fade_distance = 0.3;
uniform float refraction : hint_range(0.0,1.0) = 0.2;
uniform sampler2D normal_map: hint_normal;
uniform vec3 uv_scale = vec3(1.0, 1.0, 1.0);

//depth-fade vars
uniform float beers_law = 2.0; // Beers law value, regulates the blending size to the deep water level
uniform float depth_offset = -0.75;
uniform vec4 deep_water: hint_color;

// wave vars
uniform vec2 wave_strength = vec2(0.3, 0.2);
uniform vec2 wave_freq = vec2(12.0, 12.0);
uniform vec2 time_factor = vec2(0.5, 1.0);

// foam vars
varying float vertex_height;
uniform sampler2D foam_sampler : hint_black;
uniform float foam_strength: hint_range(0.0, 200.0) = 1.0;


float waves(vec2 pos, float time) {
	float wave_y = wave_strength.y * sin(pos.y * wave_freq.y + time * time_factor.y);
	float wave_x = wave_strength.x * sin(pos.x * wave_freq.x + time * time_factor.x);
	return wave_y + wave_x;
}

void vertex() {
	VERTEX.y += waves(VERTEX.xy, TIME);
	UV = UV*uv_scale.xy;
	
	//For foam shading in frag:
	vertex_height = (PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0) ).z;
}

void fragment() {
	
	// UV scroll anim
	vec2 uv_movement = UV;
	uv_movement += TIME * scroll_speed;
	vec4 albedo_tex = texture(texture_albedo, uv_movement);
	
	// Depth-fade
	float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = PROJECTION_MATRIX[3][2] / (depth_raw + PROJECTION_MATRIX[2][2]);
	float depth_blend = exp((depth+VERTEX.z + depth_offset) * -beers_law);
	depth_blend = clamp(1.0-depth_blend, 0.0, 1.0);	
	float depth_blend_pow = clamp(pow(depth_blend, 2.5), 0.0, 1.0);
	
	// Initial shading
	vec4 full_color = mix(albedo_tex*albedo, albedo_tex*deep_water, depth_blend_pow);
	vec3 color = full_color.rgb;
	
	// Foam
	if(depth + VERTEX.z < vertex_height-0.1){
		float foam_noise = clamp(pow(texture(foam_sampler, (UV*4.0) ).r, 10.0)*40.0, 0.0, 0.2);
		float foam_mix = clamp(pow((1.0-(depth + VERTEX.z) + foam_noise), 8.0) * foam_noise * 0.4, 0.0, 1.0);
		color = mix(color, vec3(1.0), foam_mix*foam_strength);
	}
	
	// Apply first shade
	ALBEDO = color;
	NORMAL = texture(normal_map, uv_movement).rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = full_color.a;
	
	// Refraction and edge fade - generated by Godot
	vec3 ref_normal = NORMAL;
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
	float ref_amount = 1.0 - albedo.a * albedo_tex.a;
	EMISSION += textureLod(SCREEN_TEXTURE,ref_ofs,ROUGHNESS * 8.0).rgb * ref_amount;
	ALBEDO *= 1.0 - ref_amount;
	float depth_tex = textureLod(DEPTH_TEXTURE,SCREEN_UV,0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex*2.0-1.0,1.0);
	world_pos.xyz/=world_pos.w;
	ALPHA*=clamp(1.0-smoothstep(world_pos.z+proximity_fade_distance,world_pos.z,VERTEX.z),0.0,1.0);
}