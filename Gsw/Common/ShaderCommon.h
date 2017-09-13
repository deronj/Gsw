//
//  ShaderCommon.h
//  Gsw
//
//  Created by Deron Johnson on 7/7/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

// These types are shared among Metal shaders

#ifndef ShaderCommon_h
#define ShaderCommon_h

/////////////////////////////
// Per-vertex input structures

typedef struct {
    float3 position [[attribute(VertexAttributeDescriptorIndexPosition)]];
} Vertex_Input_Untextured_Unlit;

typedef struct {
    float3 position [[attribute(VertexAttributeDescriptorIndexPosition)]];
    float3 normal   [[attribute(VertexAttributeDescriptorIndexNormal)]];
} Vertex_Input_Untextured_Lit;

typedef struct {
    float3 position [[attribute(VertexAttributeDescriptorIndexPosition)]];
    half2  texcoord [[attribute(VertexAttributeDescriptorIndexTexcoord)]];
} Vertex_Input_Textured_Unlit;

typedef struct {
    float3 position [[attribute(VertexAttributeDescriptorIndexPosition)]];
    float3 normal   [[attribute(VertexAttributeDescriptorIndexNormal)]];
    half2 texcoord [[attribute(VertexAttributeDescriptorIndexTexcoord)]];
} Vertex_Input_Textured_Lit;

/////////////////////////////////////////////
// Per-vertex outputs and per-fragment inputs

typedef struct {
    float4 positionCC [[position]];
} Vertex_Output_Untextured_Unlit;

typedef struct {
    float4 positionCC [[position]];
    float3 eyeVecEC;            // Vector from the vertex to the eye (in eye coords)
    float3 normalEC;            // Vertex normal in eye coords

    // For positional lights only. Otherwise 0.
    float3 lightDirection0EC;   // Vector from the vertex to light 0 (in eye coords)
    float3 lightDirection1EC;   // Vector from the vertex to light 1(in eye coords)
} Vertex_Output_Untextured_Lit;

typedef struct {
    float4 positionCC [[position]];
    half2  texcoord;
} Vertex_Output_Textured_Unlit;

typedef struct {
    float4 positionCC [[position]];
    float3 normalEC;
    half2  texcoord;
} Vertex_Output_Textured_Lit;

#endif /* ShaderCommon_h */
