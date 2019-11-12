Shader "Custom/Outline"
{
    Properties
    {
		_Texture("Texture", 2D) = "black" {}

		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineWidth("Outline Width", Range(0.0, 1.0)) = 0.1
		_OutlineGradient("Outline Gradient", Range(0.0, 10.0)) = 0.0
    }

    SubShader
    {
		// The first pass draws a single color version of the object, but scaled up
		// The second pass will render the object as is over the first pass
		Pass
		{
			// Cull Front makes it so we render the back side of the object, so that will make the second pass render over it, because it will be in front of it
			Cull Front

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
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float _OutlineWidth;
			float4 _OutlineColor;
			float _OutlineGradient;

			float v3Mag(float3 vec)
			{
				return sqrt((vec.x * vec.x) + (vec.y * vec.y) + (vec.z * vec.z));
			}

			v2f vert(appdata IN)
			{
				// By projecting the (zero, zero, zero) point and the (one, one, one) point of the object into the world, and taking the difference, we get the scale of the object
				float3 objScale = float3(1, 1, 1);
				objScale.x = v3Mag(mul(unity_ObjectToWorld, float3(1, 0, 0)) - mul(unity_ObjectToWorld, float3(0, 0, 0)));
				objScale.y = v3Mag(mul(unity_ObjectToWorld, float3(0, 1, 0)) - mul(unity_ObjectToWorld, float3(0, 0, 0)));
				objScale.z = v3Mag(mul(unity_ObjectToWorld, float3(0, 0, 1)) - mul(unity_ObjectToWorld, float3(0, 0, 0)));

				// Inversly scale the outline width with the object scale, and add it to one
				// This way, the outline will be a fixed width regardless of object scale
				float3 outlineScale = float3(1, 1, 1) + float3(_OutlineWidth, _OutlineWidth, _OutlineWidth) / objScale;

				// Get camera view direction
				float3 viewDir = normalize((mul(unity_ObjectToWorld, IN.vertex).xyz - _WorldSpaceCameraPos.xyz));

				// Scale up the local vertex positions by the outline width value to make the object appear bigger
				IN.vertex.xyz *= outlineScale;
				IN.vertex.xyz = mul(unity_WorldToObject, mul(unity_ObjectToWorld, IN.vertex.xyz) + viewDir * 2.0);
				v2f OUT;

				OUT.pos = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv;

				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				return _OutlineColor;
			}

			ENDCG
		}

		// The second pass is a vertex shader for texture rendering
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
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _Texture;
			
			v2f vert(appdata IN)
			{
				v2f OUT;

				OUT.pos = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv;

				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				float4 texColor = tex2D(_Texture, IN.uv);
				return texColor;
			}

			ENDCG
		}
    }

    FallBack "Diffuse"
}
