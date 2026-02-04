shader_type spatial;

uniform float pixelScale = 256.0; //scale of pixels. 32 for a 32x32 sprite etc
uniform float minWidth : hint_range(-0.5, 0.5, 0.01) = 0.1; //inner width
uniform float maxWidth : hint_range(0.0, 0.5, 0.01) = 0.5; //outer width
uniform float maxRandomness : hint_range(0.0, 1.0, 0.01) = 0.05; //random thickness around edge
uniform float visibleLength : hint_range(0.0, 1.0, 0.01) = 1.0; //use to animate the length without affecting other parameters

uniform sampler2D thicknessGradient : filter_nearest, repeat_disable; //gradient for thickness
uniform sampler2D trimGradient : filter_nearest, repeat_disable; //gradient for thickness, applied after randomness
uniform sampler2D color : filter_linear, repeat_disable; //gradient for color
uniform float dither : hint_range(0.0, 2.0, 0.01); //amount of dither

uniform float animFPS = 8.0; //rounds TIME to a FPS

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = floor(UV * pixelScale) / pixelScale;
    float dist = uv.x - 0.5; // Use the x coordinate for linear placement
    float dist2 = uv.y;
	float dist3 = length(vec2(uv.x - 0.5, uv.y-1.0));

    float r = random(vec2(dist - floor(TIME * animFPS), uv.y)) * maxRandomness;

    float maxThickness = maxWidth - minWidth;
    float thickness = texture(thicknessGradient, vec2(uv.y, 0.0)).r; // Fixed texture lookup
    float t = maxThickness * thickness * 0.5 + r;

    // Check if the current point is within the desired thickness range
    if (dist >= t + minWidth || dist <= -t - minWidth) {
        discard;
    }
	
	float trim = texture(trimGradient, vec2(uv.y, 0.0)).r;
	//trim = maxThickness * trim * 0.5;
	if (dist >= trim || dist <= -trim) {
        discard;
    }

    // Ensure we only render within the specified visible length
    if (uv.y > visibleLength) {
        discard;
    }

    ALBEDO.rgb = texture(color, vec2(0.0, 0.0)).rgb;

    // Dither effect
    vec2 d = mod(floor(UV * pixelScale), vec2(2.0, 2.0));
    if (length(d) > dither * (2.0 - dist3)) {
        discard;
    }
}
