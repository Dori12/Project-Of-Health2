Shader "RR/Water" {
    Properties {
        _FogColor ("Fog Color", Color) = (0.282353,0.6196079,0.5764706,1)
        _FogHeight ("Fog Height", Float ) = 1


		_specularColor("specularColor", Color) = (0.0,0.0,0.3,1)
		_Gloss("Gloss", Float) = 1
		_Specular("Specular", Range(0, 1)) = 0
		_values_specular("Values Specular", Range(0, 2)) = 0.3

        _ReflectionTex ("ReflectionTex", 2D) = "white" {}
        _Water01 ("Water01", 2D) = "bump" {}
        _Wave01 ("Wave01", 2D) = "bump" {}
        _Water02 ("Water02", 2D) = "bump" {}
        _Wave02 ("Wave02", 2D) = "bump" {}
        _RefractionAmount ("Refraction Amount", Range(0, 0.1)) = 0.05
        _ShoreBlend ("Shore Blend", Float ) = 6
        _DepthRefractionBlend ("Depth Refraction Blend ", Float ) = 1
        _Fresnel ("Fresnel", Float ) = 1
        [MaterialToggle] _UseFoam ("Use Foam", Float ) = 0
        _Foam ("Foam", 2D) = "white" {}
        _ShoreFoamDepth ("Shore Foam Depth", Float ) = 2
        [MaterialToggle] _RealTimeReflect ("RealTimeReflect", Float ) = 0
        _CubeMap ("CubeMap", Cube) = "_Skybox" {}
        _HeightMap ("HeightMap", 2D) = "white" {}
        _Vert_offset ("Vert_offset", Float ) = 0.2
        _PDDistanceChek ("PD Distance Chek", Range(0, 0.1)) = 0
        _Normalstr ("Normal str", Float ) = 1
        _Count_teselation ("Count_teselation", Float ) = 30
        _Distance ("Distance", Float ) = 3
        _Speed ("Speed", Float ) = 1
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        LOD 200
        GrabPass{ "Refraction" }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            ZWrite Off
            
            CGPROGRAM
            #pragma hull hull
            #pragma domain domain
            #pragma vertex tessvert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "Tessellation.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 
            #pragma target 5.0
            uniform sampler2D Refraction;
            uniform sampler2D _CameraDepthTexture;
            uniform float4 _TimeEditor;
            uniform sampler2D _Wave01; uniform float4 _Wave01_ST;
            uniform fixed _RefractionAmount;
            uniform fixed _ShoreBlend;
            uniform float4 _FogColor;
            uniform sampler2D _ReflectionTex; uniform float4 _ReflectionTex_ST;
            uniform fixed _DepthRefractionBlend;
            uniform float _Fresnel;
            uniform sampler2D _Wave02; uniform float4 _Wave02_ST;
            uniform sampler2D _Water01; uniform float4 _Water01_ST;
            uniform sampler2D _Water02; uniform float4 _Water02_ST;
            uniform float _FogHeight;
            uniform sampler2D _Foam; uniform float4 _Foam_ST;
            uniform float _ShoreFoamDepth;
            uniform fixed _UseFoam;
            uniform fixed _RealTimeReflect;
            uniform samplerCUBE _CubeMap;
            uniform fixed _PDDistanceChek;
            uniform sampler2D _HeightMap; uniform float4 _HeightMap_ST;
            uniform fixed _Normalstr;
            uniform fixed _Vert_offset;
            uniform fixed _Count_teselation;
            uniform fixed _Distance;
            uniform fixed _Speed;
           	uniform fixed _Specular;
			uniform fixed _values_specular;
			uniform fixed _Gloss;
			uniform fixed4 _specularColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
                float4 projPos : TEXCOORD6;
                UNITY_FOG_COORDS(7)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                float3 recipObjScale = float3( length(unity_WorldToObject[0].xyz), length(unity_WorldToObject[1].xyz), length(unity_WorldToObject[2].xyz) );
                float3 objScale = 1.0/recipObjScale;
                float4 node_2642 = _Time + _TimeEditor;
                float2 Tesselation_hod = (((o.uv0/_Speed)+node_2642.g*float2(0.5,0.5))*_Speed);
                fixed4 Height = tex2Dlod(_HeightMap,float4(TRANSFORM_TEX(Tesselation_hod, _HeightMap),0.0,0));
                v.vertex.xyz += ((Height.r*v.normal)*_Vert_offset);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                o.screenPos = o.pos;
                return o;
            }
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                struct TessVertex {
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 texcoord0 : TEXCOORD0;
                };
                struct OutputPatchConstant {
                    float edge[3]         : SV_TessFactor;
                    float inside          : SV_InsideTessFactor;
                    float3 vTangent[4]    : TANGENT;
                    float2 vUV[4]         : TEXCOORD;
                    float3 vTanUCorner[4] : TANUCORNER;
                    float3 vTanVCorner[4] : TANVCORNER;
                    float4 vCWts          : TANWEIGHTS;
                };
                TessVertex tessvert (VertexInput v) {
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.texcoord0 = v.texcoord0;
                    return o;
                }
                float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2){
                    return UnityEdgeLengthBasedTess(v.vertex, v1.vertex, v2.vertex, pow((distance(mul(unity_ObjectToWorld, v.vertex).rgb,_WorldSpaceCameraPos)/_Count_teselation),_Distance));
                }
                OutputPatchConstant hullconst (InputPatch<TessVertex,3> v) {
                    OutputPatchConstant o = (OutputPatchConstant)0;
                    float4 ts = Tessellation( v[0], v[1], v[2] );
                    o.edge[0] = ts.x;
                    o.edge[1] = ts.y;
                    o.edge[2] = ts.z;
                    o.inside = ts.w;
                    return o;
                }
                [domain("tri")]
                [partitioning("fractional_odd")]
                [outputtopology("triangle_cw")]
                [patchconstantfunc("hullconst")]
                [outputcontrolpoints(3)]
                TessVertex hull (InputPatch<TessVertex,3> v, uint id : SV_OutputControlPointID) {
                    return v[id];
                }
                [domain("tri")]
                VertexOutput domain (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3> vi, float3 bary : SV_DomainLocation) {
                    VertexInput v = (VertexInput)0;
                    v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
                    v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
                    v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
                    v.texcoord0 = vi[0].texcoord0*bary.x + vi[1].texcoord0*bary.y + vi[2].texcoord0*bary.z;
                    VertexOutput o = vert(v);
                    return o;
                }
            #endif
            float4 frag(VertexOutput i) : COLOR {
                float3 recipObjScale = float3( length(unity_WorldToObject[0].xyz), length(unity_WorldToObject[1].xyz), length(unity_WorldToObject[2].xyz) );
                float3 objScale = 1.0/recipObjScale;
                #if UNITY_UV_STARTS_AT_TOP
                    float grabSign = -_ProjectionParams.x;
                #else
                    float grabSign = _ProjectionParams.x;
                #endif
                i.normalDir = normalize(i.normalDir);
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float4 node_2642 = _Time + _TimeEditor;
                float node_3186 = 5.0;
                float2 node_8616 = ((i.uv0*objScale.r*node_3186)+node_2642.g*float2(0,0.12));
                fixed3 node_5329 = UnpackNormal(tex2D(_Water01,TRANSFORM_TEX(node_8616, _Water01)));
                float2 node_7137 = ((i.uv0*objScale.r*node_3186)+node_2642.g*float2(0.12,-0.12));
                fixed3 node_6790 = UnpackNormal(tex2D(_Water02,TRANSFORM_TEX(node_7137, _Water02)));
                fixed3 node_5741 = UnpackNormal(tex2D(_Wave01,TRANSFORM_TEX(node_8616, _Wave01)));
                fixed3 node_7963 = UnpackNormal(tex2D(_Wave02,TRANSFORM_TEX(node_7137, _Wave02)));
                float3 node_1214 = ((node_5329.rgb+node_6790.rgb)+(node_5741.rgb+node_7963.rgb));
                float2 node_3941 = ((i.uv0*objScale.r)+node_2642.g*float2(0.05,0));
                fixed3 node_2013 = UnpackNormal(tex2D(_Water01,TRANSFORM_TEX(node_3941, _Water01)));
                float2 node_9630 = ((i.uv0*objScale.r)+node_2642.g*float2(-0.05,-0.05));
                fixed3 node_8744 = UnpackNormal(tex2D(_Water02,TRANSFORM_TEX(node_9630, _Water02)));
                fixed3 node_1217 = UnpackNormal(tex2D(_Wave01,TRANSFORM_TEX(node_3941, _Wave01)));
                fixed3 node_5571 = UnpackNormal(tex2D(_Wave02,TRANSFORM_TEX(node_9630, _Wave02)));
                float3 node_825 = ((node_2013.rgb+node_8744.rgb)+(node_1217.rgb+node_5571.rgb));
                float node_250 = 0.1;
                float2 node_6613 = ((i.uv0*objScale.r*node_250)+node_2642.g*float2(0.012,0.008));
                float3 node_4224 = UnpackNormal(tex2D(_Wave01,TRANSFORM_TEX(node_6613, _Wave01)));
                float2 node_1139 = ((i.uv0*objScale.r*node_250)+node_2642.g*float2(-0.01,0));
                float3 node_8785 = UnpackNormal(tex2D(_Wave02,TRANSFORM_TEX(node_1139, _Wave02)));
                float3 node_6911 = (node_4224.rgb+node_8785.rgb);
                fixed zero_hod = 0.0;
                float2 tes_normal_hodx = ((((i.uv0-float2(_PDDistanceChek,zero_hod))/_Speed)+node_2642.g*float2(0.5,0.5))*_Speed);
                fixed4 HeightR = tex2D(_HeightMap,TRANSFORM_TEX(tes_normal_hodx, _HeightMap));
                float2 Tex_normalHody = ((((i.uv0-float2(zero_hod,_PDDistanceChek))/_Speed)+node_2642.g*float2(0.5,0.5))*_Speed);
                fixed4 HeightG = tex2D(_HeightMap,TRANSFORM_TEX(Tex_normalHody, _HeightMap));
                float2 node_2374 = clamp(((float2(HeightR.r,HeightG.r)-HeightG.r)*_Normalstr),-1,1);
                float3 node_8833_nrm_base = lerp(lerp(node_1214,node_825,0.7),node_6911,0.6) + float3(0,0,1);
                float3 node_8833_nrm_detail = float3(node_2374,sqrt((1.0 - dot(node_2374,node_2374)))) * float3(-1,-1,1);
                float3 node_8833_nrm_combined = node_8833_nrm_base*dot(node_8833_nrm_base, node_8833_nrm_detail)/node_8833_nrm_base.z - node_8833_nrm_detail;
                float3 node_8833 = node_8833_nrm_combined;
                float3 normalLocal = node_8833;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);
                float2 sceneUVs = float2(1,grabSign)*i.screenPos.xy*0.5+0.5 + ((lerp(lerp(node_1214,node_825,0.7),node_6911,0.1).rg*clamp(saturate((sceneZ-partZ)/_DepthRefractionBlend),0,1))*_RefractionAmount);
                float4 sceneColor = tex2D(Refraction, sceneUVs);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = 1;
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                fixed gloss = _Gloss;
              
