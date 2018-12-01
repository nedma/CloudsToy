// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Shadertoy/IqCloud" {
	Properties
	{
		iMouse("Mouse Pos", Vector) = (100, 100, 0, 0)
		iChannel0("iChannel0", 2D) = "white" {}
		iChannelResolution0("iChannelResolution0", Vector) = (100, 100, 0, 0)
	}

	CGINCLUDE
	#include "UnityCG.cginc"   
	#include "IqCloudLib.cginc"
	#pragma target 3.0      

	struct v2f 
	{
		float4 pos : SV_POSITION;
		float4 scrPos : TEXCOORD0;
	};

	v2f vert(appdata_base v) 
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.scrPos = ComputeScreenPos(o.pos);
		return o;
	}

	vec4 main(vec2 fragCoord)
	{
		vec4 color;

		mainImage(color, fragCoord);

		return color;
	}

	fixed4 frag(v2f _iParam) : COLOR0
	{
		vec2 fragCoord = gl_FragCoord;
		return main(gl_FragCoord);
	}
	ENDCG



	SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex vert    
			#pragma fragment frag    
			#pragma fragmentoption ARB_precision_hint_fastest     

			ENDCG
		}
	}

	FallBack Off
}