Shader "Unlit/TrueElipseSDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SmoothOne ("Smoothness 1", Range(0,1)) = 0.03
        _SmoothTwo ("Smoothness 2", Range(0,1)) = 0.035
        _First ("First", Vector) = (0.075, 0.9, 0, 0)
        _Third ("Third", Vector) = (0.035, 0.1, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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

            float smin( float a, float b, float k )
            {
                k *= 1.0;
                float r = exp2(-a/k) + exp2(-b/k);
                return -k*log2(r);
            }

            sampler2D _MainTex;
            float4 _MainTex_ST, _First, _Second, _Third;
            float _SmoothOne, _SmoothTwo;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
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
                return pow(final, 0.7);
            }
            ENDCG
        }
    }
}
