Shader "AA1/Water"
{
    Properties
    {        
        _MainTexture ("Main Texture", 2D) = "white" {}
        _NoiseTexture ("Noise Texture", 2D) = "white" {}
        
        _Flow1 ("Flow vector 1", Vector) = (1, 0, 0, 0)
        _Flow2 ("Flow vector 2", Vector) = (1, 0, 0, 0)

        _FlowAmount ("Flow Amount", Float) = 1.0
        _FlowSpeed("Flow Speed", Float) = 1.0
        _MoveSpeed ("Move Speed", Float) = 0.01
        _PulsePower("Pulse Power", Float) = 1.0
        _MaxHeight("Max Height", float) = 1.0
        _NoiseScale("Noise Scale", Range(1, 2.5)) = 1.0
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
                float2 noise_uv : TEXCOORD1;
            };

            float4 _MainTexture_ST, _NoiseTexture_ST, _Flow1, _Flow2;
            sampler2D _MainTexture, _NoiseTexture;
            float _FlowAmount, _FlowSpeed, _MoveSpeed, _PulsePower, _MaxHeight, _NoiseScale;

            //NOISE FUNCTIONS-------------------------------------------------------------------------
            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }
            //NOISE FUNCTIONS-------------------------------------------------------------------------


            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTexture); //Load Main Texture UV

                o.uv += _Flow1 * _Time.x; //Move Main Texture UV based on Flow and Time
                o.noise_uv = TRANSFORM_TEX(v.uv, _NoiseTexture); //Load Noise Texture UV
                o.noise_uv += _Flow2.xy * _Time.x; //Move Noise Texture UV based on Flow and Time

                float2 flowVector = tex2Dlod(_NoiseTexture, float4(o.uv.xy, 0, 0)).rg;
                o.uv += o.uv - flowVector * sin(_Time.y * _FlowSpeed) * _FlowAmount * _Time * (_MoveSpeed / 100);

                float gradientNoise = unity_gradientNoise(o.uv.xy * _NoiseScale);
                float height = gradientNoise * _MaxHeight;
                o.uv = float2(v.uv.x, gradientNoise);
                
                o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)); //Idk
                o.vertex.y += height; //Change vertex height
                o.vertex = mul(UNITY_MATRIX_VP, o.vertex); //Idk
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 noise = tex2D(_NoiseTexture, i.noise_uv); //Draw Noise UV Pixel
                fixed2 disturb = noise.xy * 0.5 - 0.5; //Create a Disturb using normals
                fixed4 color = tex2D(_MainTexture, i.uv + disturb); //Draw Main UV Pixel with given distubation by Noise Texture Normals
                fixed noisePulse = tex2D(_NoiseTexture, i.noise_uv + disturb).a; //Idk
                fixed4 temper = color * noisePulse * _PulsePower + (color * color - 0.1); //Change Brightness taking care : Main Texture Pixel Color, idk, Pulse Power and idk
                color = temper;
                color.a = 1.0; // Prevent transparency
                return color;
            }
            ENDCG
        }
    }
}
