//--------------------------------------------------------------------------------------
// Colour Tint Post-Processing Pixel Shader
//--------------------------------------------------------------------------------------
// Just samples a pixel from the scene texture and multiplies it by a fixed colour to tint the scene

#include "Common.hlsli"


//--------------------------------------------------------------------------------------
// Textures (texture maps)
//--------------------------------------------------------------------------------------

// The scene has been rendered to a texture, these variables allow access to that texture
Texture2D    SceneTexture : register(t0);
SamplerState PointSample  : register(s0); // We don't usually want to filter (bilinear, trilinear etc.) the scene texture when
                                          // post-processing so this sampler will use "point sampling" - no filtering

//--------------------------------------------------------------------------------------
// Shader code
//--------------------------------------------------------------------------------------

float Epsilon = 1e-10;
 
float3 RGBtoHCV(in float3 RGB)
{
    float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0 / 3.0) : float4(RGB.gb, 0.0, -1.0 / 3.0);
    float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
    return float3(H, C, Q.x);
}

float3 RGBtoHSL(in float3 RGB)
{
    float3 HCV = RGBtoHCV(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1 - abs(L * 2 - 1) + Epsilon);
    return float3(HCV.x, S, L);
}

float3 HUEtoRGB(in float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R, G, B));
}

float3 HSLtoRGB(in float3 HSL)
{
    float3 RGB = HUEtoRGB(HSL.x);
    float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
    return (RGB - 0.5) * C + HSL.z;
}


// Post-processing shader that tints the scene texture to a given colour
float4 main(PostProcessingInput input) : SV_Target
{
    float3 colour1 = { 0, 1, 0 };
    float3 colour2 = {0,0, 1};
	
    float3 colour1HSL = RGBtoHSL(colour1);
    float3 colour2HSL = RGBtoHSL(colour2);
    
    float SinX = sin(gHeatHazeTimer * 0.5f);
    float SinX2 = sin(gHeatHazeTimer * 0.5f);
    
    colour1HSL.x += (0.314f * SinX);
    colour2HSL.x += (0.314f * SinX2);
    
    if (colour1HSL.x >= 1) colour1HSL.x = 0;
    
    if (colour2HSL.x >= 1) colour2HSL.x = 0;
    
    float3 coloutOutput1 = HSLtoRGB(colour1HSL);
    float3 coloutOutput2 = HSLtoRGB(colour2HSL);
    
    float3 outputColour;
    
    outputColour.r = lerp(coloutOutput1.r, coloutOutput2.r, input.areaUV.y);
    outputColour.g = lerp(coloutOutput1.g, coloutOutput2.g, input.areaUV.y);
    outputColour.b = lerp(coloutOutput1.b, coloutOutput2.b, input.areaUV.y);
    
    // Sample a pixel from the scene texture and multiply it with the tint colour (comes from a constant buffer defined in Common.hlsli)
    float3 colour = SceneTexture.Sample(PointSample, input.sceneUV).rgb * outputColour;
	
    
    
	// Got the RGB from the scene texture, set alpha to 1 for final output
    float softEdge = 0.10f; // Softness of the edge of the circle - range 0.001 (h
    float2 centreVector = input.areaUV - float2(0.5f, 0.5f);
    float centreLengthSq = dot(centreVector, centreVector);
    float alpha = 1.0f - saturate((centreLengthSq - 0.25f + softEdge) / softEdge);
    
	return float4(colour, alpha);
}