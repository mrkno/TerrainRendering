#version 400

layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

uniform vec4 lightPos;
uniform mat4 mvpMatrix;
uniform vec4 cameraPos;
uniform float heightMapHeightScale;

out float diffuseTerm;
out vec2 texCoords;
out vec4 texWeights;

void main() {
	vec3 p1 = gl_in[0].gl_Position.xyz;
	vec3 p2 = gl_in[1].gl_Position.xyz;
	vec3 p3 = gl_in[2].gl_Position.xyz;

	vec3 norMatrix = normalize(cross(p2 - p1, p3 - p1));
	float div = (heightMapHeightScale * 2.0f) / 4.0f;
	float div3 = div / 3.0f;
	float divm2 = div * 2.0f;
	float divm3 = div * 3.0f;

	float minx = min(min(p1.x, p2.x), p3.x);
	float scalex = max(max(p1.x, p2.x), p3.x) - minx;
	float minz = min(min(p1.z, p2.z), p3.z);
	float scalez = max(max(p1.z, p2.z), p3.z) - minz;

	for (int i = 0; i < gl_in.length(); i++) {
		vec4 posn = gl_in[i].gl_Position;

		// calculate diffuse lighting
		vec3 lightVec = normalize(lightPos.xyz - posn.xyz);
		diffuseTerm = max(dot(lightVec, norMatrix), 0.0f);

		// scale texture with distance
		float dist = max(100 - abs(distance(posn, cameraPos)), 1);
		float texScale = 1 - (dist / 100);
		texCoords = vec2(((posn.x - minx) / scalex) * texScale, ((posn.z - minz) / scalez) * texScale);

		// calculate texture weights
		if (posn.y < div) {
			texWeights = vec4(1.0, 0.0, 0.0, 0.0);
		}
		else if (posn.y < divm2) {
			texWeights = vec4(0.0, 1.0, 0.0, 0.0);
		}
		else if (posn.y < (divm2 + div3)) {
			float change = max(posn.y - divm2, 0.0f) / div3;
			texWeights = vec4(0.0, 1.0 - change, change, 0.0);
		}
		else if (posn.y < divm3) {
			texWeights = vec4(0.0, 0.0, 1.0, 0.0);
		}
		else if (posn.y < (divm3 + div3)) {
			float change = max(posn.y - divm3, 0.0f) / div3;
			texWeights = vec4(0.0, 0.0, 1.0 - change, change);
		}
		else {
			texWeights = vec4(0.0, 0.0, 0.0, 1.0);
		}

		gl_Position = mvpMatrix * posn;
		EmitVertex();
	}
}