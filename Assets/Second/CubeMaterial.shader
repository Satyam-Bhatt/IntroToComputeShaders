Shader "Unlit/CubeMaterial"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" 
        "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_instancing // What is this??

            // Signal this shader requires compute buffers
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 5.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            StructuredBuffer<float4> position;

            struct attributes
            {
                float3 normal : NORMAL;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct varyings
            {
                float4 vertex : SV_POSITION;
                float3 diffuse : TEXCOORD2;
                float3 color : TEXCOORD3;
                float2 uv : TEXCOORD4; // UVs
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            varyings vert (attributes v, const uint instance_id : SV_InstanceID) // What Difference between instance_id and vertexID
            {
                float4 startPos = position[instance_id];
                float3 world_pos  = startPos.xyz + v.vertex.xyz;
                world_pos = world_pos + sin(_Time.y * 2 +  world_pos.z) * 0.2;

                varyings o;
                o.vertex = TransformWorldToHClip(float4(world_pos, 1.0));;
                o.diffuse = saturate(dot(v.normal, _MainLightPosition.xyz));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.color = color;
                return o;
            }

            float4 frag (const varyings i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                const float3 lighting = i.diffuse *  1.7;
				col.rgb *= i.diffuse;
                return col;
            }
            ENDHLSL
        }
    }
}
