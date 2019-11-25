Shader "Custom/Camera/WaterLevel"
{
	Properties
	{
		// _MainTex (with the underscore) is sort of a keyword. In case of camera shaders it will contain the image rendered by the camera
		// Has to be added as a property as well to function
		_MainTex("Main Texture", 2D) = "white" {}
	}

	SubShader
	{
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

			// Texture for the water surface
			sampler2D _WaterTexture;

			// Texture properties (not set manually, automaticly filled)
			// https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html
			// For _TexelSize, x contains 1.0/width, y contains 1.0 / height, z contains width, w contains height
			float4 _WaterTexture_TexelSize;

			// Movement of the water surface texture (x, z, speed, 0)
			float4 _WaterDirection;

			// Color tint to apply to texture
			fixed4 _ColorTint;

			// Variables to calculate world position from depth
			float4 _Vector_X;
			float4 _Vector_Y;
			float4 _Screen_Corner;

			// Water level hight
			float _WaterLevel;

			// Noise map for disturbing the water surface
			sampler2D _NoiseMap;

			// _TexelSize, x contains 1.0/width, y contains 1.0 / height, z contains width, w contains height
			float4 _NoiseMap_TexelSize;

			// Movement of the noise map (x, z, speed, strength)
			float4 _NoiseDirection;

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

				// Get the actual world space position of the fragment based on the depth value
				float3 worldSpacePos = _WorldSpaceCameraPos + viewDir * depthValue;

				// Note that the above is very slightly incorrect
				// The length of the viewDir vector is from the camera position to the far clip plane projected position of the fragment
				// On the other hand, the liner 01 depth represents going from the camera near clip plane position to the far clip plane position
				// The correct calculation would be somthing like:
				// float3 worldSpacePos = _WorldSpaceCameraPos + ((viewDir - vectorToNearPlaneProjection) * depthValue) + vectorToNearPlaneProjection;
				// However this would require additional calculationas, and if the magnitude difference between the near and far plane distances is significant, the error is minimal.

				// Ratio of how much we'd have to go along the view direction to intersect the water level
				float surfaceDistRatio = (_WaterLevel - _WorldSpaceCameraPos.y) / viewDir.y;

				// Get the world space position of the water surface
				float3 waterSurfacePoint = _WorldSpaceCameraPos + viewDir * surfaceDistRatio;

				// Get the base UV coordinates for the water texture based on the world space position of the water surface point, tiling the texture
				float2 waterCoords = float2((waterSurfacePoint.x + _WaterDirection.x * _WaterDirection.z * (_Time.x % _WaterTexture_TexelSize.w)),
					                        (waterSurfacePoint.z + _WaterDirection.y * _WaterDirection.z * (_Time.x % _WaterTexture_TexelSize.w)));

				// Get the base UV coordinates for the noise texture based on the world space position of the water surface point, tiling the texture
				float2 noiseCoords = float2((waterSurfacePoint.x + _NoiseDirection.x * _NoiseDirection.z * (_Time.x % _NoiseMap_TexelSize.w)),
					                        (waterSurfacePoint.z + _NoiseDirection.y * _NoiseDirection.z * (_Time.x % _NoiseMap_TexelSize.w)));

				// Calculate a 2D Noise based on the noise texture and strength
				float2 noiseAmmount = tex2D(_NoiseMap, noiseCoords) * _NoiseDirection.w;

				// Calculate final water texture UV coordinates including noise perturbation
				float2 waterUVpos = float2((waterCoords.x + noiseAmmount.x) % _WaterTexture_TexelSize.z, (waterCoords.y + noiseAmmount.y) % _WaterTexture_TexelSize.w);

				// Get the color from the water texture and tint it
				float4 water = tex2D(_WaterTexture, waterUVpos) * _ColorTint;

				// Check if the water level is between the camera and the fragment world space position (we actually see the water, and it's not covered by the fragment)
				bool waterLevelBetween = ((worldSpacePos.y <= _WaterLevel) && (_WaterLevel <= _WorldSpaceCameraPos.y)) ||
										 ((_WorldSpaceCameraPos.y <= _WaterLevel) && (_WaterLevel <= worldSpacePos.y));

				// Calculate the final color
				float4 finalColor = (waterLevelBetween) ? (water + (texColor * (1.0 - water.a))) : texColor;

				return finalColor;
			}

			ENDCG
		}
	}

	FallBack "Diffuse"
}
