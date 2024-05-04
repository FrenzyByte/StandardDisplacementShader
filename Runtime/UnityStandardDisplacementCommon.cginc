#ifndef UNITY_STANDARD_DISPLACEMENT_COMMON_INCLUDED
#define UNITY_STANDARD_DISPLACEMENT_COMMON_INCLUDED

// Displacement functions and variables shared between passes.

float _TessellationFactor; // The maximum of tessellation to be applied.
float2 _TessellationDistance; // The start/stop distance in world space when the tessellaton should be and the maximum/minimum factor.
float _DisplacementScale; //The strength of the displacement that should be applied to the vertices.
sampler2D _DisplacementMap; // The texture to sample the displacement from.

struct Vertex2Hull {
	VertexInput v;
	float4 worldPos : TEXCOORD8;
};

float SampleDisplacement(VertexInput v)
{
	//Sample displacement texture. Place it in -1 to 1 range. Dark colors lower vertices, Light colors raise vertices.
	float displacement = tex2Dlod(_DisplacementMap, float4(TRANSFORM_TEX(v.uv0, _MainTex), 0, 0)).r * 2 - 1;
	return displacement * _DisplacementScale;
}

struct TesFact
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

//Vertex shader. Since we use the Standard shader's vertex shader in the domain shader we only calculate world space position here for the tessellaton factor.
Vertex2Hull vertexTess(VertexInput v)
{
	Vertex2Hull o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_OUTPUT(Vertex2Hull, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(t);
	o.v = v;

	//Calculate world space, this is needed for tessellation factor
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	return o;
}

//Helper function to calculate amount of tessellation.
float CalcDistanceTessFactor(float4 worldPos, float minDist, float maxDist, float tess)
{
	//Get the distance of the vertex in world space.
	float dist = distance(worldPos, _WorldSpaceCameraPos);

	//Inverse lerp the distance from world space distance from camera, to 0 to 1. Multiply by tessellation factor of the material properties.
	float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
	return f;
}

//Average out the tessellation factor for each edge.
float4 CalcTriEdgeTessFactors(float3 triVertexFactors)
{
	float4 tess;
	tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
	tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
	tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
	tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
	return tess;
}

//Calculate tessellation factor for each vertex independently.
float4 DistanceBasedTess(float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tess)
{
	float3 f;
	f.x = CalcDistanceTessFactor(v0, minDist, maxDist, tess);
	f.y = CalcDistanceTessFactor(v1, minDist, maxDist, tess);
	f.z = CalcDistanceTessFactor(v2, minDist, maxDist, tess);

	return CalcTriEdgeTessFactors(f);
}

//Tessellation function to pass tessellation factor to the hull shader.
TesFact PatchConstFunc(InputPatch<Vertex2Hull, 3> patch)
{
	TesFact f;

	float4 tessEdges = DistanceBasedTess(patch[0].worldPos, patch[1].worldPos, patch[2].worldPos, _TessellationDistance.x, _TessellationDistance.y, _TessellationFactor);

	f.edge[0] = tessEdges.x;
	f.edge[1] = tessEdges.y;
	f.edge[2] = tessEdges.z;
	f.inside = tessEdges.w;
	return f;
}


//Hull shader
[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("PatchConstFunc")]
VertexInput hullTess(InputPatch<Vertex2Hull, 3> patch,
	uint id : SV_OutputControlPointID)
{
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[id]);
	VertexInput o = patch[id].v;
	return o;
}

#endif // UNITY_STANDARD_DISPLACEMENT_COMMON_INCLUDED