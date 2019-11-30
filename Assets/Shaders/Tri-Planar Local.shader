Shader "Custom/Tri-Planar Local"
{
	Properties
	{
		_Texture("Texture", 2D) = "white" {}
		_Scale("Scale", Float) = 2
		_Gradient("_Gradient", Float) = 1
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Geometry"
			"IgnoreProjector" = "False"
			"RenderType" = "Opaque"
		}

		Cull Back
		ZWrite On

		CGPROGRAM

		#pragma surface surf Lambert
		#pragma exclude_renderers flash

		sampler2D _Texture;
		float _Scale;
		float _Gradient;

		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
		};

		void surf(Input IN, inout SurfaceOutput o)
		{
			float3 projNormal = normalize(pow(abs(IN.worldNormal), _Gradient)) + float3(0.0001, 0.0001, 0.0001);

			// Turn World position into local position
			float3 localPos = IN.worldPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1));

			// SIDE X
			float3 x = tex2D(_Texture, frac(localPos.zy * _Scale)) * projNormal.x;

			// SIDE Y
			float3 y = tex2D(_Texture, frac(localPos.zx * _Scale)) * projNormal.y;

			// SIDE Z	
			float3 z = tex2D(_Texture, frac(localPos.xy * _Scale)) * projNormal.z;

			float3 xy = lerp(x, y, projNormal.x / (projNormal.x + projNormal.y));
			float3 yz = lerp(y, z, projNormal.y / (projNormal.y + projNormal.z));
			float3 zx = lerp(z, x, projNormal.z / (projNormal.z + projNormal.x));

			float3 xxyz = lerp(xy, zx, projNormal.y / (projNormal.y + projNormal.z));
			float3 xyyz = lerp(yz, xy, projNormal.z / (projNormal.z + projNormal.x));
			float3 xyzz = lerp(zx, yz, projNormal.x / (projNormal.x + projNormal.y));

			o.Albedo = x + y + z - (yz + zx + xy) / 2 + (xxyz + xyyz + xyzz) / 6;
		}

		ENDCG
	}

	Fallback "Diffuse"
}