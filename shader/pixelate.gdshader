shader_type canvas_item;

// --- Uniforms ---
uniform float pixel_size : hint_range(1.0, 256.0) = 8.0; // taille du "pixel" (en px écran)
uniform vec2 pixel_size_xy = vec2(8.0, 8.0);             // taille séparée (X,Y)
uniform bool use_separate_xy = false;                    // utiliser pixel_size_xy si true
uniform float mix_with_original : hint_range(0.0, 1.0) = 1.0; // 1 = full pixelisé
uniform bool center_pixels = true;                       // sample au centre du bloc

// --- Depuis Godot 4.5, il faut déclarer SCREEN_TEXTURE ---
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- Fragment shader ---
void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 one_pixel_uv = SCREEN_PIXEL_SIZE;

    // taille du bloc en UV
    vec2 block_uv = (use_separate_xy ? pixel_size_xy : vec2(pixel_size)) * one_pixel_uv;
    block_uv = max(block_uv, vec2(1e-6));

    vec2 grid_uv;
    if (center_pixels) {
        grid_uv = floor(uv / block_uv) * block_uv + block_uv * 0.5;
    } else {
        grid_uv = floor(uv / block_uv) * block_uv;
    }

    // on lit la couleur "pixelisée" depuis la texture écran
    vec4 pixel_col = texture(SCREEN_TEXTURE, grid_uv);
    vec4 orig_col = texture(SCREEN_TEXTURE, uv);

    COLOR = mix(orig_col, pixel_col, mix_with_original);

    // applique la texture du ColorRect (souvent blanc) pour la modulation
    COLOR *= texture(TEXTURE, UV);
}
