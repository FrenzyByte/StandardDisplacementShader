#ifndef UNITY_STANDARD_DISPLACEMENT_SHADOW_INCLUDED
#define UNITY_STANDARD_DISPLACEMENT_SHADOW_INCLUDED

//Impleentation of shadow pass Standard Displacement shader

//Check which vertShadowCaster function from the unity cglibrary to use. Between Unity 2021.3.30 and 2021.3.37 the vertShadowCaster input parameter changed.
//Unity does not allow patch versions in the UNITY_VERSION macro so picking the correct function cannot be done automatically for these versions.
//If you are running a version Unity 2023.3 that shows compile errors compiling this shader, change SHADOW_VERTEX_OUTPUT to 0
#if UNITY_VERSION >= 202130
#define SHADOW_VERTEX_OUTPUT 1
#endif

#include "UnityStandardShadow.cginc"
#include "UnityStandardDisplacementCommon.cginc"

#define DOMAIN_INTERPOLATE(fieldName) data.fieldName = \
				patch[0].fieldName * barycentrCoords.x + \
				patch[1].fieldName * barycentrCoords.y + \
				patch[2].fieldName * barycentrCoords.z;

//Shadow Vertex Transform function
void transformVertexShadow(VertexInput v
#if SHADOW_VERTEX_OUTPUT
	, out VertexOutput output
#else
	, out float4 opos : SV_POSITION
#endif
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
	, out VertexOutputShadowCaster o
#endif
#ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
	, out VertexOutputStereoShadowCaster os
#endif
)
{
	//Displace the vertex in object space.
	float4 displacement = SampleDisplacement(v);
	v.vertex.xyz += v.normal * displacement;

	//Apply Unity Standard vertex shader for vertex attribute transforms.
#if SHADOW_VERTEX_OUTPUT
	output = vertShadowCaster(v
#else
	vertShadowCaster(v, opos
#endif
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
		, o
#endif
#ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
		, os
#endif
	);
}

//Domain shader.
[UNITY_domain("tri")]
void domainTess(
	TesFact factors,
	OutputPatch<VertexInput, 3> patch,
	float3 barycentrCoords : SV_DomainLocation,
	uint pid : SV_PrimitiveID
#if SHADOW_VERTEX_OUTPUT
	, out  VertexOutput output
#else
	, out float4 opos : SV_POSITION
#endif
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
	, out VertexOutputShadowCaster o
#endif
#ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
	, out VertexOutputStereoShadowCaster os
#endif
) {
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[0]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[1]);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(patch[2]);

	VertexInput data;

	//Interpolate vertex data
	DOMAIN_INTERPOLATE(vertex);
	DOMAIN_INTERPOLATE(uv0);
	DOMAIN_INTERPOLATE(normal);
#ifdef _TANGENT_TO_WORLD
	DOMAIN_INTERPOLATE(tangent);
#endif

	UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(patch[0], data)

#if SHADOW_VERTEX_OUTPUT
	transformVertexShadow(data, output
#else
	transformVertexShadow(data, opos
#endif
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
		, o
#endif
#ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
		, os
#endif
	);
}
#endif // UNITY_STANDARD_DISPLACEMENT_SHADOW_INCLUDED