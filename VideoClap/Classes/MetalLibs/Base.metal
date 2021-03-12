#include <metal_stdlib>
#include "Vertex.h"
#include "Uniforms.h"

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float4 color;
} RasterizerData;

vertex
RasterizerData basicVertex(const device Vertex* vertex_array [[ buffer(0) ]],
                           const device Uniforms& uniforms [[ buffer(1) ]],
                           unsigned int vid [[ vertex_id ]])
{
    RasterizerData data;
    
    data.position = uniforms.mvpMatrix * float4(vertex_array[vid].position, 1.0);
    data.color = vertex_array[vid].color;
    return data;
}

fragment
half4 basicFragment(RasterizerData interpolated [[stage_in]])
{
    return half4(interpolated.color);
}
