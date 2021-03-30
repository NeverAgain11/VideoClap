#include <metal_stdlib>
#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h

using namespace metal;

extern "C" float4 Squareswire(coreimage::sampler inputImage, coreimage::sampler inputTargetImage, float progress, float2 squares, float2 direction, float smoothness) {
    float2 p = inputImage.coord();
    float2 center = float2(0.5);
    
    float2 v = normalize(direction);
    v /= abs(v.x)+abs(v.y);
    float d = v.x * center.x + v.y * center.y;
    float offset = smoothness;
    float pr = smoothstep(-offset, 0.0, v.x * p.x + v.y * p.y - (d-0.5+progress*(1.+offset)));
    float2 squarep = fract(p*squares);
    float2 squaremin = float2(pr/2.0);
    float2 squaremax = float2(1.0 - pr/2.0);
    float a = (1.0 - step(progress, 0.0)) * step(squaremin.x, squarep.x) * step(squaremin.y, squarep.y) * step(squarep.x, squaremax.x) * step(squarep.y, squaremax.y);
    return mix(inputImage.sample(p), inputTargetImage.sample(p), a);
}
