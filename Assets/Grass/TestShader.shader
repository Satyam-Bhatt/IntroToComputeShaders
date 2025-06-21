Shader "Unlit/TestShader"
{
    Properties
    {

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing // Enables GPU instancing

            // Signal this shader requires compute buffers
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 5.0

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            StructuredBuffer<float4x4> transform;

            struct appdata
            {
                float3 normal : NORMAL;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 diffuse : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v, const uint id : SV_InstanceID)
            {
                //float4x4 m = transform[id];
                //float4 startPos = float4(m._m03, m._m13, m._m23, m._m33);
                //float3 world_Pos = startPos.xyz + v.vertex.xyz;

                // This applies the translation, rotation and scaling to the vertex
                //float4 world_Pos = mul(m, v.vertex);

                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.vertex = UnityObjectToClipPos(world_Pos);
                o.uv = v.uv;
                if(saturate(dot(v.normal, _WorldSpaceLightPos0.xyz)) > 0.0f)
                {
                    o.diffuse = saturate(dot(v.normal, _WorldSpaceLightPos0.xyz));
                }
                else
                {
                    o.diffuse = saturate(dot(v.normal, -_WorldSpaceLightPos0.xyz));
                }
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv * 2 - 1;
                float len = length(uv);
                return len;
                return float4(uv, 0 ,1);
                //float4 col = float4(0.0f, 0.4f, 0.0f, 1.0f);
                //col.rgb *= i.diffuse;
                //return col;
            }
            ENDCG
        }
    }
}
