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

            #pragma multi_compile_instancing // Enables GPU instancing

            // Signal this shader requires compute buffers
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 5.0

            //#include "UnityCG.cginc"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            StructuredBuffer<float4> position; // Buffer that stores the current postion which comes from the compute
            StructuredBuffer<float4> originalPosition; // Buffer that stores the original position of the mesh

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
                float dist : TEXCOORD3; // distance between the original and the world position

            };

            float4 _NearColor;
			float4 _FarColor;

            // SV_InstanceID is used to get the index of the instance in the buffer. Mostly useful in GPU instancing
            // SV_VertexID is used to get the index of the vertex in the mesh
            // Here we use SV_InstanceID as we want to get data for relevant instances from the postion and the original position buffer
            v2f vert (appdata v, const uint id : SV_InstanceID) // What Difference between instance_id and vertexID || CLAUDE ||
            {
                float4 startPos = position[id]; // Get the postion from the Buffer
                // As the postion in the buffer is the center of the instance, in order to postion the vertex correctly we need to offset it
                // that is why we add them together
                float3 world_pos  = startPos.xyz + v.vertex.xyz; 
                float3 originalWorldPos = originalPosition[id].xyz + v.vertex.xyz;
                originalWorldPos = TransformWorldToHClip(float4(originalWorldPos, 1.0)); // Transfrom the world position to the clip space

                v2f o;
                o.vertex = TransformWorldToHClip(float4(world_pos, 1.0));
                o.diffuse = saturate(dot(v.normal, _MainLightPosition.xyz)); // Simple diffuse lighting
                // Distance between the original and the current postion of the vertex when both are in clip space
				o.dist = length(o.vertex.xyz - originalWorldPos.xyz); 

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = float4(1.0f, 1.0f, 1.0f, 1.0f);
                col.rgb *= i.diffuse; // To have some shadows

                float4 colorOfChange = lerp(_NearColor, _FarColor, i.dist); // Change the color based on the distance from the original position
                return col + colorOfChange / 2.0f ; // Some calulations so that the mesh does not look too bright
            }
            ENDHLSL
        }
    }
}
