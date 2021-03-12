//
//  Image.metal
//  VideoClap
//
//  Created by lai001 on 2021/3/9.
//

#include <metal_stdlib>
#include "ImageVertex.h"

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float2 textureCoordinate;
} RasterizerData;

vertex
RasterizerData imageVertexShader(uint vertexID [[ vertex_id ]],
                                 constant ImageVertex *vertexArray [[ buffer(0) ]])
{
    RasterizerData out;
    out.position = float4(vertexArray[vertexID].position, 0.0, 1.0);
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment
float4 imageFragmentShader(RasterizerData input [[stage_in]],
                           texture2d<float> texture [[ texture(0) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float4 color = texture.sample(textureSampler, input.textureCoordinate);
    return color;
}
