Shader "AA1/Hologram"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Power ("Power", float) = 1.0
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
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                half3 normal : NORMAL;
                half3 viewDirection : TEXCOORD0;
            };

            fixed4 _Color;
            float _Power;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);

                o.viewDirection = normalize(WorldSpaceViewDir(v.vertex));
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float fresnel = saturate(dot(i.normal, i.viewDirection));
                fresnel = saturate(1 - fresnel);
                fresnel = pow(fresnel, sin(_Time.y) + 1.5);
                fixed4 fresnelColor = fresnel * _Color;
                fixed4 color = fresnelColor;
                return color;
            }
            ENDCG
        }
    }
}
