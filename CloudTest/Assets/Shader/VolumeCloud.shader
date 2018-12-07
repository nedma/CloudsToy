Shader "Clouds/VolumeCloud"
{
	Properties
	{
		_NoiseTex("NoiseTex", 2D) = "white" {}


		_SkyColor0("Sky Color Above", Color) = (0, 0, 0, 1)
		_SkyColor1("Sky Color Below", Color) = (0, 0, 0, 1)

		_CloudColor("Cloud Color", Color) = (1, 1, 1, 1)
		_Octave0("Octave 0", 2D) = "white" {}
		_Octave1("Octave 1", 2D) = "white" {}
		_Octave2("Octave 2", 2D) = "white" {}
		_Octave3("Octave 3", 2D) = "white" {}
		_Speed("Speed", Range(0.0, 1.0)) = 0.1
		_Emptiness("Emptiness", Range(0.0, 1.0)) = 0.2
		_Sharpness("Sharpness", Range(0.0, 1.0)) = 1.0
		_cloudRange("Sharpness", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue" = "Background" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			

			#define RAY_MARCH_SAMPLE_COUNT 16

			#include "UnityCG.cginc"
			#include "VolumetricRenderingUtil.cginc"



			fixed4 _SkyColor0;
			fixed4 _SkyColor1;
			sampler2D _Octave0;
			sampler2D _Octave3;


			struct appdata
			{
				float4 vertex	: POSITION;
				float2 uv		: TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				half3 wsEyeDir : TEXCOORD1;
			};


			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);

				float4x4 o2w = Object2WorldMatrix(v);
				float3 posWorld = mul(o2w, v.vertex);
				o.wsEyeDir = (posWorld - _WorldSpaceCameraPos);

				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 fragColor = 1;


				half3 wsEyeDir = normalize(i.wsEyeDir);
				float3 entry = RaySphereIntersectFromEarth(u_AtmInnerRaidus, wsEyeDir);
				float3 exit = RaySphereIntersectFromEarth(u_AtmOutterRaidus, wsEyeDir);

				//half sampleLength = distance(entry, exit) / RAY_MARCH_SAMPLE_COUNT;

				half3 rd = normalize(exit - entry);
				fragColor = render(entry, rd, i.uv - 0.5);

				//fragColor.rgb = rd;

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return fragColor;
			}
			ENDCG
		}
	}
}
