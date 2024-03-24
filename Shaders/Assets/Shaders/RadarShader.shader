Shader "AA1/Radar"
{
    Properties
    {
        _MainTexture("Main Texure", 2D) = "white" {}
        _HeatMap("Heat Map", 2D) = "white" {}
        
        _MaxHeight("Max Height", float) = 1.0
                
        _CenterRadar("Center Radar", Vector) = (0, 0, 0, 0)
        _MinRadiusRadar("Min Radius Radar", float) = 1.0
        _MaxRadiusRadar("Max Radius Radar", Range(1, 10)) = 10
        _RadiusRadarColor("Radius Radar Color", Color) = (1, 0, 0, 1)
        _RadiusRadarWidth("Radius Radar Width", Range(1, 5)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPosition : TEXCOORD1;
            };

            fixed4 _RadiusRadarColor;
            float4 _MainTexture_ST, _HeatMap_ST, _CenterRadar;
            sampler2D _MainTexture, _HeatMap;
            float _MaxHeight, _MinRadiusRadar, _MaxRadiusRadar, _RadiusRadarWidth;

            v2f vert (appdata v)
            {
                v2f o;
                float2 localTextureHeight = tex2Dlod(_MainTexture, float4(v.uv, 0, 0));
                float height = localTextureHeight.y * _MaxHeight;
                o.uv = float2(v.uv.x, localTextureHeight.y);

                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);

                o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.vertex.y += height;
                o.vertex = mul(UNITY_MATRIX_VP, o.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 color = fixed4(tex2D(_HeatMap, i.uv).rgb, 1.0);;
                float dist = distance(_CenterRadar, i.worldPosition);
                float interpolationTime = _Time.y % 1;
                float radarScale = _MaxRadiusRadar * _RadiusRadarWidth;
                float radiusRadar = lerp(_MinRadiusRadar, radarScale, sqrt(interpolationTime));
                if (dist > radiusRadar && dist < radiusRadar + _RadiusRadarWidth)
                {
                    color = lerp(_RadiusRadarColor, color, radiusRadar / radarScale);
                }
                if (dist < _RadiusRadarWidth)
                {
                    color = _RadiusRadarColor;
                }
                return color;
            }
            ENDCG
        }
    }
}
