//
//  RenderPassShaders.metal
//  Gsw
//
//  Created by Deron Johnson on 7/6/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "Common/ShaderTypesBridge.h"
#include "Common/ShaderCommon.h"

/////////////////
// Vertex Shaders

vertex Vertex_Output_Untextured_Unlit vertex_Untextured_Unlit(
    Vertex_Input_Untextured_Unlit in [[stage_in]],
    device const PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]])
{
    Vertex_Output_Untextured_Unlit out;

    // Project world coordinate position to clip coordinates
    float4 inPosition = float4(in.position, 1.0);
    out.positionCC = perObjectMatrices.projectionViewModelMatrix * inPosition;
    
    return out;
}

vertex Vertex_Output_Untextured_Lit vertex_Untextured_Lit_General(
    Vertex_Input_Untextured_Lit in [[stage_in]],
    constant LightsStruct& lights [[buffer(LightsBufferBindIndex)]],
    device const PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]])
{
    Vertex_Output_Untextured_Lit out;
    
    // Project world coordinate position to clip coordinates
    float4 inPosition = float4(in.position, 1.0);
    out.positionCC = perObjectMatrices.projectionViewModelMatrix * inPosition;    
    
    // The vector from the eye position to the vertex (in eye coords)
    float3 vertexPosEC = float3(0.0, 0.0, 0.0);
    if (lights.light0.type == LightTypePositional || lights.light1.type == LightTypePositional)
    {
        // From OpenGL Shading Language (Orange Book), p. 271
        float4 vertexPosEC4 = perObjectMatrices.viewModelMatrix * inPosition;
        vertexPosEC = (float3(vertexPosEC4) / vertexPosEC4.w);
    }

    // We must reverse direction so the vector goes from the vertex to the eye
    out.eyeVecEC = float3(-vertexPosEC);
    
    // The vertex normal in eye coords
    out.normalEC = normalize(float3(perObjectMatrices.normalMatrix * in.normal));
    
    out.lightDirection0EC = (lights.light0.type == LightTypePositional)
                              ? lights.light0.lightPositionEC - vertexPosEC
                              : float3(0.0, 0.0, 0.0);
    out.lightDirection1EC = (lights.light1.type == LightTypePositional)
                              ? lights.light1.lightPositionEC - vertexPosEC
                              : float3(0.0, 0.0, 0.0);

    return out;
}

vertex Vertex_Output_Untextured_Lit vertex_Untextured_Lit_1dir(
                                                                  
    Vertex_Input_Untextured_Lit in [[stage_in]],
    device const PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]])
{
    Vertex_Output_Untextured_Lit out;
    
    // Project world coordinate position to clip coordinates
    float4 inPosition = float4(in.position, 1.0);
    out.positionCC = perObjectMatrices.projectionViewModelMatrix * inPosition;    

    // The vertex normal in eye coords
    out.normalEC = normalize(perObjectMatrices.normalMatrix * in.normal);
    
    return out;
}

vertex
#if DEBUG_VERTEX_SHADER
void
#else
Vertex_Output_Textured_Unlit
#endif
vertex_Textured_Unlit(
    Vertex_Input_Textured_Unlit in [[stage_in]],
#if DEBUG_VERTEX_SHADER
    device Vertex_Output_Textured_Unlit* debugBuffer [[buffer(DebugBufferBindIndex)]],
    uint vid [[ vertex_id ]],
#endif
    device PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]])
{
    Vertex_Output_Textured_Unlit out;
    
    // Project world coordinate position to clip coordinates
    float4 inPosition = float4(in.position, 1.0);
    out.positionCC = perObjectMatrices.projectionViewModelMatrix * inPosition;    

    // Pass through texcoord
    out.texcoord = in.texcoord;

#if DEBUG_VERTEX_SHADER
    if (vid < DEBUG_VERTEX_SHADER_NUM_VERTICES)
    {
        debugBuffer[vid] = out;
    }
#else
    return out;
#endif
}

vertex Vertex_Output_Textured_Lit vertex_Textured_Lit(
    Vertex_Input_Textured_Lit in [[stage_in]],
    device const PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]])
{
    Vertex_Output_Textured_Lit out;
    
    // Project world coordinate position to clip coordinates
    float4 inPosition = float4(in.position, 1.0);
    out.positionCC = perObjectMatrices.projectionViewModelMatrix * inPosition;    
    
    // Pass through normal and texture coordinates
    out.normalEC = in.normal;
    out.texcoord = in.texcoord;
    
    return out;
}

///////////////////
// Fragment Shaders

fragment half4 fragment_Untextured_Unlit(
    Vertex_Output_Untextured_Unlit in [[ stage_in ]])
{
    // Unlit material is chosen to be 50% gray
    return half4(0.5f, 0.5f, 0.5f, 1.0f);
}

