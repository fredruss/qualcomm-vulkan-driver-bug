// Trees and grass: the KayKit palette texture, and a vertex sway that grows with the height.
shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float sway = 0.04;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = TIME * 1.7 + origin.x * 0.35 + origin.z * 0.27;
	VERTEX.xz += vec2(sin(phase), cos(phase * 0.8)) * sway * max(VERTEX.y, 0.0);
}

void fragment() {
	ALBEDO = texture(albedo_texture, UV).rgb;
	ROUGHNESS = 0.8;
}
