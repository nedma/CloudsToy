#pragma once


uniform float		u_WorldScale = 1;
//uniform float		u_EarthRaidus = 6000;		// km
//uniform float		u_AtmInnerRaidus = 8000;
//uniform float		u_AtmOutterRaidus = 12000;


#define u_EarthRaidus 6000
#define u_AtmInnerRaidus 8000
#define u_AtmOutterRaidus 12000


uniform half3 _cloudRange = half3(1,1,1);
uniform half3 _Wind = half3(1, 1, 1);
uniform half _NoiseMultiplier = 1;
uniform half3 _Bright = half3(1, 1, 1);
uniform half3 _Dark = half3(0.1, 0.1, 0.1);

sampler2D _NoiseTex;
float4 _NoiseTex_ST;








float noise(in float3 x)
{
	float3 p = floor(x);
	float3 f = frac(x);
	f = f*f*(3.0 - 2.0*f);

#if 1
	float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
	float2 rg = tex2Dlod(_NoiseTex, half4((uv + 0.5) / 256.0, 0.0f, 0.0f)).yx;
#else
	ivec3 q = ivec3(p);
	ivec2 uv = q.xy + ivec2(37, 17)*q.z;

	float2 rg = mix(mix(texelFetch(iChannel0, (uv) & 255, 0),
		texelFetch(iChannel0, (uv + ivec2(1, 0)) & 255, 0), f.x),
		mix(texelFetch(iChannel0, (uv + ivec2(0, 1)) & 255, 0),
			texelFetch(iChannel0, (uv + ivec2(1, 1)) & 255, 0), f.x), f.y).yx;
#endif    

	return -1.0 + 2.0 * lerp(rg.x, rg.y, f.z);
}

float map5(in float3 p)
{
	float3 q = p - float3(0.0, 0.1, 1.0) * _Time;
	float f;
	f = 0.50000*noise(q); q = q*2.02;
	f += 0.25000*noise(q); q = q*2.03;
	f += 0.12500*noise(q); q = q*2.01;
	f += 0.06250*noise(q); q = q*2.02;
	f += 0.03125*noise(q);
	return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
}

float map4(in float3 p)
{
	float3 q = p - float3(0.0, 0.1, 1.0) * _Time;
	float f;
	f = 0.50000*noise(q); q = q*2.02;
	f += 0.25000*noise(q); q = q*2.03;
	f += 0.12500*noise(q); q = q*2.01;
	f += 0.06250*noise(q);
	return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
}
float map3(in float3 p)
{
	float3 q = p - float3(0.0, 0.1, 1.0)* _Time;
	float f;
	f = 0.50000*noise(q); q = q*2.02;
	f += 0.25000*noise(q); q = q*2.03;
	f += 0.12500*noise(q);
	return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
}
float map2(in float3 p)
{
	float3 q = p - float3(0.0, 0.1, 1.0)* _Time;
	float f;
	f = 0.50000*noise(q); q = q*2.02;
	f += 0.25000*noise(q);;
	return clamp(1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0);
}


float4 integrate(in float4 sum, in float dif, in float den, in float3 bgcol, in float t)
{
	// lighting
	float3 lin = float3(0.65, 0.7, 0.75)*1.4 + float3(1.0, 0.6, 0.3)*dif;
	float4 col = float4(lerp(float3(1.0, 0.95, 0.8), float3(0.25, 0.3, 0.35), den), den);
	col.xyz *= lin;
	col.xyz = lerp(col.xyz, bgcol, 1.0 - exp(-0.003*t*t));
	// front to back blending    
	col.a *= 0.4;
	col.rgb *= col.a;
	return sum + col*(1.0 - sum.a);
}


void doRaymarch(int steps, float3 ro, float3 rd, float3 bgcol, out float4 sum)
{
	float3 sundir = _WorldSpaceLightPos0.xyz;
	float t = 0.0;

	for (int i = 0; i<steps; i++)
	{
		float3  pos = ro + t*rd;
		//if (pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99)
		//	break;

		float den = map5(pos);
		if (den>0.01)
		{
			float dif = clamp((den - map5(pos + 0.3*sundir)) / 0.6, 0.0, 1.0);
			sum = integrate(sum, dif, den, bgcol, t);
		}

		t += max(0.05, 0.02*t);
	}
}

float4 raymarch(in float3 ro, in float3 rd, in float3 bgcol, in half2 px)
{
	float4 sum = 0.0;

	float t = 0.0;//0.05*texelFetch( iChannel0, px&255, 0 ).x;
	int step = 30;


	doRaymarch(step, ro, rd, bgcol, sum);

	return clamp(sum, 0.0, 1.0);
}

