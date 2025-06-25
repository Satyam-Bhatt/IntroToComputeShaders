Shader "Unlit/ShaderForGrass"
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

                        float sdEllipse( float2 p, float2 ab )
            {
                p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
                float l = ab.y*ab.y - ab.x*ab.x;
                float m = ab.x*p.x/l;      float m2 = m*m; 
                float n = ab.y*p.y/l;      float n2 = n*n; 
                float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
                float q = c3 + m2*n2*2.0;
                float d = c3 + m2*n2;
                float g = m + m*n2;
                float co;
                if( d<0.0 )
                {
                    float h = acos(q/c3)/3.0;
                    float s = cos(h);
                    float t = sin(h)*sqrt(3.0);
                    float rx = sqrt( -c*(s + t + 2.0) + m2 );
                    float ry = sqrt( -c*(s - t + 2.0) + m2 );
                    co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
                }
                else
                {
                    float h = 2.0*m*n*sqrt( d );
                    float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
                    float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
                    float rx = -s - u - c*4.0 + 2.0*m2;
                    float ry = (s - u)*sqrt(3.0);
                    float rm = sqrt( rx*rx + ry*ry );
                    co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
                }
                float2 r = ab * float2(co, sqrt(1.0-co*co));
                return length(r-p) * sign(p.y-r.y);
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v, const uint id : SV_InstanceID)
            {
                float4x4 m = transform[id];
                //float4 startPos = float4(m._m03, m._m13, m._m23, m._m33);
                //float3 world_Pos = startPos.xyz + v.vertex.xyz;

                // This applies the translation, rotation and scaling to the vertex
                float4 world_Pos = mul(m, v.vertex);

                v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                o.vertex = UnityObjectToClipPos(world_Pos);
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
                float2 uv = i.uv;
                //return float4(uv, 0 ,1);
                float4 col = float4(0.0f, 0.4f, 0.0f, 1.0f);
                col.rgb *= i.diffuse;
                return col;
            }
            ENDCG
        }
    }
}