/////// GI Data:
                UnityLight light;
                #ifdef LIGHTMAP_OFF
                    light.color = lightColor;
                    light.dir = lightDirection;
                    light.ndotl = LambertTerm (normalDirection, light.dir);
                #else
                    light.color = half3(0.f, 0.f, 0.f);
                    light.ndotl = 0.0f;
                    light.dir = half3(0.f, 0.f, 0.f);
                #endif
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld.xyz;
                d.worldViewDir = viewDirection;
                d.atten = attenuation;
                #if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMin[0] = unity_SpecCube0_BoxMin;
                    d.boxMin[1] = unity_SpecCube1_BoxMin;
                #endif
                #if UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMax[0] = unity_SpecCube0_BoxMax;
                    d.boxMax[1] = unity_SpecCube1_BoxMax;
                    d.probePosition[0] = unity_SpecCube0_ProbePosition;
                    d.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif
                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                Unity_GlossyEnvironmentData ugls_en_data;
                ugls_en_data.roughness = 1.0 - gloss;
                ugls_en_data.reflUVW = viewReflectDirection;
                UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
                lightDirection = gi.light.dir;
                lightColor = gi.light.color;
////// Specular:
                float NdotL = max(0, dot( normalDirection, lightDirection ));
                float LdotH = max(0.0,dot(lightDirection, halfDirection));
                float node_7624 = 0.2;
                float3 specularColor = float3(node_7624,node_7624,node_7624);
                float specularMonochrome = _specularColor.a;
                float4 Reflect = tex2D(_ReflectionTex,TRANSFORM_TEX(sceneUVs.rg, _ReflectionTex));
                float3 Multiplay_reflect_fersnel = (lerp( texCUBE(_CubeMap,viewReflectDirection).rgb, Reflect.rgb, _RealTimeReflect )*((((1.0 - abs(dot(normalDirection,viewDirection))) + (-1.0)) + _Specular) / (_Specular + 1.0)) * _values_specular );
                float4 node_5368 = tex2D(_Foam,TRANSFORM_TEX(node_1139, _Foam));
                float4 node_3028 = tex2D(_Foam,TRANSFORM_TEX(node_9630, _Foam));
                float3 diffuseColor = saturate((1.0-(1.0-lerp( Multiplay_reflect_fersnel, max(Multiplay_reflect_fersnel,(((node_5368.rgb+node_3028.rgb)*(saturate((sceneZ-partZ)/_ShoreFoamDepth)*-1.0+1.0))*dot(clamp(_LightColor0.rgb,0.2,1),float3(0.3,0.59,0.11)))), _UseFoam ))*(1.0-((_LightColor0.rgb*_FogColor.rgb)*saturate((sceneZ-partZ)/_FogHeight))))); // Need this for specular when using metallic
                diffuseColor = EnergyConservationBetweenDiffuseAndSpecular(diffuseColor, _specularColor, specularMonochrome);
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = max(0.0,dot( normalDirection, viewDirection ));
                float NdotH = max(0.0,dot( normalDirection, halfDirection ));
                float VdotH = max(0.0,dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, 1.0-gloss );
                float normTerm = max(0.0, GGXTerm(NdotH, 1.0-gloss));
                float specularPBL = (NdotL*visTerm*normTerm) * (UNITY_PI / 4);
                if (IsGammaSpace())
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                specularPBL = max(0, specularPBL * NdotL);
                float3 directSpecular = (floor(1) * _LightColor0.xyz)*specularPBL*FresnelTerm(_specularColor, LdotH);
                half grazingTerm = saturate( gloss + specularMonochrome );
                float3 indirectSpecular = (gi.indirect.specular);
                indirectSpecular *= FresnelLerp (specularColor, grazingTerm, NdotV);
                float3 specular = (directSpecular + indirectSpecular);
