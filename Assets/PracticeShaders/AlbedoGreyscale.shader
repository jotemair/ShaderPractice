Shader "Custom/AlbedoGreyscale"
{
    Properties
    {
		// Texture public property
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

		// A public property that has a value in a range. (Unity will show it as a slider)
        _EffectAmmount ("Effect Ammount", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags
		{
			"RenderType" = "Transparent"
			"IgnoreProjector" = "True"
			"Queue" = "Transparent"
		}

        LOD 200

        CGPROGRAM

		// The alpha in the pragma indicates that we will be making use of the alpha channel
        #pragma surface Surf Lambert alpha

        sampler2D _MainTex;
		uniform float _EffectAmmount;

		struct Input
		{
			float2 uv_MainTex;
		};

		void Surf(Input IN, inout SurfaceOutput o)
		{
		// Instead of directly passing the mapped color to the Albedo, we store it in a half4, since we will be changing it
			half4 c = tex2D(_MainTex, IN.uv_MainTex);

			// We lerp between the original colors and a greyscale image
			// The greyscale color is created by multiplying the different color channels with different ammounts (values found through experimentation)
			// Since the result is a single number, it will be used for all channels, thus it will be grey
			o.Albedo = lerp(c.rgb, dot(c.rgb, float3(0.3, 0.59, 0.11)), _EffectAmmount);

			// Get the transparency from the original image
			o.Alpha = c.a;
		}

        ENDCG
    }

	// The FallBack shader is just a link to a different shader (Found under Legacy Shaders in the shader menu)
    FallBack "Transparent/VertexLit"
}
