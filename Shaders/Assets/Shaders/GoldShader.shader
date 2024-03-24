Shader "AA1/Gold"
{
    Properties
    {
        [Header(Unity Standard Properties)]
        _ShadowStrength("Unity Shadow Strength", Range(0,1)) = 0.75
        _DMetalProperty("Unity Diffuse Metal Property", Range(0,1)) = 1
        _Exposure("Unity Exposure", Range(1,10)) = 1
        _FresnelPower("Unity Fresnel Power", Range(0.001,10)) = 5
        _FresnelColor("Unity Fresnel Color", Color) = (0.5, 0.5, 0.5, 1.0)


        [Header(Albedo)]
        _AlbedoMap("Albedo Map", 2D) = "white" {}
        _AlbedoColor("Albedo Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Sharpness("Sharpness", Range(0, 1)) = 0.5

        [Header(Metalness)]
        _MetalnessMap("Metalness Map", 2D) = "black" {}
        _Metalness("Metalness", Range(0,1)) = 0

        [Header(Roughness)]
        _RoughnessMap("Roughness Map", 2D) = "black" {}
        _Roughness("Roughness", Range(0,1)) = 0

        [Header(Occlusion)]
        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _Occlusion("Occlusion", Range(0,1)) = 0

        [Header(Normal)]
        _NormalMap("Normal Map", 2D) = "white" {}
        _NormalStrength("Normal Strength", Range(0,1)) = 1.0
    }

        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

            Pass
            {
                Blend SrcAlpha OneMinusSrcAlpha

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "UnityCG.cginc"

                #define _PI 3.14159265359

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float4 tangent : TANGENT;
                };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                    float3 tangent : TEXCOORD1;
                    float3 binormal : TEXCOORD2;
                    float4 col : COLOR;
                    float3 worldPos : TEXCOORD3;
                };

                float4 _AlbedoColor, _FresnelColor;

                sampler2D _AlbedoMap;
                float4 _AlbedoMap_ST;
                sampler2D _MetalnessMap;
                float4 _MetalnessMap_ST;
                sampler2D _RoughnessMap;
                float4 _RoughnessMap_ST;
                sampler2D _OcclusionMap;
                float4 _OcclusionMap_ST;
                sampler2D _NormalMap;
                float4 _NormalMap_ST;

                float _Sharpness;
                float _ShadowStrength, _DMetalProperty, _Exposure, _FresnelPower;
                float _Metalness, _Roughness, _Occlusion, _NormalStrength;


                //----------------------[[[[[ FUNCTIONS ]]]]]------------------------------------------------           
                //1. Schlick Fresnel Functions---------------------------------------------------------------
                float SchlickFresnel(float i)
                {
                    float x = clamp(1.0 - i, 0.0, 1.0);
                    float x2 = x * x;
                    return x2 * x2 * x;
                }

                float3 FresnelLerp(float3 x, float3 y, float d)
                {
                    float t = SchlickFresnel(d);
                    return lerp(x, y, t);
                }

                float3 SchlickFresnelFunction(float3 SpecularColor, float LdotH)
                {
                    return SpecularColor + (1 - SpecularColor) * SchlickFresnel(LdotH);
                }

                //2. Normal Incidence Reflection Calculation-------------------------------------------------
                float F0(float NdotL, float NdotV, float LdotH, float roughness)
                {
                    // Diffuse fresnel
                    float FresnelLight = SchlickFresnel(NdotL);
                    float FresnelView = SchlickFresnel(NdotV);
                    float FresnelDiffuse90 = 0.5 + 2.0 * LdotH * LdotH * roughness;
                    float MixFLight = (FresnelDiffuse90 * FresnelLight + 1.0 * (1.0 - FresnelLight));
                    float MixFView = (FresnelDiffuse90 * FresnelView + 1.0 * (1.0 - FresnelView));
                    return MixFLight * MixFView;
                }

                //3. Normal Distribution Functions-----------------------------------------------------------
                float GGXNormalDistribution(float roughness, float NdotH)
                {
                    float roughnessSqr = roughness * roughness;
                    float NdotHSqr = NdotH * NdotH;
                    float TanNdotHSqr = (1 - NdotHSqr) / NdotHSqr;
                    float sqrResult = roughness / (NdotHSqr * (roughnessSqr + TanNdotHSqr));
                    return (1.0 / _PI) * (sqrResult * sqrResult);
                }

                //4. Geometric Shadowing Functions-----------------------------------------------------------
                float GGXGeometricShadowingFunction(float NdotL, float NdotV, float roughness)
                {
                    float roughnessSqr = roughness * roughness;
                    float NdotLSqr = NdotL * NdotL;
                    float NdotVSqr = NdotV * NdotV;
                    float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotLSqr));
                    float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotVSqr));
                    float Gs = (SmithL * SmithV);
                    return Gs;
                }
                //--------------------------------------------------------------------------------------------

                //VERTEX FX
                v2f vert(appdata v)
                {
                    v2f o;
                    o.uv = v.uv;
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.normal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                    o.tangent = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                    o.binormal = normalize(cross(o.normal, o.tangent) * v.tangent.w);

                    return o;
                }

                //FRAGMENT FX
                float4 frag(v2f i) : SV_TARGET
                {
                    //GET BASIC DIRECTIONS-------------------------------------------------------------------------------
                    float3 normalDirection = normalize(i.normal);
                    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                    float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos.xyz,_WorldSpaceLightPos0.w));


                    //READ MAPS------------------------------------------------------------------------------------------
                    //1. albedo
                    float3 albedo = tex2D(_AlbedoMap, TRANSFORM_TEX(i.uv, _AlbedoMap)).rgb;
                    i.col.rgb = albedo * _AlbedoColor.rgb * _Exposure;
                    i.col.a = _AlbedoColor.a;
                    //2. metalness
                    float metalness = saturate(max(_Metalness, tex2D(_MetalnessMap, TRANSFORM_TEX(i.uv, _MetalnessMap))).r);
                    metalness = lerp(_Metalness, metalness, 1 - _Sharpness);
                    //3. roughness
                    float roughness = saturate(max(_Roughness, tex2D(_RoughnessMap, TRANSFORM_TEX(i.uv, _RoughnessMap))).r);
                    roughness = lerp(_Roughness, roughness, 1 - _Sharpness);
                    //4. ambient occlusion
                    float occlusion = saturate(tex2D(_OcclusionMap, TRANSFORM_TEX(i.uv, _OcclusionMap)).r);
                    occlusion = lerp(1, occlusion, _Occlusion);
                    //5. normal
                    float3 normalMap = UnpackNormal(tex2D(_NormalMap, TRANSFORM_TEX(i.uv, _NormalMap)));
                    float3x3 TBN = float3x3(i.tangent, i.binormal, i.normal);
                    TBN = transpose(TBN);
                    float3 worldNormal = normalize(mul(TBN, normalMap));
                    normalDirection = lerp(normalDirection, worldNormal, _NormalStrength * (1 - _Sharpness));


                    //VECTOR CALCULATIONS-------------------------------------------------------------------------------
                    float3 viewReflectDirection = normalize(reflect(-viewDirection, normalDirection));
                    float NdotL = max(0.0, dot(normalDirection, lightDirection));
                    float3 halfDirection = normalize(viewDirection + lightDirection);
                    float NdotH = max(0.0, dot(normalDirection, halfDirection));
                    float NdotV = max(0.0, dot(normalDirection, viewDirection));
                    float LdotH = max(0.0, dot(lightDirection, halfDirection));

                    //PBR----------------------------------------------------------------------------------------------
                    //1. Diffuse Direct Light
                    float3 diffuseColor = i.col.rgb * ((1.0 - metalness) + _DMetalProperty / 5) * occlusion;
                    diffuseColor = FresnelLerp(diffuseColor, 0.05, NdotV);
                    float f0 = F0(NdotL, NdotV, LdotH, roughness);
                    diffuseColor *= f0;

                    //2. Diffuse Indirect Light
                    float3 diffuseIrradiance = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalDirection, UNITY_SPECCUBE_LOD_STEPS).rgb * occlusion;
                    float3 indirectDiffuse = diffuseColor * diffuseIrradiance;

                    //3. Specular Direct Light
                    float3 specColor = lerp(_LightColor0.rgb, i.col.rgb, metalness);
                    float3 SpecularDistribution = saturate(_LightColor0.rgb * GGXNormalDistribution(roughness, NdotH));
                    float GeometricShadow = GGXGeometricShadowingFunction(NdotL, NdotV, roughness);
                    float3 FresnelFunction = _LightColor0.rgb * SchlickFresnelFunction(specColor, LdotH);;
                    float3 specularity = SpecularDistribution * FresnelFunction * GeometricShadow / 4 * (NdotL * NdotV);

                    //4. Specular Indirect Light
                    float3 SpecularIrradiance = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, viewReflectDirection, roughness * UNITY_SPECCUBE_LOD_STEPS).rgb * occlusion;
                    float grazingTerm = saturate(roughness + metalness);
                    float3 indirectSpecular = SpecularIrradiance * FresnelLerp(specColor, grazingTerm, NdotV) * max(0.5, metalness) * (1 - roughness * roughness * roughness);

                    //5. Combining everything
                    float3 lightingModel = diffuseColor + indirectDiffuse + specularity + indirectSpecular;
                    lightingModel *= lerp(1,NdotL, _ShadowStrength);

                    float fresnel = pow(saturate(1 - dot(i.normal, viewDirection)), _FresnelPower);
                    fresnel *= _FresnelColor;
                    lightingModel += fresnel;
                    float4 returnFinal = float4(saturate(lightingModel), i.col.a);


                    //VISUALIZE-------------------------------------------------------------------------------
                    //returnFinal.rgb = SpecularIrradiance;
                    return returnFinal;
                }
                ENDCG
            }

        }
            FallBack "Legacy Shaders/VertexLit"
}


