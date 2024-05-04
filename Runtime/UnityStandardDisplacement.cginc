#ifndef UNITY_STANDARD_DISPLACEMENT_INCLUDED
#define UNITY_STANDARD_DISPLACEMENT_INCLUDED

#include "UnityStandardCore.cginc"
#include "UnityStandardDisplacementCommon.cginc"

//Decide which Standard vertex shader to run.
#if STANDARD_FORWARD_BASE
#define VertexOutput VertexOutputForwardBase
#elif STANDARD_FORWARD_ADD
#define VertexOutput VertexOutputForwardAdd
#elif STANDARD_DEFERRED
#define VertexOutput VertexOutputDeferred
#elif STANDARD_META
#define VertexOutput v2f_meta
#endif

#define DOMAIN_INTERPOLATE(fieldName) data.fieldName = \
				patch[0].fieldName * barycentrCoords.x + \
				patch[1].fieldName * barycentrCoords.y + \
				patch[2].fieldName * barycentrCoords.z;

//Vertex Transform function
VertexOutput transformVertex(VertexInput v)
{
	//Displace the vertex in object space.
	float4 displacement = SampleDisplacement(v);
	v.vertex.xyz += v.normal * displacement;

	//Apply Unity Standard vertex shader for vertex attribute transforms.
#if STANDARD_FORWARD_BASE
	return vertForwardBase(v);
#elif STANDARD_FORWARD_ADD
	return vertForwardAdd(v);
#elif STANDARD_DEFERRED
	return vertDeferred(v);
#elif STANDARD_META
	return vert_meta(v);
#endif
}

//Domain shader.
[UNITY_domain("tri")]
VertexOutput domainTess(
	TesFact factors,
	OutputPatch<VertexInput, 3> patch,
	float3 barycentrCoords : SV_DomainLocation,
	uint pid : SV_PrimitiveID
) {
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[0]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[1]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[2]);

	VertexInput data;

	//Interpolate vertex data
	DOMAIN_INTERPOLATE(vertex);
	DOMAIN_INTERPOLATE(uv0);
	DOMAIN_INTERPOLATE(uv1);
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
	DOMAIN_INTERPOLATE(uv2);
#endif
	DOMAIN_INTERPOLATE(normal);
#ifdef _TANGENT_TO_WORLD
	DOMAIN_INTERPOLATE(tangent);
#endif

	UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(patch[0], data)

	//Transform the vertices
	return transformVertex(data);
}
#endif // UNITY_STANDARD_DISPLACEMENT_INCLUDED