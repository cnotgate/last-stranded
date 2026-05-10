shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
    
    float dist = distance(UV, vec2(0.5));
    
    // Modifikasi di sini: smoothstep akan mengecil sampai nol (hitam penuh) 
    // seiring bertambahnya vignette_intensity
    float radius = 0.8 * (1.0 - vignette_intensity);
    float softness = 0.6 * (1.0 - vignette_intensity);
    float vignette = smoothstep(radius, radius + softness, dist);
    
    // Mix dengan warna hitam
    color.rgb = mix(color.rgb, vec3(0.0), vignette);
    
    // Jika intensitas 1.0, paksa jadi hitam total (fading akhir)
    color.rgb = mix(color.rgb, vec3(0.0), vignette_intensity * 0.5); 
    // Atur pengali di atas (0.5 atau lebih) sesuai selera kegelapan
    
    COLOR = vec4(color.rgb, 1.0);
}