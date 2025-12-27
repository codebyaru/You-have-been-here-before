shader_type canvas_item;

// --- INPUTS ---
uniform sampler2D custom_texture;
uniform int cooldown_progress : hint_range(0, 100) = 100;

// --- COLORS ---
uniform vec4 active_color : source_color = vec4(0.2, 0.7, 0.2, 1.0);  // Green Border
uniform vec4 cooldown_color : source_color = vec4(0.7, 0.2, 0.2, 1.0);  // Red Border
uniform float border : hint_range (0.0, 0.5) = 0.05;

// --- NEW: UNLOCK EFFECT VARS ---
uniform float unlock_progress : hint_range(0.0, 2.0) = 0.0; // 0 = Off. Gets tweened from 0 to 2.
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 0.8, 1.0); // Golden/White Shine

void fragment() {
    vec2 uv = UV;
    float progress = float(cooldown_progress) / 100.0;
    
    vec4 final_color = vec4(0.0);
    
    // Check if we are drawing the Border or the Center
    bool is_border = (uv.x < border || uv.x > 1.0 - border || uv.y < border || uv.y > 1.0 - border);
    
    // ------------------------------------------
    // 1. EXISTING COOLDOWN LOGIC (UNCHANGED)
    // ------------------------------------------
    if (is_border) {
        float dist = 0.0;
        if (uv.y < border) { dist = uv.x; } 
        else if (uv.x > 1.0 - border) { dist = 1.0 + uv.y; } 
        else if (uv.y > 1.0 - border) { dist = 2.0 + (1.0 - uv.x); } 
        else { dist = 3.0 + (1.0 - uv.y); }
        
        float perimeter_pos = dist / 4.0;
        
        if (perimeter_pos > progress) {
            final_color = cooldown_color;
        } else {
            final_color = active_color;
        }
    } 
    else {
        vec4 tex_color = texture(custom_texture, uv);
        
        // Cooldown Grayscale Logic
        if (1.0 - uv.y > progress) {
            float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
            tex_color.rgb = vec3(gray) * 0.5; 
        }
        
        final_color = tex_color;
    }

    // ------------------------------------------
    // 2. NEW: UNLOCK SHINE EFFECT (OVERLAY)
    // ------------------------------------------
    // Ye logic tabhi chalega jab script se unlock_progress > 0 hoga
    if (unlock_progress > 0.0) {
        
        // A. Diagonal Shine Line (Sweep from top-left to bottom-right)
        // Math: x + y creates a diagonal gradient. We subtract unlock_progress to move it.
        float shine_pos = (uv.x + uv.y) * 0.5; 
        float shine_width = 0.15;
        
        // Create a sharp beam moving across
        float beam = smoothstep(unlock_progress - shine_width, unlock_progress, shine_pos) 
                   - smoothstep(unlock_progress, unlock_progress + shine_width, shine_pos);
        
        // B. Flash/Pulse (Whole icon glows bright at the start)
        float flash = 1.0 - clamp(unlock_progress * 1.5, 0.0, 1.0); // Fades out quickly
        
        // Combine Beam and Flash
        vec3 shine_effect = shine_color.rgb * (beam * 2.0 + flash * 0.5);
        
        // Add to final color (Additive Blending for Glow)
        final_color.rgb += shine_effect;
    }
    
    COLOR = final_color;
}