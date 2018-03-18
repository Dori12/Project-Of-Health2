Shader "RR/Road" {
    Properties {
        _MainTex ("Road Albedo", 2D) = "white" {}
        _RoadColor ("Road Color", Color) = (1,1,1,1)
        _BumpMap ("Road Normal", 2D) = "bump" {}
        Mrao ("Road MRAO", 2D) = "white" {}
        _Roughness ("Roughness", Range(0, 2)) = 1
        _Terrain ("Terrain Albedo", 2D) = "white" {}
        _terrain_normal ("Terrain Normal", 2D) = "bump" {}
        _TerrainTile ("Terrain Tile", Float ) = 4
        _BrightnessDetail ("Brightness Detail", Range(1, 10)) = 5
        _DetailAlbedo ("Detail Albedo", 2D) = "white" {}
        _DetailNormal ("Detail Normal", 2D) = "bump" {}
        _Tiledetailx ("Tile detail x", Float ) = 1
        _Tiledetaily ("Tile detail y", Float ) = 1
        _VertexAlpha ("Vertex Alpha", Range(0, 1)) = 0
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "DEFERRED"
            Tags {
                "LightMode"="Deferred"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_DEFERRED
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile ___ UNITY_HDR_ON
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma exclude_renderers d3d9 opengl gles gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform fixed4 _RoadColor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
            uniform sampler2D _Terrain; uniform float4 _Terrain_ST;
            uniform sampler2D _terrain_normal; uniform float4 _terrain_normal_ST;
            uniform sampler2D Mrao; uniform float4 Mrao_ST;
            uniform fixed _VertexAlpha;
            uniform float _TerrainTile;
            uniform sampler2D _DetailAlbedo; uniform float4 _DetailAlbedo_ST;
            uniform sampler2D _DetailNormal; uniform float4 _DetailNormal_ST;
            uniform float _Tiledetailx;
            uniform float _Tiledetaily;
            uniform float _Roughness;
            uniform float _BrightnessDetail;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float4 posWorld : TEXCOORD3;
                float3 normalDir : TEXCOORD4;
                float3 tangentDir : TEXCOORD5;
                float3 bitangentDir : TEXCOORD6;
                float4 vertexColor : COLOR;
                #if defined(LIGHTMAP_ON) || defined(UNITY_SHOULD_SAMPLE_SH)
                    float4 ambientOrLightmapUV : TEXCOORD7;
                #endif
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                o.vertexColor = v.vertexColor;
                #ifdef LIGHTMAP_ON
                    o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    o.ambientOrLightmapUV.zw = 0;
                #elif UNITY_SHOULD_SAMPLE_SH
                #endif
                #ifdef DYNAMICLIGHTMAP_ON
                    o.ambientOrLightmapUV.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex );
                return o;
            }
            void frag(
                VertexOutput i,
                out half4 outDiffuse : SV_Target0,
                out half4 outSpecSmoothness : SV_Target1,
                out half4 outNormal : SV_Target2,
                out half4 outEmission : SV_Target3 )
            {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float2 Divader = (i.posWorld.rgb.rb/_TerrainTile);
                fixed3 _terrain_normal_var = UnpackNormal(tex2D(_terrain_normal,TRANSFORM_TEX(Divader, _terrain_normal)));
                fixed3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
                float2 node_9436 = (i.uv0*float2(_Tiledetailx,_Tiledetaily));
                fixed3 _DetailNormal_var = UnpackNormal(tex2D(_DetailNormal,TRANSFORM_TEX(node_9436, _DetailNormal)));
                float3 blend_normal_nrm_base = _BumpMap_var.rgb + float3(0,0,1);
                float3 blend_normal_nrm_detail = _DetailNormal_var.rgb * float3(-1,-1,1);
                float3 blend_normal_nrm_combined = blend_normal_nrm_base*dot(blend_normal_nrm_base, blend_normal_nrm_detail)/blend_normal_nrm_base.z - blend_normal_nrm_detail;
                fixed3 blend_normal = blend_normal_nrm_combined;
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                fixed node_2710 = (_MainTex_var.a*(1.0 - lerp(0.0,_VertexAlpha,i.vertexColor.r)));
                float3 normalLocal = lerp(_terrain_normal_var.rgb,blend_normal,node_2710);
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
////// Lighting:
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                fixed4 _Terrain_var = tex2D(_Terrain,TRANSFORM_TEX(Divader, _Terrain));
                fixed4 Mrao_var = tex2D(Mrao,TRANSFORM_TEX(i.uv0, Mrao));
                float gloss = lerp(_Terrain_var.a,(1.0 - (_Roughness*Mrao_var.g)),node_2710);
/////// GI Data:
                UnityLight light; // Dummy light
                light.color = 0;
                light.dir = half3(0,1,0);
                light.ndotl = max(0,dot(normalDirection,light.dir));
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld.xyz;
                d.worldViewDir = viewDirection;
                d.atten = 1;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    d.ambient = 0;
                    d.lightmapUV = i.ambientOrLightmapUV;
                #else
                    d.ambient = i.ambientOrLightmapUV;
                #endif
                d.boxMax[0] = unity_SpecCube0_BoxMax;
                d.boxMin[0] = unity_SpecCube0_BoxMin;
                d.probePosition[0] = unity_SpecCube0_ProbePosition;
                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.boxMax[1] = unity_SpecCube1_BoxMax;
                d.boxMin[1] = unity_SpecCube1_BoxMin;
                d.probePosition[1] = unity_SpecCube1_ProbePosition;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                Unity_GlossyEnvironmentData ugls_en_data;
                ugls_en_data.roughness = 1.0 - gloss;
                ugls_en_data.reflUVW = viewReflectDirection;
                UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
////// Specular:
                float3 specularColor = 0.0;
                float specularMonochrome;
                fixed4 _DetailAlbedo_var = tex2D(_DetailAlbedo,TRANSFORM_TEX(node_9436, _DetailAlbedo));
                float node_4603_if_leA = step(_DetailAlbedo_var.rgb,1.0);
                float node_4603_if_leB = step(1.0,_DetailAlbedo_var.rgb);
                float3 diffuseColor = (lerp(_Terrain_var.rgb,lerp((node_4603_if_leA*saturate(((_BrightnessDetail*_DetailAlbedo_var.rgb)*_MainTex_var.rgb)))+(node_4603_if_leB*_MainTex_var.rgb),_MainTex_var.rgb,node_4603_if_leA*node_4603_if_leB),node_2710)*_RoadColor.rgb); // Need this for specular when using metallic
                diffuseColor = DiffuseAndSpecularFromMetallic( diffuseColor, specularColor, specularColor, specularMonochrome );
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = max(0.0,dot( normalDirection, viewDirection ));
                half grazingTerm = saturate( gloss + specularMonochrome );
                float3 indirectSpecular = (gi.indirect.specular);
                indirectSpecular *= FresnelLerp (specularColor, grazingTerm, NdotV);
/////// Diffuse:
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += gi.indirect.diffuse;
                float node_9630 = lerp(1.0,Mrao_var.b,node_2710);
                indirectDiffuse *= node_9630; // Diffuse AO
/// Final Color:
                outDiffuse = half4( diffuseColor, node_9630 );
                outSpecSmoothness = half4( specularColor, gloss );
                outNormal = half4( normalDirection * 0.5 + 0.5, 1 );
                outEmission = half4(0,0,0,1);
                outEmission.rgb += indirectSpecular * node_9630;
                outEmission.rgb += indirectDiffuse * diffuseColor;
                #ifndef UNITY_HDR_ON
                    outEmission.rgb = exp2(-outEmission.rgb);
                #endif
            }
            ENDCG
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            
            
            Stencil {
                Ref 128
                Fail Replace
                ZFail Invert
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma exclude_renderers d3d9 opengl gles gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform fixed4 _RoadColor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
            uniform sampler2D _Terrain; uniform float4 _Terrain_ST;
            uniform sampler2D _terrain_normal; uniform float4 _terrain_normal_ST;
            uniform sampler2D Mrao; uniform float4 Mrao_ST;
            uniform fixed _VertexAlpha;
            uniform float _TerrainTile;
            uniform sampler2D _DetailAlbedo; uniform float4 _DetailAlbedo_ST;
            uniform sampler2D _DetailNormal; uniform float4 _DetailNormal_ST;
            uniform float _Tiledetailx;
            uniform float _Tiledetaily;
            uniform float _Roughness;
            uniform float _BrightnessDetail;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float4 posWorld : TEXCOORD3;
                float3 normalDir : TEXCOORD4;
                float3 tangentDir : TEXCOORD5;
                float3 bitangentDir : TEXCOORD6;
                float4 vertexColor : COLOR;
                LIGHTING_COORDS(7,8)
                #if defined(LIGHTMAP_ON) || defined(UNITY_SHOULD_SAMPLE_SH)
                    float4 ambientOrLightmapUV : TEXCOORD9;
                #endif
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                o.vertexColor = v.vertexColor;
                #ifdef LIGHTMAP_ON
                    o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    o.ambientOrLightmapUV.zw = 0;
                #elif UNITY_SHOULD_SAMPLE_SH
                #endif
                #ifdef DYNAMICLIGHTMAP_ON
                    o.ambientOrLightmapUV.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex );
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float2 Divader = (i.posWorld.rgb.rb/_TerrainTile);
                fixed3 _terrain_normal_var = UnpackNormal(tex2D(_terrain_normal,TRANSFORM_TEX(Divader, _terrain_normal)));
                fixed3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
                float2 node_9436 = (i.uv0*float2(_Tiledetailx,_Tiledetaily));
                fixed3 _DetailNormal_var = UnpackNormal(tex2D(_DetailNormal,TRANSFORM_TEX(node_9436, _DetailNormal)));
                float3 blend_normal_nrm_base = _BumpMap_var.rgb + float3(0,0,1);
                float3 blend_normal_nrm_detail = _DetailNormal_var.rgb * float3(-1,-1,1);
                float3 blend_normal_nrm_combined = blend_normal_nrm_base*dot(blend_normal_nrm_base, blend_normal_nrm_detail)/blend_normal_nrm_base.z - blend_normal_nrm_detail;
                fixed3 blend_normal = blend_normal_nrm_combined;
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                fixed node_2710 = (_MainTex_var.a*(1.0 - lerp(0.0,_VertexAlpha,i.vertexColor.r)));
                float3 normalLocal = lerp(_terrain_normal_var.rgb,blend_normal,node_2710);
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                fixed4 _Terrain_var = tex2D(_Terrain,TRANSFORM_TEX(Divader, _Terrain));
                fixed4 Mrao_var = tex2D(Mrao,TRANSFORM_TEX(i.uv0, Mrao));
                float gloss = lerp(_Terrain_var.a,(1.0 - (_Roughness*Mrao_var.g)),node_2710);
                float specPow = exp2( gloss * 10.0+1.0);
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
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    d.ambient = 0;
                    d.lightmapUV = i.ambientOrLightmapUV;
                #else
                    d.ambient = i.ambientOrLightmapUV;
                #endif
                d.boxMax[0] = unity_SpecCube0_BoxMax;
                d.boxMin[0] = unity_SpecCube0_BoxMin;
                d.probePosition[0] = unity_SpecCube0_ProbePosition;
                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.boxMax[1] = unity_SpecCube1_BoxMax;
                d.boxMin[1] = unity_SpecCube1_BoxMin;
                d.probePosition[1] = unity_SpecCube1_ProbePosition;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                Unity_GlossyEnvironmentData ugls_en_data;
                ugls_en_data.roughness = 1.0 - gloss;
                ugls_en_data.reflUVW = viewReflectDirection;
                UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
                lightDirection = gi.light.dir;
                lightColor = gi.light.color;
////// Specular:
                float NdotL = max(0, dot( normalDirection, lightDirection ));
                float node_9630 = lerp(1.0,Mrao_var.b,node_2710);
                float3 specularAO = node_9630;
                float LdotH = max(0.0,dot(lightDirection, halfDirection));
                float3 specularColor = 0.0;
                float specularMonochrome;
                fixed4 _DetailAlbedo_var = tex2D(_DetailAlbedo,TRANSFORM_TEX(node_9436, _DetailAlbedo));
                float node_4603_if_leA = step(_DetailAlbedo_var.rgb,1.0);
                float node_4603_if_leB = step(1.0,_DetailAlbedo_var.rgb);
                float3 diffuseColor = (lerp(_Terrain_var.rgb,lerp((node_4603_if_leA*saturate(((_BrightnessDetail*_DetailAlbedo_var.rgb)*_MainTex_var.rgb)))+(node_4603_if_leB*_MainTex_var.rgb),_MainTex_var.rgb,node_4603_if_leA*node_4603_if_leB),node_2710)*_RoadColor.rgb); // Need this for specular when using metallic
                diffuseColor = DiffuseAndSpecularFromMetallic( diffuseColor, specularColor, specularColor, specularMonochrome );
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
                float3 directSpecular = (floor(attenuation) * _LightColor0.xyz)*specularPBL*FresnelTerm(specularColor, LdotH);
                half grazingTerm = saturate( gloss + specularMonochrome );
                float3 indirectSpecular = (gi.indirect.specular) * specularAO;
                indirectSpecular *= FresnelLerp (specularColor, grazingTerm, NdotV);
                float3 specular = (directSpecular + indirectSpecular);
/////// Diffuse:
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotL);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += gi.indirect.diffuse;
                indirectDiffuse *= node_9630; // Diffuse AO
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
/// Final Color:
                float3 finalColor = diffuse + specular;
                return fixed4(finalColor,1);
            }
            ENDCG
        }
        Pass {
            Name "FORWARD_DELTA"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDADD
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma exclude_renderers d3d9 opengl gles gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform fixed4 _RoadColor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
            uniform sampler2D _Terrain; uniform float4 _Terrain_ST;
            uniform sampler2D _terrain_normal; uniform float4 _terrain_normal_ST;
            uniform sampler2D Mrao; uniform float4 Mrao_ST;
            uniform fixed _VertexAlpha;
            uniform float _TerrainTile;
            uniform sampler2D _DetailAlbedo; uniform float4 _DetailAlbedo_ST;
            uniform sampler2D _DetailNormal; uniform float4 _DetailNormal_ST;
            uniform float _Tiledetailx;
            uniform float _Tiledetaily;
            uniform float _Roughness;
            uniform float _BrightnessDetail;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float4 posWorld : TEXCOORD3;
                float3 normalDir : TEXCOORD4;
                float3 tangentDir : TEXCOORD5;
                float3 bitangentDir : TEXCOORD6;
                float4 vertexColor : COLOR;
                LIGHTING_COORDS(7,8)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                o.vertexColor = v.vertexColor;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos(v.vertex );
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                i.normalDir = normalize(i.normalDir);
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float2 Divader = (i.posWorld.rgb.rb/_TerrainTile);
                fixed3 _terrain_normal_var = UnpackNormal(tex2D(_terrain_normal,TRANSFORM_TEX(Divader, _terrain_normal)));
                fixed3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
                float2 node_9436 = (i.uv0*float2(_Tiledetailx,_Tiledetaily));
                fixed3 _DetailNormal_var = UnpackNormal(tex2D(_DetailNormal,TRANSFORM_TEX(node_9436, _DetailNormal)));
                float3 blend_normal_nrm_base = _BumpMap_var.rgb + float3(0,0,1);
                float3 blend_normal_nrm_detail = _DetailNormal_var.rgb * float3(-1,-1,1);
                float3 blend_normal_nrm_combined = blend_normal_nrm_base*dot(blend_normal_nrm_base, blend_normal_nrm_detail)/blend_normal_nrm_base.z - blend_normal_nrm_detail;
                fixed3 blend_normal = blend_normal_nrm_combined;
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                fixed node_2710 = (_MainTex_var.a*(1.0 - lerp(0.0,_VertexAlpha,i.vertexColor.r)));
                float3 normalLocal = lerp(_terrain_normal_var.rgb,blend_normal,node_2710);
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                fixed4 _Terrain_var = tex2D(_Terrain,TRANSFORM_TEX(Divader, _Terrain));
                fixed4 Mrao_var = tex2D(Mrao,TRANSFORM_TEX(i.uv0, Mrao));
                float gloss = lerp(_Terrain_var.a,(1.0 - (_Roughness*Mrao_var.g)),node_2710);
                float specPow = exp2( gloss * 10.0+1.0);
////// Specular:
                float NdotL = max(0, dot( normalDirection, lightDirection ));
                float LdotH = max(0.0,dot(lightDirection, halfDirection));
                float3 specularColor = 0.0;
                float specularMonochrome;
                fixed4 _DetailAlbedo_var = tex2D(_DetailAlbedo,TRANSFORM_TEX(node_9436, _DetailAlbedo));
                float node_4603_if_leA = step(_DetailAlbedo_var.rgb,1.0);
                float node_4603_if_leB = step(1.0,_DetailAlbedo_var.rgb);
                float3 diffuseColor = (lerp(_Terrain_var.rgb,lerp((node_4603_if_leA*saturate(((_BrightnessDetail*_DetailAlbedo_var.rgb)*_MainTex_var.rgb)))+(node_4603_if_leB*_MainTex_var.rgb),_MainTex_var.rgb,node_4603_if_leA*node_4603_if_leB),node_2710)*_RoadColor.rgb); // Need this for specular when using metallic
                diffuseColor = DiffuseAndSpecularFromMetallic( diffuseColor, specularColor, specularColor, specularMonochrome );
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
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotL);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL) * attenColor;
                float3 diffuse = directDiffuse * diffuseColor;
