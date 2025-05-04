Shader "Unlit/CubeMaterial"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseSpeed ("Noise Speed", Float) = 1.0
        _NoiseHeight ("Noise Height", Float) = 0.5
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
            StructuredBuffer<float4> positionUpdate;

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
            float _NoiseScale;
            float _NoiseSpeed;
            float _NoiseHeight;

            float3 mod289(float3 x)
            {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }
            
            float4 mod289(float4 x)
            {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }
            
            float4 permute(float4 x)
            {
                return mod289(((x * 34.0) + 1.0) * x);
            }
            
            float4 taylorInvSqrt(float4 r)
            {
                return 1.79284291400159 - 0.85373472095314 * r;
            }

            float snoise(float3 v)
            {
                const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
                const float4 D = float4(0.0, 0.5, 1.0, 2.0);
                
                // First corner
                float3 i = floor(v + dot(v, C.yyy));
                float3 x0 = v - i + dot(i, C.xxx);
                
                // Other corners
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);
                
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - D.yyy;
                
                // Permutations
                i = mod289(i);
                float4 p = permute(permute(permute(
                        i.z + float4(0.0, i1.z, i2.z, 1.0))
                        + i.y + float4(0.0, i1.y, i2.y, 1.0))
                        + i.x + float4(0.0, i1.x, i2.x, 1.0));
                
                // Gradients
                float n_ = 0.142857142857;
                float3 ns = n_ * D.wyz - D.xzx;
                
                float4 j = p - 49.0 * floor(p * ns.z * ns.z);
                
                float4 x_ = floor(j * ns.z);
                float4 y_ = floor(j - 7.0 * x_);
                
                float4 x = x_ * ns.x + ns.yyyy;
                float4 y = y_ * ns.x + ns.yyyy;
                float4 h = 1.0 - abs(x) - abs(y);
                
                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);
                
                float4 s0 = floor(b0) * 2.0 + 1.0;
                float4 s1 = floor(b1) * 2.0 + 1.0;
                float4 sh = -step(h, float4(0.0, 0.0, 0.0, 0.0));
                
                float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
                
                float3 p0 = float3(a0.xy, h.x);
                float3 p1 = float3(a0.zw, h.y);
                float3 p2 = float3(a1.xy, h.z);
                float3 p3 = float3(a1.zw, h.w);
                
                // Normalise gradients
                float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
                p0 *= norm.x;
                p1 *= norm.y;
                p2 *= norm.z;
                p3 *= norm.w;
                
                // Mix final noise value
                float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
                m = m * m;
                return 42.0 * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
            }

            varyings vert (attributes v, const uint instance_id : SV_InstanceID) // What Difference between instance_id and vertexID
            {
                float4 startPos = position[instance_id];
                //float4 objectPosition = positionUpdate[0];

                // Calculate noise based on position and time
                float3 noiseInput = float3(
                    startPos.x * _NoiseScale, // Sampling noise on the basis of x position to offset y position
                    startPos.z * _NoiseScale, // Sampling noise on the basis of z position to offset y position
                    _Time.y * _NoiseSpeed // This helps in varying the noise
                );

                // Generate noise value between -1 and 1
                float noiseValue = snoise(noiseInput);

                float3 world_pos  = startPos.xyz + v.vertex.xyz;
                world_pos.y += noiseValue * _NoiseHeight;

                // float distance = length(world_pos - objectPosition.xyz);
                // float affect = 0;

                // if(distance > 1)
                // {
                //     affect = 1/(distance);
                // }
                // else
                // {
                //     affect = 0;
                // }

                //float3 newPos = world_pos + normalize(objectPosition.xyz - world_pos) * affect;

                varyings o;
                o.vertex = TransformWorldToHClip(float4(world_pos, 1.0));
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
