Shader "Custom/ForceField"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Scale("Scale", Range(0.1, 10)) = 1
		_Gradient("Gradient", Range(0.1, 10)) = 1
		_TintColor("TintColor", Color) = (1,1,1,1)

		_ScrollSpeedX("Scroll X Speed", Range(-10, 10)) = 2
		_ScrollSpeedY("Scroll Y Speed", Range(-10, 10)) = 0
		_ScrollSpeedZ("Scroll Z Speed", Range(-10, 10)) = 0

		_Fresnel("Fresnel Intensity", Range(0.1, 200)) = 3.0
		_FresnelWidth("Fresnel Width", Range(0, 5)) = 3.0

		_Distort("Distort", Range(0, 100)) = 1.0
		_IntersectionThreshold("Intersection", range(0, 1)) = .1
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Overlay"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"ForceNoShadowCasting" = "True"
		}

		GrabPass { "_BackgroundTexture" }

		Pass
		{
			Lighting Off
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				fixed4 vertex : POSITION;
				fixed4 normal : NORMAL;
				fixed3 uv : TEXCOORD0;
			};

			struct v2f
			{
				fixed4 clipPos : SV_POSITION;
				fixed rimStrength : TEXCOORD0;
				fixed4 scrnPos : TEXCOORD1;
				fixed3 worldNormal : TEXCOORD2;
				fixed3 worldPos : TEXCOORD3;
			};

			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			fixed4 _MainTex_TexelSize;

			fixed _Scale;
			fixed _Gradient;

			fixed4 _TintColor;

			fixed _ScrollSpeedX;
			fixed _ScrollSpeedY;
			fixed _ScrollSpeedZ;

			sampler2D _CameraDepthTexture;

			sampler2D _BackgroundTexture;
			fixed4 _BackgroundTexture_ST;
			fixed4 _BackgroundTexture_TexelSize;

			fixed _Fresnel;
			fixed _FresnelWidth;
			
			fixed _Distort;
			fixed _IntersectionThreshold;

			v2f vert(appdata v)
			{
				v2f OUT;

				// https://docs.unity3d.com/Manual/SL-BuiltinFunctions.html
				OUT.clipPos = UnityObjectToClipPos(v.vertex);

				// ObjSpaceViewDir returns object space direction (not normalized) from given object space vertex position towards the camera.
				fixed3 objSpaceViewDir = normalize(ObjSpaceViewDir(v.vertex));

				// Fresnel

				// saturate(x) : Clamps the specified value within the range of 0 to 1.
				// For vectors of unit length, the dot product gives a value that indicates how much the vectors align
				//   1 if they point in the same direction, 0 if they are perpendicular and -1 if they point in opposite directions

				// The following formula will be zero if the vertex normal points towards the camera, and goes to one as it turns away from it
				fixed normalFacingAwayFromCamera = 1 - saturate(dot(v.normal, objSpaceViewDir));

				// smoothstep(min, max, x) : Returns a smooth Hermite interpolation between 0 and 1, if x is in the range [min, max].

				// The following formula will return a value between 0 and 0.5 depending on how much the surface normal faces away from the camera
				// Note that with flat objects, such as cubes, the dot product style rim calculation will not result in a gradient,
				//   rather it will be same for any point on a particular face
				OUT.rimStrength = smoothstep(1 - _FresnelWidth, 1.0, normalFacingAwayFromCamera) * 0.5f;

				// Computes texture coordinate for doing a screenspace-mapped texture sample. Input is clip space position.
				OUT.scrnPos = ComputeScreenPos(OUT.clipPos);

				// The following macro only works, if the input appdata paramater is named 'v'
				// https://docs.unity3d.com/Manual/SL-DepthTextures.html
				COMPUTE_EYEDEPTH(OUT.scrnPos.z);

				OUT.worldNormal = UnityObjectToWorldNormal(v.normal);

				fixed repeatModulo = _MainTex_TexelSize.z * _MainTex_TexelSize.w;
				OUT.worldPos = mul(unity_ObjectToWorld, v.vertex)
					+ fixed3((_Time.x * _ScrollSpeedX) % repeatModulo, (_Time.x * _ScrollSpeedY) % repeatModulo, (_Time.x * _ScrollSpeedZ) % repeatModulo);

				return OUT;
			}

			// https://docs.unity3d.com/Manual/SL-ShaderSemantics.html
			// VFACE input positive for frontbaces, negative for backfaces.
			fixed4 frag(v2f IN, fixed facing : VFACE) : SV_Target
			{
				// Intersection

				// Get the depth value from the depth texture, and convert it to a linear 0 1 range value
				float linearBackgroundDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, IN.scrnPos).r);

				// Previously, we computed the depth value of the vertex, and stored it in the z of the screenPos value,
				//   we use this to calculate depth difference between the object and the background
				float depthDiff = abs(linearBackgroundDepth - IN.scrnPos.z);

				// The intersect value is near zero if the point depth is close to the background depth, and one if it's far
				// The _IntersectionThreshold value is between 0 and 1. If it's small, the depth difference needs to be very small to get a saturate value less than 1
				//   This effectively controls how close the point on the object needs to be to the background to be considered intersecting
				fixed intersect = saturate((depthDiff) / _IntersectionThreshold);

				// Get triplanar texture (no overlap correction)
				fixed3 projNormal = normalize(pow(abs(IN.worldNormal), _Gradient)) + float3(0.0001, 0.0001, 0.0001);
				fixed3 localPos = IN.worldPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
				fixed3 x = tex2D(_MainTex, frac(localPos.zy * _Scale)) * projNormal.x;
				fixed3 y = tex2D(_MainTex, frac(localPos.zx * _Scale)) * projNormal.y;
				fixed3 z = tex2D(_MainTex, frac(localPos.xy * _Scale)) * projNormal.z;
				fixed3 mainTextureColor = x + y + z;

				// Distortion

				// Shift the screen coordinates based on the main textures read and grean color channel to distort background
				IN.scrnPos.xy += (mainTextureColor.rg * 2 - 1) * _Distort * _BackgroundTexture_TexelSize.xy;
				fixed3 distortedBackgroundColor = tex2Dproj(_BackgroundTexture, IN.scrnPos);

				// Apply tint color to the distorted background image
				distortedBackgroundColor *= (_TintColor * _TintColor.a) + 1;

				// The above is short for the following
				// distortedBackgroundColor = fixed3(
				// 	(distortedBackgroundColor.r * ((_TintColor.r * _TintColor.a) + 1)),
				// 	(distortedBackgroundColor.g * ((_TintColor.g * _TintColor.a) + 1)),
				// 	(distortedBackgroundColor.b * ((_TintColor.b * _TintColor.a) + 1))
				// );

				// Intersect hightlight

				// rimIntersect is a combination of rimStrength and intersect, meaning that the value is greater if the point is both a rim, and it also 'intersects'
				// The value is closer to zero if one of those properties isn't met, and it's zeroed out for back faces
				fixed rimIntersect = IN.rimStrength * intersect * saturate(facing);

				// pow(x, y) : x is raised to the power of y

				// We adjust the main texture color with the tint color, the adjusted color will be stronger near the 'sides' and weaker facing the camera
				fixed3 adjustedMainTextureColor = mainTextureColor * _TintColor * pow(_Fresnel, rimIntersect);

				// Mix colors

				// We lerp between the distorted background color and the adjusted main texture color
				fixed3 finalColor = lerp(distortedBackgroundColor, adjustedMainTextureColor, rimIntersect);

				// We add a solid rim intersection edge coloring
				finalColor += (1 - intersect) * _TintColor * _Fresnel;

				return fixed4(finalColor, .9);
			}

			ENDCG
		}
	}

	Fallback "Diffuse"
}