/// Final Color:
                float3 finalColor = diffuse + specular;
                return fixed4(finalColor * 1,0);
            }
            ENDCG
        }
        Pass {
            Name "Meta"
            Tags {
                "LightMode"="Meta"
            }
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_META 1
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityMetaPass.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma exclude_renderers d3d9 opengl gles gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform fixed4 _RoadColor;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _Terrain; uniform float4 _Terrain_ST;
            uniform sampler2D Mrao; uniform float4 Mrao_ST;
            uniform fixed _VertexAlpha;
            uniform float _TerrainTile;
            uniform sampler2D _DetailAlbedo; uniform float4 _DetailAlbedo_ST;
            uniform float _Tiledetailx;
            uniform float _Tiledetaily;
            uniform float _Roughness;
            uniform float _BrightnessDetail;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float4 posWorld : TEXCOORD3;
                float4 vertexColor : COLOR;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                o.vertexColor = v.vertexColor;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST );
                return o;
            }
            float4 frag(VertexOutput i) : SV_Target {
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT( UnityMetaInput, o );
                
                o.Emission = 0;
                
                float2 Divader = (i.posWorld.rgb.rb/_TerrainTile);
                fixed4 _Terrain_var = tex2D(_Terrain,TRANSFORM_TEX(Divader, _Terrain));
                float2 node_9436 = (i.uv0*float2(_Tiledetailx,_Tiledetaily));
                fixed4 _DetailAlbedo_var = tex2D(_DetailAlbedo,TRANSFORM_TEX(node_9436, _DetailAlbedo));
                float node_4603_if_leA = step(_DetailAlbedo_var.rgb,1.0);
                float node_4603_if_leB = step(1.0,_DetailAlbedo_var.rgb);
                fixed4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                fixed node_2710 = (_MainTex_var.a*(1.0 - lerp(0.0,_VertexAlpha,i.vertexColor.r)));
                float3 diffColor = (lerp(_Terrain_var.rgb,lerp((node_4603_if_leA*saturate(((_BrightnessDetail*_DetailAlbedo_var.rgb)*_MainTex_var.rgb)))+(node_4603_if_leB*_MainTex_var.rgb),_MainTex_var.rgb,node_4603_if_leA*node_4603_if_leB),node_2710)*_RoadColor.rgb);
                float specularMonochrome;
                float3 specColor;
                diffColor = DiffuseAndSpecularFromMetallic( diffColor, 0.0, specColor, specularMonochrome );
                fixed4 Mrao_var = tex2D(Mrao,TRANSFORM_TEX(i.uv0, Mrao));
                float roughness = 1.0 - lerp(_Terrain_var.a,(1.0 - (_Roughness*Mrao_var.g)),node_2710);
                o.Albedo = diffColor + specColor * roughness * roughness * 0.5;
                
                return UnityMetaFragment( o );
            }
            ENDCG
        }
    }
    FallBack "Standard"
}
