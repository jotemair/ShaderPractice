Shader "Custom/Camera/Fog"
{
	Properties
	{
		// _MainTex (with the underscore) is sort of a keyword. In case of camera shaders it will contain the image rendered by the camera
		// Has to be added as a property as well to function
		_MainTex("Main Texture", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Geometry"
		}

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 clipPos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 wpos : TEXCOORD1;
				float3 vpos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
			};

			// Connection for the _MainTex
			sampler2D _MainTex;

			// Connection for accessing builtin depth texture
			// Camera DepthTextureMode needs to be Depth or DepthNormals
			// https://docs.unity3d.com/Manual/SL-CameraDepthTexture.html
			sampler2D _CameraDepthTexture;

			// Parameters set from script

			fixed4 _FogColor;

			fixed _FogEndAngle;
			fixed _FogAngleFalloff;

			fixed _BottomFogStartHeight;
			fixed _BottomFogMinDist;
			fixed _BottomFogDepth;

			// Variables to calculate world position from depth
			float4 _Vector_X;
			float4 _Vector_Y;
			float4 _Screen_Corner;

			v2f vert(appdata IN)
			{
				v2f OUT;

				OUT.clipPos = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv;
				OUT.wpos = mul(unity_ObjectToWorld, IN.vertex).xyz;
				OUT.vpos = IN.vertex.xyz;
				OUT.screenPos = ComputeScreenPos(OUT.clipPos);

				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				// Get the original color of the fragment
				float4 texColor = tex2D(_MainTex, IN.uv);

				// Calculate a linear zero to one depth value from the depth texture and screen position
				float depthValue = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)).r);

				// Get the world position of where the fragment would be of we projected to the camera far clip plane from the camera
				float3 fragmentFarPlaneProjectionWorldPos = (_Vector_X * IN.screenPos.x + _Vector_Y * IN.screenPos.y + _Screen_Corner);

				// Get the world space viewing direction of the camera
				float3 viewDir = (fragmentFarPlaneProjectionWorldPos - _WorldSpaceCameraPos);

				float3 vectorToNearPlaneProjection = viewDir * _ProjectionParams.w * _ProjectionParams.y;

				// Get the actual world space position of the fragment based on the depth value
				float3 worldSpacePos = _WorldSpaceCameraPos + ((viewDir - vectorToNearPlaneProjection) * depthValue) + vectorToNearPlaneProjection;

				// smoothstep(min, max, x) : Returns a smooth Hermite interpolation between 0 and 1, if x is in the range [min, max].
				float startHeight = min(_BottomFogStartHeight, _WorldSpaceCameraPos.y - _BottomFogMinDist);
				float bottomFogDepth = smoothstep(-startHeight, _BottomFogDepth - startHeight, -worldSpacePos.y);

				float angleDecay = 1.0;

				if ((viewDir.y > 0) && (depthValue == 1.0))
				{
					float pitchAngle = asin(viewDir.y / length(viewDir));

					angleDecay = smoothstep(0, _FogEndAngle, pitchAngle);
					angleDecay = 1.0 - pow(angleDecay, _FogAngleFalloff);
				}

				// Calculate the final color
				float fogDensity = saturate(max(depthValue * angleDecay, bottomFogDepth));
				float4 finalColor = fogDensity * _FogColor + (1.0 - fogDensity) * texColor;

				// finalColor = lerp(finalColor, _FogColor, bottomFogDepth);

				return finalColor;
			}

			ENDCG
		}
	}

	FallBack "Diffuse"
}
