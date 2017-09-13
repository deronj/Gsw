//
//  ShaderTypesBridge.h
//  Gsw
//
//  Created by Deron Johnson on 7/11/17.
//  Copyright © 2017 Deron Johnson. All rights reserved.
//

#ifndef ShaderTypesBridge_h
#define ShaderTypesBridge_h

#include <simd/simd.h>

#define DEBUG_VERTEX_SHADER 0

// For Debug
#define DEBUG_VERTEX_SHADER_NUM_VERTICES 10

// These types are shared by both Swift files and Metal Shaders.

// Indices of vertex attribute in descriptor.
// Note: this is a convention that Model I/O uses. We also follow it for other types of objects.
enum VertexAttributesBindIndex
{
    VertexAttributeDescriptorIndexPosition = 0,
    VertexAttributeDescriptorIndexNormal   = 1,
    VertexAttributeDescriptorIndexTexcoord = 2,
};

// Indices for texture bind points.
// (By convention, in this renderer, this is the same for both vertex and fragment shaders).
enum TextureBindIndex
{
    DiffuseTextureBindIndex = 0
};

// Indices for buffer bind points.
// (By convention in this renderer, this is the same for both vertex and fragment shaders).
enum BufferBindIndex
{
    GeometryVertexBufferBindIndex       = 0,
    PerObjectMatricesBufferBindIndex    = 1,
    MaterialBufferBindIndex             = 2,
    LightsBufferBindIndex               = 3,

    // For Debug
    DebugBufferBindIndex                = 15,
};

// These transforms are per-object because they depend on the model matrix
struct PerObjectMatrices
{
    matrix_float4x4 viewModelMatrix;
    matrix_float4x4 projectionViewModelMatrix;
    matrix_float3x3 normalMatrix;
    
    matrix_float4x4 viewMatrix;             // TODOXXX: no longer used?
    matrix_float4x4 projectionViewMatrix;   // TODOXXX: no longer used?
};

struct MaterialStruct
{
    vector_float4 emissiveColor;
    vector_float4 ambientReflectance;
    vector_float4 diffuseReflectance;
    vector_float4 specularReflectance;
    float         shininess;
};

////////////////////
// Info for Lighting
//
// TODO: eventually we want to support two lights, either of which may be directional or positional.
 
typedef enum
{
    LightTypeDisabled    = 0,
    LightTypeDirectional = 1,
    LightTypePositional  = 2,
} LightType;

typedef struct
{
    vector_float4 ambientColor;
    vector_float4 diffuseColor;
    vector_float4 specularColor;

    // Directional lights only: light direction in eye coords
    vector_float3 lightDirectionEC;
    
    // Directional lights only: half angle vector
    vector_float3 halfAngleVecEC;
    
    // Positional lights only: light position in eye coords
    vector_float3 lightPositionEC;

    LightType     type;
} LightStruct;

typedef struct
{
    LightStruct light0;
    LightStruct light1;
} LightsStruct;

#endif /* ShaderTypesBridge_h */
