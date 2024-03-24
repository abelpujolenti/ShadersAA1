Shader "AA1/Celshade"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Step("Step", Range(20, 50)) = 30.0
		[HDR]
		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
		[HDR]
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716
		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineWidth("Outline Width", float) = 1.0
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" "PassFlags" = "OnlyDirectional" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;	
				float3 normal : NORMAL;
            };
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : NORMAL;
				float3 viewDir : TEXCOORD1;
			};

            v2f vert (appdata v)
            {
                v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);		
				o.viewDir = WorldSpaceViewDir(v.vertex);
				return o;
            }

			float4 _Color;
            float _Step;
			float4 _AmbientColor;
			float4 _RimColor;
			float _RimAmount;
			float _RimThreshold;	

			float4 frag (v2f i) : SV_Target
			{
				float3 normal = normalize(i.worldNormal);
				float3 viewDir = normalize(i.viewDir);
                
				float NdotL = dot(_WorldSpaceLightPos0, normal);

				float lightIntensity = smoothstep(0, 1, NdotL);
                float step = ((lightIntensity * 100.0) % _Step) / 100.0;
                lightIntensity -= step;
				float4 light = lightIntensity * _LightColor0;		

				float rimDot = 1 - dot(viewDir, normal);
				float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
				float4 rim = rimIntensity * _RimColor;

                return (light * _AmbientColor + rim) * _Color;
			}
            ENDCG
        }

		Pass
		{
			Cull Front                

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			fixed4 _OutlineColor;
			float _OutlineWidth;

			v2f vert(appdata v)
			{
				v2f o;
				v.vertex.xyz += _OutlineWidth * 0.01 * v.normal;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return _OutlineColor;
			}
			ENDCG
		}
    }
}
