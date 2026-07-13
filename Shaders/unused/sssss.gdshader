shader_type canvas_item;
render_mode unshaded;

// Shader Uniforms
group_uniforms Texture;
		uniform sampler2D Scroll_Texture : repeat_enable, filter_nearest;
		uniform bool Use_Original_Texture = false;
group_uniforms;

group_uniforms Scrolling_Settings;
		uniform vec2 Scrolling_Speed = vec2(-1, -1);
		uniform float Time_Scale = 0.1;
		uniform float Texture_Scale = 1.0;
group_uniforms;

group_uniforms Bobbing_Settings;
		uniform float Height : hint_range(0, 16, 1) = 8;
		uniform float Cycles = 0.4;
		uniform float Offset = 0.0;
group_uniforms;

group_uniforms Echoes_Settings;
		uniform float Distance : hint_range(0, 128, 0.1) = 35.0;
		uniform int Count : hint_range(0, 8, 1) = 2;
		uniform float Fade : hint_range(0.0, 1.0, 0.01) = 0.25;
		uniform float Start_Alpha : hint_range(0.0, 1.0, 0.01) = 0.8;
		uniform float Tint_Amount : hint_range(0.0, 1.0, 0.01) = 0.5;
		uniform vec4 Tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
		uniform bool Pulse_both_Directions = false;
		uniform float Diagonal_Angle : hint_range(0, 90, 15) = 45.0;
		uniform int Echo_Blend_Mode : hint_enum("Mix","Additive") = 0; // 0 for Mix, 1 for Additive
group_uniforms;

varying float vertex_scale;

vec4 RenderEchoes(
	vec2 BaseUV,
	vec2 sScrollUVColor,
	sampler2D MainTex,
	sampler2D ScrollTex,
	vec2 sPX,
	bool UseMainTex,
	float BobOSC,
	float EchoDistPx,
	int EchoCount,
	float EchoFade,
	float EchoStartAlpha,
	float EchoTintAmount,
	vec4 EchoTint,
	bool Pulse2Direction,
	float EchoAngle,
	int EchoBlendMode
) {
		vec4 AccumEchoCol = vec4(0.0);

		float AngleRadians = radians(EchoAngle);
		vec2 BaseDirVector = vec2(cos(AngleRadians), sin(AngleRadians));

		float decay_factor = 1.0 - EchoFade;
		float inv_echo_count = 1.0 / max(1.0, float(EchoCount));

		// Pre-sample Scrolling Texture if not using original texture
		vec3 pre_sampled_scrolling_rgb = vec3(0.0);
		if (!UseMainTex) {
				pre_sampled_scrolling_rgb = texture(ScrollTex, sScrollUVColor).rgb;
		}

		for (int i = 1; i <= EchoCount; ++i){
				float CurrentEchoAlpha;
				if (i == 1) {
						CurrentEchoAlpha = EchoStartAlpha;
				} else {
						CurrentEchoAlpha = EchoStartAlpha * pow(decay_factor, float(i - 1));
				}

				CurrentEchoAlpha = max(0.0, CurrentEchoAlpha);

				if (CurrentEchoAlpha <= 0.0){
						break;
				}

				float i_norm = float(i) * inv_echo_count;

				vec3 progressive_rgb_tint = mix(vec3(1.0), EchoTint.rgb, i_norm * EchoTintAmount);

				float OffsetMagnitUV = BobOSC * EchoDistPx * float(i) * sPX.x;

				for (int j = 0; j < (Pulse2Direction ? 2 : 1); ++j){
						vec2 CurrentDispUV = BaseDirVector * ((j == 0) ? OffsetMagnitUV : -OffsetMagnitUV);
						vec2 DispUVOGShape = BaseUV - CurrentDispUV;

						vec4 CurrentEchoColor;

						if (UseMainTex) {
								CurrentEchoColor = texture(MainTex, DispUVOGShape);
						} else {
								// Use pre-sampled value for ScrollingEchoRGB
								float OGalphaAtEchoPos = texture(MainTex, DispUVOGShape).a;
								CurrentEchoColor = vec4(pre_sampled_scrolling_rgb, OGalphaAtEchoPos);
						}

						CurrentEchoColor.rgb *= progressive_rgb_tint;
						CurrentEchoColor.a *= (EchoTint.a * CurrentEchoAlpha);

						if (EchoBlendMode == 0) { // Mix
								AccumEchoCol = mix(AccumEchoCol, CurrentEchoColor, CurrentEchoColor.a);
						} else if (EchoBlendMode == 1) { // Additive
								AccumEchoCol.rgb += CurrentEchoColor.rgb * CurrentEchoColor.a;
								AccumEchoCol.a = min(1.0, AccumEchoCol.a + CurrentEchoColor.a);
						}
				}
		}
		return AccumEchoCol;
}

vec2 ScrollingUV(vec2 sUV, vec2 sPX, float time, float timespeed, vec2 scrollspd, sampler2D scrolltex) {
		vec2 T = Scrolling_Speed * time * Time_Scale;
		vec2 ScreenPixelSize = vec2(1.0) / sPX;
		vec2 TexturePixelSize = vec2(float(textureSize(Scroll_Texture, 0).x), float(textureSize(Scroll_Texture, 0).y));
		vec2 repeats = ScreenPixelSize / TexturePixelSize;
		return (sUV * repeats + T) / Texture_Scale;
}

float CalculateExpansion() {
		float estimated_sprite_size = 512.0;
		float max_echo_distance = Distance * float(Count);
		float distance_ratio = max_echo_distance / estimated_sprite_size;
		float required_expansion = (1.0 + (distance_ratio * 2.0)) * 1.2;
		return max(1.0, required_expansion);
}

void vertex() {
		vertex_scale = CalculateExpansion();
		VERTEX *= vertex_scale; // Simplified scaling
		float bob_px = sin(TAU * Cycles * TIME + Offset) * Height;
		VERTEX.y += bob_px;
}

void fragment() {
		vec2 adjusted_UV = (UV - 0.5) * vertex_scale + 0.5;
		vec2 ScreenSrollingUV = ScrollingUV(SCREEN_UV, SCREEN_PIXEL_SIZE, TIME, Time_Scale, Scrolling_Speed, Scroll_Texture);

		vec4 tex1 = texture(TEXTURE, adjusted_UV);
		vec3 tex2_scrolling_rgb = texture(Scroll_Texture, ScreenSrollingUV).rgb;

		float BobOSC = sin(TAU * Cycles * TIME + Offset);

		vec4 AccumEchoCol = RenderEchoes(
			adjusted_UV,
			ScreenSrollingUV,
			TEXTURE,
			Scroll_Texture,
			SCREEN_PIXEL_SIZE,
			Use_Original_Texture,
			BobOSC,
			Distance,
			Count,
			Fade,
			Start_Alpha,
			Tint_Amount,
			Tint,
			Pulse_both_Directions,
			Diagonal_Angle,
			Echo_Blend_Mode
		);

		vec4 MainInstCol;
		if (Use_Original_Texture){
				MainInstCol = tex1;
		} else{
				MainInstCol = vec4(tex2_scrolling_rgb * tex1.a, tex1.a);
		}

		COLOR = mix(AccumEchoCol, MainInstCol, MainInstCol.a);
}