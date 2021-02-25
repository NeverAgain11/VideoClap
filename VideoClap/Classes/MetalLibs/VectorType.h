//
//  VectorType.h
//  VideoClap
//
//  Created by lai001 on 2021/2/25.
//

#ifndef VectorType_h
#define VectorType_h

#include <simd/simd.h>

#ifdef METAL_FILE

#define float4x4 metal::float4x4
#define float3 metal::float3
#define float4 metal::float4

#else

#define float4x4 simd_float4x4
#define float3 simd_float3
#define float4 simd_float4

#endif

#endif /* VectorType_h */
