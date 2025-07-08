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
        // Tags { "RenderType"="Transparent"
        // "Queue"="Transparent" }

        Tags { "RenderType"="Opaque" }

        Pass
        {
            //ZWrite Off
            //Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing // Enables GPU instancing

            // Signal this shader requires compute buffers
             #pragma prefer_hlslcc gles
             #pragma exclude_renderers d3d11_9x
             //#pragma target 5.0

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

            uint hash(uint2 x, uint seed){
                const uint m = 0x5bd1e995U;
                uint hash = seed;
                // process first vector element
                uint k = x.x; 
                k *= m;
                k ^= k >> 24;
                k *= m;
                hash *= m;
                hash ^= k;
                // process second vector element
                k = x.y; 
                k *= m;
                k ^= k >> 24;
                k *= m;
                hash *= m;
                hash ^= k;
	            // some final mixing
                hash ^= hash >> 13;
                hash *= m;
                hash ^= hash >> 15;
                return hash;
            }

            float2 gradientDirection(uint hash) {
                switch (int(hash) & 3) { // look at the last two bits to pick a gradient direction
                case 0:
                    return float2(1.0, 1.0);
                case 1:
                    return float2(-1.0, 1.0);
                case 2:
                    return float2(1.0, -1.0);
                case 3:
                    return float2(-1.0, -1.0);
                }
            }

            float interpolate(float value1, float value2, float value3, float value4, float2 t) {
                return lerp(lerp(value1, value2, t.x), lerp(value3, value4, t.x), t.y);
            }

            float2 fade(float2 t) {
                // 6t^5 - 15t^4 + 10t^3
	            return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
            }

            float perlinNoise(float2 position, uint seed) {
                float2 floorPosition = floor(position);
                float2 fractPosition = position - floorPosition;
                uint2 cellCoordinates = uint2(floorPosition);
                float value1 = dot(gradientDirection(hash(cellCoordinates, seed)), fractPosition);
                float value2 = dot(gradientDirection(hash((cellCoordinates + uint2(1, 0)), seed)), fractPosition - float2(1.0, 0.0));
                float value3 = dot(gradientDirection(hash((cellCoordinates + uint2(0, 1)), seed)), fractPosition - float2(0.0, 1.0));
                float value4 = dot(gradientDirection(hash((cellCoordinates + uint2(1, 1)), seed)), fractPosition - float2(1.0, 1.0));
                return interpolate(value1, value2, value3, value4, fade(fractPosition));
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
                float3 _position = float3(m._m03, m._m13, m._m23);

                uint seed = 0x578437adU;
                float noiseValue = perlinNoise(float2(_position.x, _position.z) * _NoiseScale + _Time.y, seed);
                noiseValue = (noiseValue + 1.0) * 0.5;
                uint seed2 = 0x578463adU;
                float noiseValue2 = perlinNoise(float2(_position.x, _position.z) * _NoiseScale + _Time.y, seed2);
                noiseValue2 = (noiseValue2 + 1.0) * 0.5;

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
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i, const uint id : SV_InstanceID) : SV_Target
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
                float4 grassBlade = float4( final * col.rgb, 1);
                if(mask == 0) discard;
                return grassBlade;
            }
            ENDCG
        }
    }
}
