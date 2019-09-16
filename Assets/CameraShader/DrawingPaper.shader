Shader "Custom/DrawingPaper"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _PaperTexture ("Base (RGB)", 2D) = "white" {}
        _TimeX ("Time", Range(0,1)) = 1
        _ScreenRect ("Screen Rect", Vector) = (0, 0, 0, 0)
    }

	SubShader
	{
		Pass
		{
			Cull Off ZWrite Off ZTest Always

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma target 3.0
			#pragma glsl

			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _PaperTexture;

			uniform float4 _PencilColor;
			uniform float4 _BackColor;

			uniform float _TimeX;
			uniform float _PencilSize;
			uniform float _PencilCorrection;
			uniform float _Intesity;
			uniform float _AnimationSpeed;
			uniform float _CornerLoss;
			uniform float _PaperFadeIn;
			uniform float _PaperFadeColor;

			uniform float2 _MainTex_TexelSize;

			struct appdata_t
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			v2f vert(appdata_t IN)
			{
				v2f OUT;

				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.color = IN.color;
				OUT.texcoord = IN.texcoord;

				return OUT;
			}

			half4 _MainTex_ST;

			float3 frag(v2f input) : COLOR
			{
				float2 uvst = UnityStereoScreenSpaceUVAdjust(input.texcoord, _MainTex_ST);
				float2 uv = uvst;

				#if UNITY_STARTS_AT_TOP

				if (_MainTex_TexelSize.y < 0)
				{
					uv.y = 1 - uv.y;
				}

				#endif

				float4 originalImage = tex2D(_MainTex, uvst);
				float3 paper = tex2D(_PaperTexture, uv).rgb;
				float ce = 1;
				float4 tex1[4];
				float4 tex2[4];
				float tex = _PencilSize;
				float t = _TimeX * _AnimationSpeed;
				float s = floor(sin(t * 10) * 0.02) / 12;
				float c = floor(cos(t * 10) * 0.02) / 12;
				float dist = float2(c + paper.b * 0.02, s + paper.b * 0.02);

				tex2[0] = tex2D(_MainTex, uvst + float2( tex, 0) + dist / 128);
				tex2[1] = tex2D(_MainTex, uvst + float2(-tex, 0) + dist / 128);
				tex2[2] = tex2D(_MainTex, uvst + float2(0,  tex) + dist / 128);
				tex2[3] = tex2D(_MainTex, uvst + float2(0, -tex) + dist / 128);

				for (int i = 0; i < 4; ++i)
				{
					tex1[i] = saturate(1 - distance(tex2[i].r, originalImage.r));
					tex1[i] *= saturate(1 - distance(tex2[i].g, originalImage.g));
					tex1[i] *= saturate(1 - distance(tex2[i].b, originalImage.b));
					tex1[i] = pow(tex1[i], _PencilCorrection * 25);
					ce *= dot(tex1[i], 1);
				}

				float3 ax = 1 - saturate(ce);
				ax *= paper.b;
				ax *= _Intesity * _Intesity * 1.5;
				float gg = lerp(1 - paper.g, 0,1 - _CornerLoss);
				ax = lerp(ax, float3(0,0,0), gg);

				paper.rgb = paper.rrr;
				paper.rgb *= float3(0.695, 0.496, 0.3125) * 1.2;
				paper = lerp(paper.rgb, _BackColor.rgb, _PaperFadeIn);
				paper = lerp(paper, _PencilColor.rgb, ax);
				paper -= gg * 0.1;
				paper = lerp(originalImage, paper, _PaperFadeColor);

				return float4(paper, 1.0);
			}

			ENDCG
		}
	}
}
