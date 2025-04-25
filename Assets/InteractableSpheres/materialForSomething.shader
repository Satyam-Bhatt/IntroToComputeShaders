Shader "Unlit/materialForSomething"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing // What is this??

            // Signal this shader requires compute buffers
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 5.0

            //#include "UnityCG.cginc"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            StructuredBuffer<float4> position;

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

            v2f vert (appdata v, const uint id : SV_InstanceID) // What Difference between instance_id and vertexID
            {
                float4 startPos = position[id];
                float3 world_pos  = startPos.xyz + v.vertex.xyz;

                v2f o;
                o.vertex = TransformWorldToHClip(float4(world_pos, 1.0));
                o.diffuse = saturate(dot(v.normal, _MainLightPosition.xyz));

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                col.rgb *= i.diffuse;
                return col;
            }
            ENDHLSL
        }
    }
}