fragment half4 fragment_Untextured_Lit_General(
    Vertex_Output_Untextured_Lit in [[ stage_in ]],
    device const PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]],
    constant LightsStruct& lights [[buffer(LightsBufferBindIndex)]],
    constant MaterialStruct& material [[buffer(MaterialBufferBindIndex)]])
{
    // Compute ambient terms
    float4 ambientColor0 = lights.light0.ambientColor * material.ambientReflectance;
    float4 ambientColor1 = lights.light1.ambientColor * material.ambientReflectance;
    
    // normalize both input vectors
    float3 normalEC = normalize(in.normalEC);
    float3 eyeVecEC = normalize(in.eyeVecEC);
    
    // Compute light directions
    // TODO: positional
    float3 lightDirection0EC = lights.light0.lightDirectionEC;
    float3 lightDirection1EC = lights.light1.lightDirectionEC;
    
    // Compute diffuse terms
    float diffuseIntensity0 = max(dot(normalEC, lightDirection0EC), 0.0);
    float diffuseIntensity1 = max(dot(normalEC, lightDirection1EC), 0.0);
    float4 diffuseColor0 = diffuseIntensity0 * lights.light0.diffuseColor * material.diffuseReflectance;
    float4 diffuseColor1 = diffuseIntensity1 * lights.light1.diffuseColor * material.diffuseReflectance;
    
    // If the vertex is lit compute the specular colors
    float4 specularColor0 = float4(0.0);
    float4 specularColor1 = float4(0.0);
    if (diffuseIntensity0 > 0.0)
    {
        float3 halfAngleVecEC = normalize(lightDirection0EC + eyeVecEC);
        float specularIntensity = max(dot(halfAngleVecEC, normalEC), 0.0);
        specularColor0 = pow(specularIntensity, material.shininess) *
                         lights.light0.specularColor * material.specularReflectance;
    }
    if (diffuseIntensity1 > 0.0)
    {
        float3 halfAngleVecEC = normalize(lightDirection1EC + eyeVecEC);
        float specularIntensity = max(dot(halfAngleVecEC, normalEC), 0.0);
        specularColor1 = pow(specularIntensity, material.shininess) *
                         lights.light1.specularColor * material.specularReflectance;
    }

    // Sum lighting terms and saturate (aka clamp to 1).
    // And saturate (aka clamp to 1) so it will fit into a half4
    float4 color = material.emissiveColor;
    color += ambientColor0 + diffuseColor0 + specularColor0;
    color += ambientColor1 + diffuseColor1 + specularColor1;
    color = saturate(color);
    
    return half4(color);
}

fragment half4 fragment_Untextured_Lit_1dir(
    Vertex_Output_Untextured_Lit in [[ stage_in ]],
    device const PerObjectMatrices& perObjectMatrices [[buffer(PerObjectMatricesBufferBindIndex)]],
    constant LightsStruct& lights [[buffer(LightsBufferBindIndex)]],
    constant MaterialStruct& material [[buffer(MaterialBufferBindIndex)]])
{
    // Compute ambient terms
    float4 ambientColor0 = lights.light0.ambientColor * material.ambientReflectance;
    
    // normalize input vectors
    float3 normalEC = normalize(in.normalEC);

    // Compute light directions
    float3 lightDirection0EC = lights.light0.lightDirectionEC;
    
    // Compute diffuse terms
    float diffuseIntensity0 = max(dot(normalEC, lightDirection0EC), 0.0);
    float4 diffuseColor0 = diffuseIntensity0 * lights.light0.diffuseColor * material.diffuseReflectance;
    
    // If the vertex is lit compute the specular colors
    float4 specularColor0 = float4(0.0);
    if (diffuseIntensity0 > 0.0)
    {
        float specularIntensity = max(dot(lights.light0.halfAngleVecEC, normalEC), 0.0);
        specularColor0 = pow(specularIntensity, material.shininess) *
                         lights.light0.specularColor * material.specularReflectance;
    }
    
    // Sum lighting terms and saturate (aka clamp to 1).
    // And saturate (aka clamp to 1) so it will fit into a half4
    float4 color = material.emissiveColor;
    color += ambientColor0 + diffuseColor0 + specularColor0;
    color = saturate(color);
    
    // DEBUG
    //color = float4(0.0, 0.0, 0.0, 1.0);
    
    return half4(color);
}

fragment half4 fragment_Textured_Unlit(
    Vertex_Output_Textured_Unlit in [[ stage_in ]],
    texture2d<half> diffuseTexture [[texture(DiffuseTextureBindIndex)]])
{
    // TODO
    constexpr sampler defaultSampler;

    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord));

    return color;
}

fragment half4 fragment_Textured_Lit(
    Vertex_Output_Textured_Lit in [[stage_in]],
    texture2d<half> diffuseTexture [[texture(DiffuseTextureBindIndex)]])
{
    // TODO
    constexpr sampler defaultSampler;
    
    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord));
    
    // TODO: Light
    
    return color;
}
    
    
    

