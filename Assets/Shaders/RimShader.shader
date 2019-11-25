Shader "Custom/RimShader"
{
    Properties
    {
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineStrength("Outline Width", Range(0.0, 10.0)) = 1
		_OutlineGradient("Outline Gradient", Range(0.0, 10.0)) = 1
    }

    SubShader
    {
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"ForceNoShadowCasting" = "True"
		}

		GrabPass { "_BackgroundTexture" }

		Pass
		{
			ZWrite Off

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed4 normal : NORMAL;
			};

			struct v2f
			{
				float4 clipPos : SV_POSITION;
				float4 scrnPos : TEXCOORD0;
				float2 uv : TEXCOORD1;
				float rimStrength : TEXCOORD2;
			};

			float4 _OutlineColor;
			float _OutlineStrength;
			float _OutlineGradient;

			sampler2D _BackgroundTexture;

			v2f vert(appdata IN)
			{
				v2f OUT;

				OUT.clipPos = UnityObjectToClipPos(IN.vertex);
				OUT.scrnPos = ComputeScreenPos(OUT.clipPos);
				OUT.uv = IN.uv;

				fixed3 objSpaceViewDir = normalize(ObjSpaceViewDir(IN.vertex));
				OUT.rimStrength = 1 - saturate(pow(dot(IN.normal, objSpaceViewDir) * _OutlineStrength, _OutlineGradient));

				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 backgroundColor = tex2Dproj(_BackgroundTexture, IN.scrnPos);

				return  (IN.rimStrength * _OutlineColor) + ((1 - IN.rimStrength) * backgroundColor);
			}

			ENDCG
		}
    }

    FallBack "Diffuse"
}
