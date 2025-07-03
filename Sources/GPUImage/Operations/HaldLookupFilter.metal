//
//  File.metal
//  GPUImage
//
//  Created by Muhammad Haroon on 03/07/2025.
//
#include <metal_stdlib>
#include "OperationShaderTypes.h"
using namespace metal;

typedef struct {
    float intensity;
} IntensityUniform;

float2 computeSliceOffset(float slice, float slicesPerRow, float2 sliceSize) {
    return sliceSize * float2(fmod(slice, slicesPerRow), floor(slice / slicesPerRow));
}

half4 sampleAs3DTexture(half3 textureColor, float size, float numRows, float slicesPerRow,
                        texture2d<half> lutTexture, sampler lutSampler) {
    float slice = float(textureColor.z) * 63.0;  // 64 slices (0-63)
    float zOffset = fract(slice);
    
    float2 sliceSize = float2(1.0 / slicesPerRow, 1.0 / numRows);
    float2 slice0Offset = computeSliceOffset(floor(slice), slicesPerRow, sliceSize);
    float2 slice1Offset = computeSliceOffset(ceil(slice), slicesPerRow, sliceSize);
    
    float2 slicePixelSize = sliceSize / size;
    float2 sliceInnerSize = slicePixelSize * (size - 1.0);
    
    // Convert to float2 for texture sampling
    float2 uv = slicePixelSize * 0.5 + float2(textureColor.xy) * sliceInnerSize;
    
    half4 slice0Color = lutTexture.sample(lutSampler, slice0Offset + uv);
    half4 slice1Color = lutTexture.sample(lutSampler, slice1Offset + uv);
    return mix(slice0Color, slice1Color, half(zOffset));
}

fragment half4 haldFragment(TwoInputVertexIO fragmentInput [[stage_in]],
                              texture2d<half> inputTexture [[texture(0)]],
                              texture2d<half> inputTexture2 [[texture(1)]],
                              constant IntensityUniform& uniform [[buffer(1)]])
{
    constexpr sampler quadSampler;
    half4 base = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    // Clamp and process color using 3D LUT
    half3 clampedColor = clamp(base.rgb, 0.0h, 1.0h);
    half4 newColor = sampleAs3DTexture(clampedColor, 64.0, 8.0, 8.0, inputTexture2, quadSampler);
    
    // Mix with original based on intensity
    return mix(base, half4(newColor.rgb, base.a), half(uniform.intensity));
}
