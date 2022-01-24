// SHADER FROM @Arcane Hive Games
shader_type spatial;

uniform float grass_level = 2.0;
uniform float snow_level = 18.0;
uniform float barren_land = 0.2;

varying float height_val;
varying vec3 normal;
void vertex(){
	height_val = VERTEX.y;
	normal = NORMAL;
}

void fragment(){
	vec3 dirt = vec3(0.6,0.3,0.1);
	vec3 grass = vec3(0.3,0.6,0.1);
	vec3 snow = vec3(0.7,0.7,0.7);
	
	float slope = 1.0 - normal.y;
	float base_snow = clamp((height_val), 0, 1);
	float snow_cutoff = clamp(height_val/snow_level, 0, 1);
	float slope_sq = slope+barren_land;
	slope_sq *= slope_sq;
	slope_sq = clamp(slope_sq, 0, 1);
	vec3 col = dirt;
	vec3 overhang = mix(grass, snow, (snow_cutoff));
	vec3 snowy = mix(snow, dirt, slope_sq);
	col = mix(overhang, dirt, slope_sq);

	ALBEDO = col;
}