float4 render(in float3 ro, in float3 rd, in half2 px)
{
	float3 sundir = _WorldSpaceLightPos0.xyz;

	// background sky     
	float sun = clamp(dot(sundir, rd), 0.0, 1.0);
	float3 col = float3(0.6, 0.71, 0.75) - rd.y*0.2*float3(1.0, 0.5, 1.0) + 0.15*0.5;
	col += 0.2*float3(1.0, .6, 0.1)*pow(sun, 8.0);

	// clouds    
	float4 res = raymarch(ro, rd, col, px);
	col = col*(1.0 - res.w) + res.xyz;

	// sun glare    
	col += 0.2*float3(1.0, 0.4, 0.2)*pow(sun, 3.0);

	return float4(col, 1.0);
}





float RaySphereIntersect(float3 r0, float3 rd, float3 s0, float sr, out float3 intersectPos)
{
	// - r0: ray origin
	// - rd: normalized ray direction
	// - s0: sphere center
	// - sr: sphere radius
	// - Returns distance from r0 to first intersecion with sphere,
	//   or -1.0 if no intersection.
	float a = dot(rd, rd);
	float3 s0_r0 = r0 - s0;
	float b = 2.0 * dot(rd, s0_r0);
	float c = dot(s0_r0, s0_r0) - (sr * sr);
	float discriminant = b*b - 4.0f * a*c;
	if (discriminant < 0.0)
	{
		intersectPos = 0.0;
		return -1.0;
	}

	float dist1 = (-b + sqrt(discriminant)) / (2.0*a);
	float dist2 = (-b - sqrt(discriminant)) / (2.0*a);
	float3 intersectPos1 = r0 + rd * dist1;
	float3 intersectPos2 = r0 + rd * dist2;

	intersectPos = intersectPos1;
	return dist1;
}


float3 RaySphereIntersectFromEarth(float radius, float3 dir)
{
	float3 exit;

	float3 pos = _WorldSpaceCameraPos;
	half dist = RaySphereIntersect(pos, dir, float3(0, -u_EarthRaidus, 0), radius, exit);


	//dist = RaySphereIntersect(_WorldSpaceCameraPos, dir, float3(0,-6000,0), 8200, exit);

	return exit;
}


#ifdef TTTT_____
#define StepCount 64


float fBM_ShaderX()
{


}

float noise(in float3 x)
{
	float3 p = floor(x);
	float3 f = frac(x);
	f = f * f*(3.0 - 2.0*f);
	float2 uv2 = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
	float2 rg = tex2Dlod(_NoiseTex, float4((uv2 + 0.5) / 256.0, 0, 0)).yx;
	return lerp(rg.x, rg.y, f.z);
}
float4 map(in float3 p, in float t)
{
	float3 pos = p;
	//d就是当前坐标距离顶部的差值
	pos.y += _cloudRange.z;
	pos /= _cloudRange.z;
	float d = -max(0.0, pos.y - _cloudRange.y / _cloudRange.z);
	float3 q = pos - _Wind.xyz * _Time.y;
	float f;
	f = 0.5000*noise(q);
	q = q * 2.02;
	f += 0.2500*noise(q);
	q = q * 2.03;
	f += 0.1250*noise(q);
	q = q * 2.01;
	f += 0.0625*noise(q);
	//算出的噪声就是我们想要的噪声，然后让d去和噪声相加，模拟当前云的颜色值。
	d += _NoiseMultiplier * f;
	d = saturate(d);
	float4 res = (float4)d;
	res.xyz = lerp(_Bright, _Dark, res.x*res.x);
	return res;
}


float4 RayMarch(in float3 ro, in float3 rd, in float zbuf)
{
	float4 sum = (float4)0;
	float dt = 0.1;
	float t = dt;

	//这个是根据方向算出完全朝上的部分
	float upStep = dot(rd, float3(0, 1, 0));
	bool rayUp = upStep;
	float angleMultiplier = 1;

	for (int i = 0; i < StepCount; i++)
	{
		//摄像机的深度图-0.1
		float distToSurf = zbuf - t;
		//从ro出发的y增加上rd的y，比例是t
		float rayPosY = ro.y + t * rd.y;
		/* Calculate the cutoff planes for the top and bottom.
		Involves some hardcoding for our particular case. */
		float topCutoff = (_CloudVerticalRange.y + _CloudGranularity * max(1., _ParallaxQuotient) + .06*t + max(0, ro.y)) - rayPosY;
		float botCutoff = rayPosY - (_CloudVerticalRange.x - _CloudGranularity * max(1., _ParallaxQuotient) - t / .06 + min(0, ro.y));
		if (distToSurf &lt; = 0.001 || (rayUp &amp; &amp; topCutoff &lt; 0) || (!rayUp &amp; &amp; botCutoff &lt; 0)) break;
		// Fade out the clouds near the max z distance
		float wt;
		if (zbuf &lt; _ProjectionParams.z - 10)
		wt = (distToSurf &gt; = dt) ? 1. : distToSurf / dt;
		else
		wt = distToSurf / zbuf;
		RaymarchStep(ro + t * rd, dt, wt, sum, t);
		t += max(dt, _CloudStepMultiplier*t*0.0011);
	}

	return saturate(sum);
}

#endif