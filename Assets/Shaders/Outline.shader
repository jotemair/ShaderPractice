Shader "Custom/Outline"
{
    Properties
    {
		_Texture("Texture", 2D) = "black" {}

		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineWidth("Outline Width", Range(1.0,10.0)) = 1.1
    }

    SubShader
    {
		// The first pass draws a single color version of the object, but scaled up
		// The second pass will render the object as is over the first pass
		Pass
		{
			// ZWrite Off also works, but for some reason only in editor view
			// Call front makes it so we render the back side of the object, so that will make the second pass render over it, because it will be in front of it
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

			v2f vert(appdata IN)
			{
				// Scale up the local vertex positions by the outline width value to make the object appear bigger
				IN.vertex.xyz *= _OutlineWidth;
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
