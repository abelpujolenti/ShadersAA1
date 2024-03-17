Shader "Custom/MossTriplanarShader"
{
    Properties
    {
        _GroundTex ("Ground Texture", 2D) = "white" {}
        _GrassTex ("Grass Texture", 2D) = "white" {}
        [NoScaleOffset] _HeightMap ("Heights", 2D) = "gray" {}
        _Scale ("Scale", float) = 1
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        sampler2D _GroundTex;
        sampler2D _GrassTex;
        sampler2D _HeightMap;
        half _Smoothness;
		half _Metallic;

        float _Scale;

        struct Input
        {
            float2 uv_GroundTex;
            float3 worldPos;
            float3 worldNormal;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 worldPos = IN.worldPos / _Scale;
            float3 proj = abs(IN.worldNormal);
            normalize(proj);
            float3 texX = tex2D(_GroundTex, worldPos.yz) * proj.x;
            float3 texY = tex2D(_GrassTex, worldPos.xz) * proj.y;
            float3 texZ = tex2D(_GroundTex, worldPos.xy) * proj.z;

            o.Albedo = texX + texY + texZ;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