/////// Diffuse:
                NdotL = dot( normalDirection, lightDirection );
                float transmission_light_warpping = 1.0;
                float3 w = float3(transmission_light_warpping,transmission_light_warpping,transmission_light_warpping)*0.5; // Light wrapping
                float3 NdotLWrap = NdotL * ( 1.0 - w );
                float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
                float3 backLight = max(float3(0.0,0.0,0.0), -NdotLWrap + w ) * float3(transmission_light_warpping,transmission_light_warpping,transmission_light_warpping);
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotLWrap);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((forwardLight+backLight) + ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL)) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                diffuseColor *= 1-specularMonochrome;
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
/// Final Color:
                float3 finalColor = diffuse + specular;
                fixed4 finalRGBA = fixed4(lerp(sceneColor.rgb, finalColor,(saturate((sceneZ-partZ)/_ShoreBlend)*_FogColor.a)),1);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
        Pass {
            Name "FORWARD_DELTA"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            ZWrite Off
            
            CGPROGRAM
            #pragma hull hull
            #pragma domain domain
            #pragma vertex tessvert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDADD
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Tessellation.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdadd
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 
            #pragma target 5.0
            uniform sampler2D Refraction;
            uniform sampler2D _CameraDepthTexture;
            uniform float4 _TimeEditor;
            uniform sampler2D _Wave01; uniform float4 _Wave01_ST;
            uniform fixed _RefractionAmount;
            uniform fixed _ShoreBlend;
            uniform float4 _FogColor;
            uniform sampler2D _ReflectionTex; uniform float4 _ReflectionTex_ST;
            uniform fixed _DepthRefractionBlend;
            uniform float _Fresnel;
            uniform sampler2D _Wave02; uniform float4 _Wave02_ST;
            uniform sampler2D _Water01; uniform float4 _Water01_ST;
            uniform sampler2D _Water02; uniform float4 _Water02_ST;
            uniform float _FogHeight;
            uniform sampler2D _Foam; uniform float4 _Foam_ST;
            uniform float _ShoreFoamDepth;
            uniform fixed _UseFoam;
            uniform fixed _RealTimeReflect;
            uniform samplerCUBE _CubeMap;
            uniform fixed _PDDistanceChek;
            uniform sampler2D _HeightMap; uniform float4 _HeightMap_ST;
            uniform fixed _Normalstr;
            uniform fixed _Vert_offset;
            uniform fixed _Count_teselation;
            uniform fixed _Distance;
            uniform fixed _Speed;
            uniform fixed _Specular;
			uniform fixed _values_specular;
			uniform fixed _Gloss;
			uniform fixed4 _specularColor;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
                float4 projPos : TEXCOORD6;
                LIGHTING_COORDS(7,8)
                UNITY_FOG_COORDS(9)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                float3 recipObjScale = float3( length(unity_WorldToObject[0].xyz), length(unity_WorldToObject[1].xyz), length(unity_WorldToObject[2].xyz) );
                float3 objScale = 1.0/recipObjScale;
                float4 node_9398 = _Time + _TimeEditor;
                float2 Tesselation_hod = (((o.uv0/_Speed)+node_9398.g*float2(0.5,0.5))*_Speed);
                fixed4 Height = tex2Dlod(_HeightMap,float4(TRANSFORM_TEX(Tesselation_hod, _HeightMap),0.0,0));
                v.vertex.xyz += ((Height.r*v.normal)*_Vert_offset);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                o.screenPos = o.pos;
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                struct TessVertex {
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 texcoord0 : TEXCOORD0;
                };
                struct OutputPatchConstant {
                    float edge[3]         : SV_TessFactor;
                    float inside          : SV_InsideTessFactor;
                    float3 vTangent[4]    : TANGENT;
                    float2 vUV[4]         : TEXCOORD;
                    float3 vTanUCorner[4] : TANUCORNER;
                    float3 vTanVCorner[4] : TANVCORNER;
                    float4 vCWts          : TANWEIGHTS;
                };
                TessVertex tessvert (VertexInput v) {
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.texcoord0 = v.texcoord0;
                    return o;
                }
                float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2){
                    return UnityEdgeLengthBasedTess(v.vertex, v1.vertex, v2.vertex, pow((distance(mul(unity_ObjectToWorld, v.vertex).rgb,_WorldSpaceCameraPos)/_Count_teselation),_Distance));
                }
                OutputPatchConstant hullconst (InputPatch<TessVertex,3> v) {
                    OutputPatchConstant o = (OutputPatchConstant)0;
                    float4 ts = Tessellation( v[0], v[1], v[2] );
                    o.edge[0] = ts.x;
                    o.edge[1] = ts.y;
                    o.edge[2] = ts.z;
                    o.inside = ts.w;
                    return o;
                }
                [domain("tri")]
                [partitioning("fractional_odd")]
                [outputtopology("triangle_cw")]
                [patchconstantfunc("hullconst")]
                [outputcontrolpoints(3)]
                TessVertex hull (InputPatch<TessVertex,3> v, uint id : SV_OutputControlPointID) {
                    return v[id];
                }
                [domain("tri")]
                VertexOutput domain (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3> vi, float3 bary : SV_DomainLocation) {
                    VertexInput v = (VertexInput)0;
                    v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
                    v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
                    v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
                    v.texcoord0 = vi[0].texcoord0*bary.x + vi[1].texcoord0*bary.y + vi[2].texcoord0*bary.z;
                    VertexOutput o = vert(v);
                    return o;
                }
            #endif
            float4 frag(VertexOutput i) : COLOR {
                float3 recipObjScale = float3( length(unity_WorldToObject[0].xyz), length(unity_WorldToObject[1].xyz), length(unity_WorldToObject[2].xyz) );
                float3 objScale = 1.0/recipObjScale;
                #if UNITY_UV_STARTS_AT_TOP
                    float grabSign = -_ProjectionParams.x;
                #else
                    float grabSign = _ProjectionParams.x;
                #endif
                i.normalDir = normalize(i.normalDir);
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float4 node_9398 = _Time + _TimeEditor;
                float node_3186 = 5.0;
                float2 node_8616 = ((i.uv0*objScale.r*node_3186)+node_9398.g*float2(0,0.12));
                fixed3 node_5329 = UnpackNormal(tex2D(_Water01,TRANSFORM_TEX(node_8616, _Water01)));
                float2 node_7137 = ((i.uv0*objScale.r*node_3186)+node_9398.g*float2(0.12,-0.12));
                fixed3 node_6790 = UnpackNormal(tex2D(_Water02,TRANSFORM_TEX(node_7137, _Water02)));
                fixed3 node_5741 = UnpackNormal(tex2D(_Wave01,TRANSFORM_TEX(node_8616, _Wave01)));
                fixed3 node_7963 = UnpackNormal(tex2D(_Wave02,TRANSFORM_TEX(node_7137, _Wave02)));
                float3 node_1214 = ((node_5329.rgb+node_6790.rgb)+(node_5741.rgb+node_7963.rgb));
                float2 node_3941 = ((i.uv0*objScale.r)+node_9398.g*float2(0.05,0));
                fixed3 node_2013 = UnpackNormal(tex2D(_Water01,TRANSFORM_TEX(node_3941, _Water01)));
                float2 node_9630 = ((i.uv0*objScale.r)+node_9398.g*float2(-0.05,-0.05));
                fixed3 node_8744 = UnpackNormal(tex2D(_Water02,TRANSFORM_TEX(node_9630, _Water02)));
                fixed3 node_1217 = UnpackNormal(tex2D(_Wave01,TRANSFORM_TEX(node_3941, _Wave01)));
                fixed3 node_5571 = UnpackNormal(tex2D(_Wave02,TRANSFORM_TEX(node_9630, _Wave02)));
                float3 node_825 = ((node_2013.rgb+node_8744.rgb)+(node_1217.rgb+node_5571.rgb));
                float node_250 = 0.1;
                float2 node_6613 = ((i.uv0*objScale.r*node_250)+node_9398.g*float2(0.012,0.008));
                float3 node_4224 = UnpackNormal(tex2D(_Wave01,TRANSFORM_TEX(node_6613, _Wave01)));
                float2 node_1139 = ((i.uv0*objScale.r*node_250)+node_9398.g*float2(-0.01,0));
                float3 node_8785 = UnpackNormal(tex2D(_Wave02,TRANSFORM_TEX(node_1139, _Wave02)));
                float3 node_6911 = (node_4224.rgb+node_8785.rgb);
                fixed zero_hod = 0.0;
                float2 tes_normal_hodx = ((((i.uv0-float2(_PDDistanceChek,zero_hod))/_Speed)+node_9398.g*float2(0.5,0.5))*_Speed);
                fixed4 HeightR = tex2D(_HeightMap,TRANSFORM_TEX(tes_normal_hodx, _HeightMap));
                float2 Tex_normalHody = ((((i.uv0-float2(zero_hod,_PDDistanceChek))/_Speed)+node_9398.g*float2(0.5,0.5))*_Speed);
                fixed4 HeightG = tex2D(_HeightMap,TRANSFORM_TEX(Tex_normalHody, _HeightMap));
                float2 node_2374 = clamp(((float2(HeightR.r,HeightG.r)-HeightG.r)*_Normalstr),-1,1);
                float3 node_8833_nrm_base = lerp(lerp(node_1214,node_825,0.7),node_6911,0.6) + float3(0,0,1);
                float3 node_8833_nrm_detail = float3(node_2374,sqrt((1.0 - dot(node_2374,node_2374)))) * float3(-1,-1,1);
                float3 node_8833_nrm_combined = node_8833_nrm_base*dot(node_8833_nrm_base, node_8833_nrm_detail)/node_8833_nrm_base.z - node_8833_nrm_detail;
                float3 node_8833 = node_8833_nrm_combined;
                float3 normalLocal = node_8833;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);
                float2 sceneUVs = float2(1,grabSign)*i.screenPos.xy*0.5+0.5 + ((lerp(lerp(node_1214,node_825,0.7),node_6911,0.1).rg*clamp(saturate((sceneZ-partZ)/_DepthRefractionBlend),0,1))*_RefractionAmount);
                float4 sceneColor = tex2D(Refraction, sceneUVs);
                float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                fixed gloss = _Gloss;
        
