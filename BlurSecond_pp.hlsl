#include "Common.hlsli"


//--------------------------------------------------------------------------------------
// Textures (texture maps)
//--------------------------------------------------------------------------------------

// The scene has been rendered to a texture, these variables allow access to that texture
Texture2D SceneTexture : register(t0);
SamplerState PointSample : register(s0); // We don't usually want to filter (bilinear, trilinear etc.) the scene texture when
                                          // post-processing so this sampler will use "point sampling" - no filtering


//--------------------------------------------------------------------------------------
// Shader code
//--------------------------------------------------------------------------------------

// Post-processing shader that tints the scene texture to a given colour
float4 main(PostProcessingInput input) : SV_Target
{
    const int values = 46;
    
    float weights[values] = { 0.013393, 0.013389, 0.013376, 0.013355, 0.013326, 0.013289, 0.013243, 0.013189, 0.013128, 0.013058, 0.012981, 0.012896, 0.012804, 0.012704, 0.012597, 0.012484, 0.012363, 0.012236, 0.012103, 0.011964, 0.011819, 0.011669, 0.011513, 0.011352, 0.011187, 0.011017, 0.010843, 0.010665, 0.010483, 0.010298, 0.01011, 0.009919, 0.009725, 0.00953, 0.009332, 0.009133, 0.008933, 0.008731, 0.008529, 0.008326, 0.008123, 0.00792, 0.007718, 0.007515, 0.007314, 0.007113 };

    
    float3 samples = { 0, 0, 0 };
	
    // Sample a pixel from the scene texture and multiply it with the tint colour (comes from a constant buffer defined in Common.hlsli)
    float3 FinalColour = SceneTexture.Sample(PointSample, input.sceneUV) * weights[0];
    
    float width = 1 / gViewportWidth;
    float height = 1 / gViewportHeight;
    
    for (int i = 1; i < values; i++)
    {
        samples += SceneTexture.Sample(PointSample, input.sceneUV + float2(width * i, 0.0f)) * weights[i].x +
                   SceneTexture.Sample(PointSample, input.sceneUV - float2(width * i, 0.0f)) * weights[i].x;
    }
	
	// Got the RGB from the scene texture, set alpha to 1 for final output
    float softEdge = 0.10f; // Softness of the edge of the circle - range 0.001 (h
    float2 centreVector = input.areaUV - float2(0.5f, 0.5f);
    float centreLengthSq = dot(centreVector, centreVector);
    float alpha = 1.0f - saturate((centreLengthSq - 0.25f + softEdge) / softEdge);

    FinalColour += samples;
    
    return float4(FinalColour, alpha);
}