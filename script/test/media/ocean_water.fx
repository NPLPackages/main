
float4x4 mWorldViewProj : WorldViewProjection;
float4x4 mWorld :World;
float3 g_EyePositionW	:worldcamerapos;

half3 sun_vec	:sunvector;
half3 sun_color	:suncolor;

//water reflection map
Texture tex1;
//normal map
Texture tex0;

//custom parameter
half3 shallowWaterColor;
half3 deepWaterColor;
float2 waveDir;

half shininess	:specularPower;
float time	:time;
half3 texCoordOffset;

sampler2D tex0Sampler  :register(s0) = sampler_state{
	texture = <tex0>;
	mipfilter = linear;
	minfilter = linear;
	magfilter = linear;
	AddressU = mirror;
	AddressV = mirror;
};

sampler2D tex1Sampler : register(s1) = sampler_state{
	texture = <tex1>;
	mipfilter = linear;
	minfilter = linear;
	magfilter = linear;
	AddressU = mirror;
	AddressV = mirror;
};


void vs_main(
    inout float4 pos  : POSITION,
    inout float2 texCoord :TEXCOORD0,
    out float2 disturbTexCoord1 :TEXCOORD1,
    out float2 disturbTexCoord2 :TEXCOORD2,
    out half3 halfVector:TEXCOORD4)
{
	half3 worldPos = mul(pos,mWorld);
	pos = mul(pos,mWorldViewProj);
	half3 viewDir = normalize(g_EyePositionW - worldPos);
	halfVector = sun_vec - viewDir;
	texCoord = texCoord;
	disturbTexCoord1 = texCoord/2 + time * 0.02*waveDir;
	disturbTexCoord2 = texCoord/3 + time * 0.03*waveDir;
}

void ps_main(in float2 texCoord: TEXCOORD0,
	in float2 waveCoord1 :TEXCOORD1,
	in float2 waveCoord2 :TEXCOORD2,
	in half3 halfVector:TEXCOORD4,
	out half4 color :COLOR)
{
	float2 tempTexCoord = (texCoord + texCoordOffset.yz)*texCoordOffset.x;
	float height = tex2D(tex0Sampler ,tempTexCoord).w;
	
	half3 bump1 = tex2D(tex0Sampler ,waveCoord1).xyz;
	half3 bump2 = tex2D(tex0Sampler ,waveCoord2).xyz;
	half3 finalWaveBump  = normalize(bump1 + bump2 - 1);
	
	tempTexCoord = (texCoord  + finalWaveBump.xy * 0.1 + texCoordOffset.yz) * texCoordOffset.x;
	tempTexCoord.x += time * 0.01;
	half3 reflectColor = tex2D(tex1Sampler,tempTexCoord);
	
	half3 waterColor = lerp(shallowWaterColor,deepWaterColor,height);
	
	halfVector = normalize(halfVector);
	half specular = pow( saturate( dot(finalWaveBump,halfVector)),shininess);
	
	half diffuse = saturate(dot(finalWaveBump,float3(0,1,0)));
	diffuse = diffuse*0.3 + 0.7;

	color.xyz = reflectColor* waterColor*diffuse + specular*sun_color;
	color.w = 1;
}

technique SimpleMesh_vs30_ps30
{
    pass P0
    {
		FogEnable = false;
        vertexShader = compile vs_1_1 vs_main();
        pixelShader = compile ps_2_0 ps_main();
    }
}