////// Specular:
                float NdotL = max(0, dot( normalDirection, lightDirection ));
                float LdotH = max(0.0,dot(lightDirection, halfDirection));
                float node_7624 = 0.2;
                float3 specularColor = float3(node_7624,node_7624,node_7624);
                float specularMonochrome;
                float4 Reflect = tex2D(_ReflectionTex,TRANSFORM_TEX(sceneUVs.rg, _ReflectionTex));
                float3 Multiplay_reflect_fersnel = (lerp( texCUBE(_CubeMap,viewReflectDirection).rgb, Reflect.rgb, _RealTimeReflect )*((((1.0 - abs(dot(normalDirection,viewDirection))) + (-1.0)) + _Specular) / (_Specular + 1.0)) * _values_specular );
                float4 node_5368 = tex2D(_Foam,TRANSFORM_TEX(node_1139, _Foam));
                float4 node_3028 = tex2D(_Foam,TRANSFORM_TEX(node_9630, _Foam));
                float3 diffuseColor = saturate((1.0-(1.0-lerp( Multiplay_reflect_fersnel, max(Multiplay_reflect_fersnel,(((node_5368.rgb+node_3028.rgb)*(saturate((sceneZ-partZ)/_ShoreFoamDepth)*-1.0+1.0))*dot(clamp(_LightColor0.rgb,0.2,1),float3(0.3,0.59,0.11)))), _UseFoam ))*(1.0-((_LightColor0.rgb*_FogColor.rgb)*saturate((sceneZ-partZ)/_FogHeight))))); // Need this for specular when using metallic
                diffuseColor = EnergyConservationBetweenDiffuseAndSpecular(diffuseColor, specularColor, specularMonochrome);
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = max(0.0,dot( normalDirection, viewDirection ));
                float NdotH = max(0.0,dot( normalDirection, halfDirection ));
                float VdotH = max(0.0,dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, 1.0-gloss );
                float normTerm = max(0.0, GGXTerm(NdotH, 1.0-gloss));
                float specularPBL = (NdotL*visTerm*normTerm) * (UNITY_PI / 4);
                if (IsGammaSpace())
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                specularPBL = max(0, specularPBL * NdotL);
                float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
                float3 specular = directSpecular;
