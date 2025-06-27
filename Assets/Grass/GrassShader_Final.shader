Shader "Unlit/GrassShader_Final"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SmoothOne ("Smoothness 1", Range(0,1)) = 0.03
        _SmoothTwo ("Smoothness 2", Range(0,1)) = 0.035
        _First ("First", Vector) = (0.075, 0.9, 0, 0)
        _Third ("Third", Vector) = (0.035, 0.1, 0, 0)
        _BottomColor("Bottom Color", Color) = (0, 0, 0, 1)
        _TopColor("Top Color", Color) = (0, 0, 0, 1)
        _BendFactor("Bend Factor", Float) = 0
        _BendScale("Bend Scale", Float) = 0
        _BendScaleX("Bend Scale X", Float) = 0
        _Angle("Angle", Float) = 0
        _BlendAngleScale("Blend Angle Scale", Float) = 0
        _NoiseScale ("Noise Scale", Float) = 1.0
        _NoiseSpeed ("Noise Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"
        "Queue"="Transparent" }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing // Enables GPU instancing

            // Signal this shader requires compute buffers
             #pragma prefer_hlslcc gles
             #pragma exclude_renderers d3d11_9x
            // #pragma target 5.0

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            StructuredBuffer<float4x4> transform;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

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

            float3 RotateAroundY(float3 position, float angle)
            {
                float c = cos(angle);
                float s = sin(angle);
    
                return float3(
                    position.x * c + position.z * s,
                    position.y,
                    -position.x * s + position.z * c
                );
            }

            float smin( float a, float b, float k )
            {
                k *= 1.0;
                float r = exp2(-a/k) + exp2(-b/k);
                return -k*log2(r);
            }

            sampler2D _MainTex;
            float4 _MainTex_ST, _First, _Second, _Third, _BottomColor, _TopColor;
            float _SmoothOne, _SmoothTwo, _BendFactor, _BendScale, _BendScaleX, _Angle, _BlendAngleScale, _NoiseScale, _NoiseSpeed;

            v2f vert (appdata v, const uint id : SV_InstanceID)
            {
                float4x4 m = transform[id];

                // For Noise Input use the position stored in Structured Buffer and access using InstanceID as Input
                float3 noiseInput = float3
                (
                    1 * _NoiseScale,
					v.vertex.z * _NoiseScale,
					_Time.y * _NoiseSpeed
                );
                float3 noiseInput2 = float3
                (
				   v.vertex.z * _NoiseScale,
                   1 * _NoiseScale,
				   _Time.y * _NoiseSpeed
                );

                float noiseValue = snoise(noiseInput);
                float noiseValue2 = snoise(noiseInput2);

                float uvY = v.uv.y;
                uvY = pow(uvY, _BendFactor);
                // Without Noise
                //v.vertex.z = v.vertex.z + uvY * _BendScale;
				//v.vertex.x = v.vertex.x + uvY * _BendScaleX;

                // With Noise
                v.vertex.z = v.vertex.z + uvY * noiseValue * _BendScale;
				v.vertex.x = v.vertex.x + uvY * noiseValue2 * _BendScaleX;

                // Without Noise
                //v.vertex.xyz = RotateAroundY(v.vertex.xyz, _Angle * 3.14159/180 * uvY * _BlendAngleScale);

                // With Noise
                v.vertex.xyz = RotateAroundY(v.vertex.xyz, _Angle * 3.14159/180 * uvY * (noiseValue * 2 - 1));

                float4 worldPos = mul(m, v.vertex);

                v2f o;
                o.vertex = UnityObjectToClipPos(worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv * 2 - 1;
                //uv = uv * 6;
                float elpise = sdEllipse(uv, float2(_First.x, _First.y));
                //elpise = pow(elpise, 0.8);
                float2 uv2 = i.uv * 2 - 1;
                uv2.y = uv2.y + 0.55;
                float elpise2 = sdEllipse(uv2, float2(0.03, 0.25));
                float first = smin(elpise, elpise2, _SmoothOne);
                //return first;
                float2 uv3 = i.uv * 2 - 1;
				uv3.y = uv3.y + 0.75;
                float elpise3 = sdEllipse(uv3, float2(_Third.x, _Third.y));
                float final = smin(first, elpise3, _SmoothTwo);
                float mask = final;
                mask = 1 - step(0.01, mask);
                final = abs(final) + 0.1;
                final = pow(final, 0.6);

                float2 uvCol = i.uv;
                uvCol.y = pow(uvCol.y, 2);
                float4 col = lerp(_BottomColor, _TopColor, uvCol.y);
                return float4( final * col.rgb, mask);
            }
            ENDCG
        }
    }
}
