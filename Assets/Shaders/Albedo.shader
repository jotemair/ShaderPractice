// Shader group and name for categorizing
Shader "Custom/Albedo"
{
	// Public properties seen on a material that uses this shader
	Properties
	{
		// Variable name is _Texture, display name is in quotations
		// The 2D is the type, and "black" {} is a default constructor for the 2D type (A )
		_Texture("Texture", 2D) = "black" {}
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
		#pragma surface MyFunctionName Lambert

		// Connect the property defined before to our CG code
		sampler2D _Texture;

		struct Input
		{
			// This is to refer to the UV map of our model
			float2 uv_Texture;
		};

		// The funcion name must match what was defined in the pragma
		// The signature is also given with the input and the output as an inout parameter
		void MyFunctionName(Input IN, inout SurfaceOutput o)
		{
			// Apply the texture to the albedo
			// text2D helps to unwrap and match our 2D input to the UV map
			// The .rgb part makes it so that we take the rgb colors (but not the alpha)
			o.Albedo = tex2D(_Texture, IN.uv_Texture).rgb;
		}

		ENDCG
	}

	// Fallback if our shader does not work for some reason
	FallBack "Diffuse"
}
