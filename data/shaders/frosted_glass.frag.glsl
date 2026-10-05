#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
precision mediump float;
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

in vec2 sol_vtex_coord;
out vec4 outColor;

uniform vec2 sol_input_size;
uniform vec2 sol_output_size;
uniform int sol_time;
uniform sampler2D sol_texture;

// Adjustable parameters
uniform float blur_radius = 1.25;      // How much blur (1.0 - 10.0)
uniform float frost_intensity = 0.3;  // Frosted glass opacity (0.0 - 1.0)
uniform float brightness = 0.8;       // Change brightness

void main() {
    vec2 uv = sol_vtex_coord.xy;
    vec2 texel_size = 1.0 / sol_input_size;
    
    // Sample pattern for blur - creates a circular blur pattern
    vec4 color_sum = vec4(0.0);
    float total_weight = 0.0;
    
    // Multi-sample blur with radial pattern
    int samples = 12;
    float angle_step = 6.28318 / float(samples); // 2*PI / samples
    
    // Center sample
    color_sum += texture(sol_texture, uv);
    total_weight += 1.0;
    
    // First ring
    for(int i = 0; i < samples; i++) {
        float angle = float(i) * angle_step;
        vec2 offset = vec2(cos(angle), sin(angle)) * texel_size * blur_radius;
        color_sum += texture(sol_texture, uv + offset);
        total_weight += 1.0;
    }
    
    // Second ring (wider)
    for(int i = 0; i < samples; i++) {
        float angle = float(i) * angle_step + angle_step * 0.5; // Offset for better coverage
        vec2 offset = vec2(cos(angle), sin(angle)) * texel_size * blur_radius * 1.8;
        color_sum += texture(sol_texture, uv + offset) * 0.7;
        total_weight += 0.7;
    }
    
    // Average the samples
    vec4 blurred = color_sum / total_weight;
    
    // Add slight desaturation for frosted glass effect
    float gray = dot(blurred.rgb, vec3(0.299, 0.587, 0.114));
    blurred.rgb = mix(blurred.rgb, vec3(gray), frost_intensity * 0.3);
    
    // Slight brightness increase and subtle color tint
    blurred.rgb *= brightness;
    blurred.rgb = mix(blurred.rgb, blurred.rgb * vec3(1.02, 1.01, 1.03), frost_intensity * 0.5);
    
    outColor = vec4(blurred.rgb, 1.0);
}