/////// Diffuse:
                NdotL = dot( normalDirection, lightDirection );
                float transmission_light_warpping = 1.0;
                float3 w = float3(transmission_light_warpping,transmission_light_warpping,transmission_light_warpping)*0.5; // Light wrapping
                float3 NdotLWrap = NdotL * ( 1.0 - w );
                float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
                float3 backLight = max(float3(0.0,0.0,0.0), -NdotLWrap + w ) * float3(transmission_light_warpping,transmission_light_warpping,transmission_light_warpping);
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotLWrap);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((forwardLight+backLight) + ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL)) * attenColor;
                diffuseColor *= 1-specularMonochrome;
                float3 diffuse = directDiffuse * diffuseColor;
/// Final Color:
                float3 finalColor = diffuse + specular;
                fixed4 finalRGBA = fixed4(finalColor * (saturate((sceneZ-partZ)/_ShoreBlend)*_FogColor.a),0);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
        Pass {
            Name "ShadowCaster"
            Tags {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            
            CGPROGRAM
            #pragma hull hull
            #pragma domain domain
            #pragma vertex tessvert
            #pragma fragment frag
            #define UNITY_PASS_SHADOWCASTER
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "Tessellation.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 
            #pragma target 5.0
            uniform float4 _TimeEditor;
            uniform sampler2D _HeightMap; uniform float4 _HeightMap_ST;
            uniform fixed _Vert_offset;
            uniform fixed _Count_teselation;
            uniform fixed _Distance;
            uniform fixed _Speed;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                V2F_SHADOW_CASTER;
                float2 uv0 : TEXCOORD1;
                float4 posWorld : TEXCOORD2;
                float3 normalDir : TEXCOORD3;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                float4 node_4446 = _Time + _TimeEditor;
                float2 Tesselation_hod = (((o.uv0/_Speed)+node_4446.g*float2(0.5,0.5))*_Speed);
                fixed4 Height = tex2Dlod(_HeightMap,float4(TRANSFORM_TEX(Tesselation_hod, _HeightMap),0.0,0));
                v.vertex.xyz += ((Height.r*v.normal)*_Vert_offset);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                struct TessVertex {
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 texcoord0 : TEXCOORD0;
                };
                struct OutputPatchConstant {
                    float edge[3]         : SV_TessFactor;
                    float inside          : SV_InsideTessFactor;
                    float3 vTangent[4]    : TANGENT;
                    float2 vUV[4]         : TEXCOORD;
                    float3 vTanUCorner[4] : TANUCORNER;
                    float3 vTanVCorner[4] : TANVCORNER;
                    float4 vCWts          : TANWEIGHTS;
                };
                TessVertex tessvert (VertexInput v) {
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.texcoord0 = v.texcoord0;
                    return o;
                }
                float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2){
                    return UnityEdgeLengthBasedTess(v.vertex, v1.vertex, v2.vertex, pow((distance(mul(unity_ObjectToWorld, v.vertex).rgb,_WorldSpaceCameraPos)/_Count_teselation),_Distance));
                }
                OutputPatchConstant hullconst (InputPatch<TessVertex,3> v) {
                    OutputPatchConstant o = (OutputPatchConstant)0;
                    float4 ts = Tessellation( v[0], v[1], v[2] );
                    o.edge[0] = ts.x;
                    o.edge[1] = ts.y;
                    o.edge[2] = ts.z;
                    o.inside = ts.w;
                    return o;
                }
                [domain("tri")]
                [partitioning("fractional_odd")]
                [outputtopology("triangle_cw")]
                [patchconstantfunc("hullconst")]
                [outputcontrolpoints(3)]
                TessVertex hull (InputPatch<TessVertex,3> v, uint id : SV_OutputControlPointID) {
                    return v[id];
                }
                [domain("tri")]
                VertexOutput domain (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3> vi, float3 bary : SV_DomainLocation) {
                    VertexInput v = (VertexInput)0;
                    v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
                    v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
                    v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
                    v.texcoord0 = vi[0].texcoord0*bary.x + vi[1].texcoord0*bary.y + vi[2].texcoord0*bary.z;
                    VertexOutput o = vert(v);
                    return o;
                }
            #endif
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3 normalDirection = i.normalDir;
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
