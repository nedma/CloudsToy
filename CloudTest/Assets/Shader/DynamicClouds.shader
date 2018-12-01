// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Clouds/2D Dynamic Clouds" {
	Properties {
		_SkyColor0 ("Sky Color Above", Color) = (0, 0, 0, 1)
		_SkyColor1 ("Sky Color Below", Color) = (0, 0, 0, 1)
		 
		_CloudColor ("Cloud Color", Color) = (1, 1, 1, 1)
		_Octave0 ("Octave 0", 2D) = "white" {}
		_Octave1 ("Octave 1", 2D) = "white" {}
		_Octave2 ("Octave 2", 2D) = "white" {}
		_Octave3 ("Octave 3", 2D) = "white" {}
		_Speed ("Speed", Range(0.0, 1.0)) = 0.1
		_Emptiness ("Emptiness", Range(0.0, 1.0)) = 0.2
		_Sharpness ("Sharpness", Range(0.0, 1.0)) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Background" }
		// Pass for the sky background
		Pass {
			Cull Off


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			fixed4 _SkyColor0;
			fixed4 _SkyColor1;
			sampler2D _Octave0;
			sampler2D _Octave3;

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 col;
				col.rgb = lerp(_SkyColor1.rgb, _SkyColor0.rgb, pow(i.uv.y, 0.5));

				fixed3 starcolor0 = pow(tex2D(_Octave3, i.uv).a, 60.0) * fixed3(3.0, 3.0, 4.0) * tex2D(_Octave3, i.uv + _Time.y * 0.1).a;
				fixed3 starcolor1 = pow(tex2D(_Octave3, i.uv + half2(0.4, 0.6)).a, 60.0) * fixed3(4.0, 4.0, 3.0) * tex2D(_Octave3, i.uv + _Time.y * 0.15).a;

				col.rgb += starcolor0 + starcolor1;
				col.a = 1.0;

				return col;
			}

			ENDCG
		}

		// Pass for 2d Cloud
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			fixed4 _CloudColor;
			sampler2D _Octave0;
			sampler2D _Octave1;
			sampler2D _Octave2;
			sampler2D _Octave3;
			float4 _Octave0_ST;
			float4 _Octave1_ST;
			float4 _Octave2_ST;
			float4 _Octave3_ST;
			float _Speed;
			fixed _Emptiness;
			fixed _Sharpness;

			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				half4 uv0 : TEXCOORD0;
				half4 uv1 : TEXCOORD1;
			};

			v2f vert (appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv0.xy = TRANSFORM_TEX(v.texcoord, _Octave0) + _Time.x * 1.0 * _Speed * half2(1.0, 0.0);
				o.uv0.zw = TRANSFORM_TEX(v.texcoord, _Octave1) + _Time.x * 1.5 * _Speed * half2(0.0, 1.0);
				o.uv1.xy = TRANSFORM_TEX(v.texcoord, _Octave2) + _Time.x * 2.0 * _Speed * half2(0.0, -1.0);
				o.uv1.zw = TRANSFORM_TEX(v.texcoord, _Octave3) + _Time.x * 2.5 * _Speed * half2(-1.0, 0.0);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				fixed4 col = 0;

				float4 n0 = tex2D(_Octave0, i.uv0.xy);
				float4 n1 = tex2D(_Octave1, i.uv0.zw);
				float4 n2 = tex2D(_Octave2, i.uv1.xy);
				float4 n3 = tex2D(_Octave3, i.uv1.zw);

				float4 fbm = 0.5 * n0 + 0.25 * n1 + 0.125 * n2 + 0.0625 * n3;
				fbm = (clamp(fbm, _Emptiness, _Sharpness) -  _Emptiness)/(_Sharpness - _Emptiness);

				fixed4 ray = fixed4(0.0, 0.2, 0.4, 0.6);
				fixed amount = dot(max(fbm - ray, 0), fixed4(0.25, 0.25, 0.25, 0.25));

//				col.rgb = amount * amount * _CloudColor.rgb + 2.0 * amount * (1.0 - amount) * 0.5 + (1.0 - amount) * (1.0 - amount) * _SkyColor.rgb;
				col.rgb = amount * _CloudColor.rgb +  2.0 * (1.0 - amount) * 0.4;
				col.a = amount * 1.5;

				return col;
			}
			ENDCG
		}
	}
}
