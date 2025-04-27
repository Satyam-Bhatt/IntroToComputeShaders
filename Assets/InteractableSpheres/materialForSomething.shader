Shader "Unlit/materialForSomething"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NearColor ("Near Color", Color) = (1,1,1,1)
		_FarColor ("Far Color", Color) = (1,1,1,1)
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
            StructuredBuffer<float4> originalPosition;

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
                float dist : TEXCOORD3;

            };

            float4 _NearColor;
			float4 _FarColor;

            v2f vert (appdata v, const uint id : SV_InstanceID) // What Difference between instance_id and vertexID
            {
                float4 startPos = position[id];
                float3 world_pos  = startPos.xyz + v.vertex.xyz;
                float3 originalWorldPos = originalPosition[id].xyz + v.vertex.xyz;
                originalWorldPos = TransformWorldToHClip(float4(originalWorldPos, 1.0));

                v2f o;
                o.vertex = TransformWorldToHClip(float4(world_pos, 1.0));
                o.diffuse = saturate(dot(v.normal, _MainLightPosition.xyz));
				o.dist = length(o.vertex.xyz - originalWorldPos.xyz);

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = float4(1.0f, 1.0f, 1.0f, 1.0f);
                col.rgb *= i.diffuse;

                float4 colorOfChange = lerp(_NearColor, _FarColor, i.dist);
                return col + colorOfChange / 2.0f ;
            }
            ENDHLSL
        }
    }
}
