Shader"AA1/Hologram"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _Power ("Power", float) = 1.0
        _LinesSpeed ("Lines Speed", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        BlendOp Add
        ZWrite Off

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
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                half3 viewDirection : TEXCOORD1;
                float4 screenPosition : TEXCOORD2;
};

            fixed4 _Color, _FresnelColor;
            float _Power, _LinesSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
    
                o.normal = UnityObjectToWorldNormal(v.normal);

                o.viewDirection = normalize(WorldSpaceViewDir(v.vertex));
    
                o.uv = v.uv;
    
                o.screenPosition = ComputeScreenPos(mul(unity_ObjectToWorld, v.vertex));
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {        
    
                float2 screenPosition = i.screenPosition.xy;
    
                float fresnel = saturate(dot(i.normal, i.viewDirection));
                fresnel = saturate(1 - fresnel);
                fresnel = pow(fresnel, sin(_Time.y) + 1.5);
                fixed4 fresnelColor = fresnel * _FresnelColor;
                fixed4 color = fresnelColor;
                
                if (sin(i.screenPosition.y * _Time.w) > 0.5)
                {
                    color *= _Color;
                }
    
                float t = sin(i.screenPosition.y * _LinesSpeed);
                color.rgb = t.xxx;
    
                return color;
            }
            ENDCG
        }
    }
}
