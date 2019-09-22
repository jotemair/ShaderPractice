Shader "Custom/Toon"
{
    Properties
    {
			_Texture("Texture", 2D) = "black" {}

			_OutlineColor("Outline Color", Color) = (1,1,1,1)
			_OutlineWidth("Outline Width", Range(1.0,10.0)) = 1.1

			_AmbientLightIntensity("Ambient Light Intensity", Range(-1.0, 2.0)) = 0.0
			_DarknessTreshold("Darkness Treshold", Range(0.0, 1.0)) = 0.1

			// The [HDR] attribute makes it so that the color can be set to values outside the 0 to 1 range
			// While such values won't be rendered differently compared to 0 and 1, they can be used to achieve different effects in shaders depending on the code that uses them
			[HDR]
			_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
			_Glossiness("Glossiness", Float) = 32
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

			// The second pass is the toon shader
			Pass
			{
				// Defining tags to change how the object interacts with light
				Tags
				{
					// More on pass tags here
					// https://docs.unity3d.com/Manual/SL-PassTags.html
					"LightMode" = "ForwardBase"
					"PassFlags" = "OnlyDirectional"
				}

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				// Setting for Unity to compile all variants required for forward base rendering
				// More on shader variants here:
				// https://docs.unity3d.com/Manual/SL-MultipleProgramVariants.html
				#pragma multi_compile_fwdbase

				#include "UnityCG.cginc"

				// Needed to access things like _LightColor0, which is the color of the main directional light
				#include "Lighting.cginc"

				// Needed to use shadow map that allows us to recieve shadows on the shader
				#include "AutoLight.cginc"
				
				struct appdata
				{
					float3 normal : NORMAL;
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float3 worldNormal : NORMAL;
					float3 viewDir : TEXCOORD1;
					float4 pos : SV_POSITION;
					float2 uv : TEXCOORD0;

					SHADOW_COORDS(2)
				};

				sampler2D _Texture;
				float _AmbientLightIntensity;
				float _DarknessTreshold;
				float _Glossiness;
				float4 _SpecularColor;
				
				v2f vert(appdata IN)
				{
					v2f OUT;

					OUT.worldNormal = UnityObjectToWorldNormal(IN.normal);
					OUT.viewDir = WorldSpaceViewDir(IN.vertex);
					OUT.pos = UnityObjectToClipPos(IN.vertex);
					OUT.uv = IN.uv;

					TRANSFER_SHADOW(OUT)

					return OUT;
				}

				fixed4 frag(v2f IN) : SV_Target
				{
					// Letters used to denote certain directions when dealing with shaders and light
					// L : Direction pointing towards the light source
					// R : Direction pointing the way of the reflected light
					// V : Direction pointing towards the viewer (camera)
					// N : Direction of the surface normal
					// H : Half way between L and V ((L + V) / 2)
					// The purpose is that it's easier for calculations to compare this to N when determining the ammount of light reflected towards the viewer (camera)

					float shadow = SHADOW_ATTENUATION(IN);

					float3 normal = normalize(IN.worldNormal);
					// In simple terms, NdotL tells us how much the surface normal and the light direction aligns
					float NdotL = dot(_WorldSpaceLightPos0, normal);
					// smoothstep helps to make the transition between light and dark smoother
					// smoothstep returns a value between 0 and 1 depending where the input is between the lower and upper bounds: smoothstep(lower bound, upper bound, input)
					float lightIntensity = smoothstep(0, _DarknessTreshold / 10.0, NdotL * shadow);
					float4 light = (lightIntensity + _AmbientLightIntensity) * _LightColor0;

					float3 viewDir = normalize(IN.viewDir);
					float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
					// In simple terms, NdotH tells us how much the surface normal and the half vector described before aligns
					//   That is to say, how much the view direction aligns with the reflected light direction
					float NdotH = dot(normal, halfVector);

					float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
					float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
					float4 specular = specularIntensitySmooth * _SpecularColor;

					float4 texColor = tex2D(_Texture, IN.uv);

					// Reduce the color resolution
					texColor.r = round(texColor.r * 64.0) / 64.0;
					texColor.g = round(texColor.g * 64.0) / 64.0;
					texColor.b = round(texColor.b * 64.0) / 64.0;

					// Multiply the texture color with the light affecting it
					return texColor * (light + specular);
				}

				ENDCG
			}

			// Add a builtin shader as a pass to cast shadows
			// Not exactly sure if it's necessary, as the shader seems to be casting shadows already?
			// UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }

    FallBack "Diffuse"
}
