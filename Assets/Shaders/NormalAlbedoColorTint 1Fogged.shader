// Shader group and name for categorizing
// The shader name does not need to match the filename
Shader "Custom/NormalAlbedoColorTintFogged"
{
	// Public properties seen on a material that uses this shader
	Properties
	{
		// Variable name is _Texture, display name is in quotations
		// The 2D is the type, and "black" {} is a default constructor for the 2D type (A )
		_TextureASD("Texture", 2D) = "black" {}

		// A normal texture. The "bump" is to mark the type as a bump map
		// This variable and needs to be named _NormalMap, or it won't work apperently
		_NormalMap("Normal", 2D) = "bump" {}


		_Color ("Tint", Color) = (1, 1, 1, 1)

		_FogColor ("Fog", Color) = (0, 0, 0, 0)
	}

	// You can have multiple subshaders. These run at different GPU levels on different platforms
	SubShader
	{
		// Tags affect certain properties of the shader, like when it should run in the render queue, or the render type
		// https://docs.unity3d.com/Manual/SL-SubShaderTags.html
		Tags
		{
			"RenderType" = "Opaque"
		}

		// This is the part for our CG code (C for Graphics)
		// Other parts are written HLSL (High Level Shader Language)
		CGPROGRAM
		
		// The surface is affected by our function, the material type is Lambert which affects what it can do
		// Lambert is the most basic material type, it lacks specular component (shiny spots)
		#pragma surface MyFunctionName Lambert finalcolor:FogColor vertex:Vert

		// Connect the properties defined before to our CG code
		sampler2D _TextureASD;
		sampler2D _NormalMap;

		fixed4 _Color;
		fixed4 _FogColor;

		struct Input
		{
			// Connecting to our textures, the name is uv + whatever name you had earlier, otherwise it wont't connect properly
			float2 uv_TextureASD;
			float2 uv_NormalMap;

			half fog;
		};

		void Ver(inout appdata_full)
		{
		
		}

		void FogColor()
		{
		
		}

		// The funcion name must match what was defined in the pragma
		// The signature is also given with the input and the output as an inout parameter
		void MyFunctionName(Input IN, inout SurfaceOutput o)
		{
			// Apply the texture to the albedo
			// text2D helps to unwrap and match our 2D input to the UV map
			// The .rgb part makes it so that we take the rgb colors (but not the alpha)
			o.Albedo = tex2D(_TextureASD, IN.uv_TextureASD).rgba * _Color;

			// UnpackNormal is required, because normal maps are compressed
			// Otherwise we map the textures the same as before
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
		}

		ENDCG
	}

	// Fallback if our shader does not work for some reason
	FallBack "Diffuse"
}
