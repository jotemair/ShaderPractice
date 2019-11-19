Shader "Custom/Outline"
{
    Properties
    {
		_MainTex ("Texture", 2D) = "white" {}
		_TintColor("Tint Color", Color) = (1,1,1,1)

		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineWidth("Outline Width", Range(0.0, 1.0)) = 0.1
		_OutlineGradient("Outline Gradient", Range(0.0, 10.0)) = 0.0
    }

    SubShader
    {
		// The first pass draws a single color version of the object, but scaled up
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

			v2f vert(appdata IN)
			{
				// Get the scaling of the object
				float3 objScale = float3(1, 1, 1);
				objScale.x = length(mul(unity_ObjectToWorld, float3(1, 0, 0)) - mul(unity_ObjectToWorld, float3(0, 0, 0)));
				objScale.y = length(mul(unity_ObjectToWorld, float3(0, 1, 0)) - mul(unity_ObjectToWorld, float3(0, 0, 0)));
				objScale.z = length(mul(unity_ObjectToWorld, float3(0, 0, 1)) - mul(unity_ObjectToWorld, float3(0, 0, 0)));

				// Inversly scale the outline width with the object scale, and add it to one
				// This way, the outline will be a fixed width regardless of object scale
				float3 outlineScale = float3(1, 1, 1) + float3(_OutlineWidth, _OutlineWidth, _OutlineWidth) / objScale;

				// Scale up the local vertex positions by the outline width value to make the object appear bigger
				IN.vertex.xyz *= outlineScale;

				// Get camera view direction to the scaled vertex position
				float3 viewDir = normalize((mul(unity_ObjectToWorld, IN.vertex).xyz - _WorldSpaceCameraPos.xyz));

				// Move the vertexes back along the view direction
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

		// The second pass renders textures colors and shadows on the object
		Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            // compile shader into multiple variants, with and without shadows
            // (we don't care about any lightmaps yet, so skip these variants)
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            // shadow helper functions and macros
            #include "AutoLight.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                SHADOW_COORDS(1) // put shadows data into TEXCOORD1
                fixed3 diff : COLOR0;
                fixed3 ambient : COLOR1;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0.rgb;
                o.ambient = ShadeSH9(half4(worldNormal,1));
                // compute shadows data
                TRANSFER_SHADOW(o)
                return o;
            }

            sampler2D _MainTex;
			fixed4 _TintColor;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _TintColor;
                // compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
                fixed shadow = SHADOW_ATTENUATION(i);
                // darken light's illumination with shadow, keep ambient intact
                fixed3 lighting = i.diff * shadow + i.ambient;
                col.rgb *= lighting;
                return col;
            }

            ENDCG
        }
		
		// The third pass handles casting of shadows
		// shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
			{ 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}
