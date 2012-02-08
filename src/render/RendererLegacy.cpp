#include "RendererLegacy.h"
#include "Light.h"
#include "Material.h"
#include "Render.h"
#include "StaticMesh.h"
#include "Surface.h"
#include "Texture.h"
#include "VertexArray.h"
#include <stddef.h> //for offsetof

struct GLRenderInfo : public RenderInfo {
	GLRenderInfo() {
		glGenBuffers(1, &vbo);
	}
	virtual ~GLRenderInfo() {
		glDeleteBuffers(1, &vbo);
	}
	GLuint vbo;
};

RendererLegacy::RendererLegacy(int w, int h) :
	Renderer(w, h)
{
	glShadeModel(GL_SMOOTH);
	glCullFace(GL_BACK);
	glFrontFace(GL_CCW);
	glEnable(GL_CULL_FACE);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);

	glClearColor(0,0,0,0);

	glViewport(0, 0, m_width, m_height);
}

RendererLegacy::~RendererLegacy()
{

}

bool RendererLegacy::BeginFrame()
{
	Render::PrepareFrame();
	glClearColor(0,0,0,0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	return true;
}

bool RendererLegacy::EndFrame()
{
	Render::PostProcess();
	return true;
}

bool RendererLegacy::SwapBuffers()
{
	glError();
	Render::SwapBuffers();
	return true;
}

bool RendererLegacy::SetTransform(const matrix4x4d &m)
{
	//XXX this is not the intended final state, but now it's easier to do this
	//and rely on push/pop in objects' render functions
	//GL2+ or ES2 renderers can forego the classic matrix stuff entirely and use uniforms
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixd(&m[0]);
	return true;
}

bool RendererLegacy::SetTransform(const matrix4x4f &m)
{
	//same as above
	glMatrixMode(GL_MODELVIEW);
	glLoadMatrixf(&m[0]);
	return true;
}

bool RendererLegacy::SetPerspectiveProjection(float fov, float aspect, float near, float far)
{
	double ymax = near * tan(fov * M_PI / 360.0);
	double ymin = -ymax;
	double xmin = ymin * aspect;
	double xmax = ymax * aspect;

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(xmin, xmax, ymin, ymax, near, far);
	return true;
}

bool RendererLegacy::SetOrthographicProjection(float xmin, float xmax, float ymin, float ymax, float zmin, float zmax)
{
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(xmin, xmax, ymin, ymax, zmin, zmax);
	return true;
}

bool RendererLegacy::SetBlendMode(BlendMode m)
{
	//where does SRC_ALPHA, ONE fit in?
	switch (m) {
	case BLEND_SOLID:
		glDisable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ZERO);
		break;
	case BLEND_ADDITIVE:
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE);
		break;
	case BLEND_ALPHA:
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		break;
	case BLEND_ALPHA_ONE:
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE);
		break;
	case BLEND_ALPHA_PREMULT:
		glEnable(GL_BLEND);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		break;
	default:
		return false;
	}
	return true;
}

bool RendererLegacy::SetLights(int numlights, const Light *lights)
{
	if (numlights < 1) return false;

	m_numLights = numlights;

	for (int i=0; i < numlights; i++) {
		const Light &l = lights[i];
		// directional lights have the length of 1
		const float pos[] = {
			l.GetPosition().x,
			l.GetPosition().y,
			l.GetPosition().z,
			l.GetType() == Light::LIGHT_DIRECTIONAL ? 1.f : 0.f
		};
		glLightfv(GL_LIGHT0+i, GL_POSITION, pos);
		glLightfv(GL_LIGHT0+i, GL_DIFFUSE, l.GetDiffuse());
		glLightfv(GL_LIGHT0+i, GL_AMBIENT, l.GetAmbient());
		glLightfv(GL_LIGHT0+i, GL_SPECULAR, l.GetSpecular());
		glEnable(GL_LIGHT0+i);
	}

	return true;
}

bool RendererLegacy::SetAmbientColor(const Color &c)
{
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, c);

	return true;
}

bool RendererLegacy::DrawLines(int count, const LineVertex *v, LineType type)
{
	if (count < 2) return false;

	glPushAttrib(GL_LIGHTING_BIT);
	glDisable(GL_LIGHTING);

	//this is easy to upgrade to GL3/ES2 level
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(3, GL_FLOAT, sizeof(LineVertex), &v[0].position);
	glColorPointer(4, GL_FLOAT, sizeof(LineVertex), &v[0].color);
	glDrawArrays(type, 0, count);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawLines(int count, const vector3f *v, const Color &c, LineType t)
{
	if (count < 2 || !v) return false;

	glPushAttrib(GL_LIGHTING_BIT);
	glDisable(GL_LIGHTING);

	glColor4f(c.r, c.g, c.b, c.a);
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3, GL_FLOAT, sizeof(vector3f), v);
	glDrawArrays(t, 0, count);
	glDisableClientState(GL_VERTEX_ARRAY);
	glColor4f(1.f, 1.f, 1.f, 1.f);

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawLines2D(int count, const vector2f *v, const Color &c, LineType t)
{
	if (count < 2 || !v) return false;

	glPushAttrib(GL_LIGHTING_BIT);
	glDisable(GL_LIGHTING);

	glColor4f(c.r, c.g, c.b, c.a);
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(2, GL_FLOAT, sizeof(vector2f), v);
	glDrawArrays(t, 0, count);
	glDisableClientState(GL_VERTEX_ARRAY);
	glColor4f(1.f, 1.f, 1.f, 1.f);

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawPoints(int count, const vector3f *points, const Color *colors, float size)
{
	if (count < 1 || !points || !colors) return false;

	glPushAttrib(GL_LIGHTING_BIT);
	glDisable(GL_LIGHTING);

	glPointSize(size);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, points);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_POINTS, 0, count);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glPointSize(1.f); // XXX wont't be necessary

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawPoints2D(int count, const vector2f *points, const Color *colors, float size)
{
	if (count < 1 || !points || !colors) return false;

	glDisable(GL_LIGHTING);

	glPointSize(size);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, points);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_POINTS, 0, count);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	glPointSize(1.f); // XXX wont't be necessary

	return true;
}

bool RendererLegacy::DrawTriangles2D(const VertexArray *v, const Material *m, PrimitiveType t)
{
	if (!v || v->GetNumVerts() < 3) return false;

	// XXX assuming GUI+unlit
	glPushAttrib(GL_ENABLE_BIT);
	glDisable(GL_LIGHTING);

	const bool diffuse = !v->diffuse.empty();
	const bool textured = (m && m->texture0 && v->uv0.size() == v->position.size());
	const unsigned int numverts = v->position.size();

	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->position[0]));
	if (diffuse) {
		assert(v->diffuse.size() == v->position.size());
		glEnableClientState(GL_COLOR_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->diffuse[0]));
	}
	if (textured) {
		assert(v->uv0.size() == v->position.size());
		glEnable(GL_TEXTURE_2D);
		m->texture0->Bind();
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(2, GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->uv0[0]));
	}

	glDrawArrays(t, 0, numverts);
	glDisableClientState(GL_VERTEX_ARRAY);

	if (diffuse)
		glDisableClientState(GL_COLOR_ARRAY);
	if (textured) {
		m->texture0->Unbind();
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	}

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawTriangles(const VertexArray *v, const Material *m, PrimitiveType t)
{
	if (!v || v->position.size() < 3) return false;

	bool diffuse = !v->diffuse.empty();

	const bool textured = (m && m->texture0 && v->uv0.size() == v->position.size());
	const bool normals = !v->normal.empty();
	const unsigned int numverts = v->position.size();

	glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT);

	if (m) {
		if (m->unlit) {
			glDisable(GL_LIGHTING);
			if (!diffuse) {
				//overall color supplied by material
				glColor4f(m->diffuse.r, m->diffuse.g, m->diffuse.b, m->diffuse.a);
			}
		} else {
			glEnable(GL_LIGHTING);
			glMaterialfv (GL_FRONT, GL_DIFFUSE, &m->diffuse[0]);
		}
		if (m->twoSided) {
			glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
			glDisable(GL_CULL_FACE);
		}
	} else {
		//unlit, colours per vertex
		glDisable(GL_LIGHTING);
		assert(v->diffuse.size() > 0); //not a fatal mistake, but there should be some colour
	}

	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->position[0]));
	if (diffuse) {
		assert(v->diffuse.size() == v->position.size());
		glEnableClientState(GL_COLOR_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->diffuse[0]));
	}
	if (normals) {
		assert(v->normal.size() == v->position.size());
		glEnableClientState(GL_NORMAL_ARRAY);
		glNormalPointer(GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->normal[0]));
	}
	if (textured) {
		assert(v->uv0.size() == v->position.size());
		glEnable(GL_TEXTURE_2D);
		m->texture0->Bind();
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(2, GL_FLOAT, 0, reinterpret_cast<const GLvoid *>(&v->uv0[0]));
	}
	glDrawArrays(t, 0, numverts);
	glDisableClientState(GL_VERTEX_ARRAY);
	if (diffuse)
		glDisableClientState(GL_COLOR_ARRAY);
	if (normals)
		glDisableClientState(GL_NORMAL_ARRAY);
	if (textured) {
		m->texture0->Unbind();
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisable(GL_TEXTURE_2D);
	}

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawSurface2D(const Surface *s)
{
	if (!s || !s->GetVertices() || s->indices.size() < 3) return false;

	Material *m = s->GetMaterial().Get();
	VertexArray *v = s->GetVertices();
	const bool diffuse = !v->diffuse.empty();
	const bool textured = (m && m->texture0 && v->uv0.size() == v->position.size());
	// no need for normals

	glPushAttrib(GL_LIGHTING_BIT);

	if (!m || m->unlit) glDisable(GL_LIGHTING);

	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(3, GL_FLOAT, 0, &v->position[0]);
	if (diffuse) {
		assert(v->diffuse.size() == v->position.size());
		glEnableClientState(GL_COLOR_ARRAY);
		glColorPointer(4, GL_FLOAT, 0, &v->diffuse[0]);
	}
	if (textured) {
		assert(v->uv0.size() == v->position.size());
		glEnable(GL_TEXTURE_2D);
		m->texture0->Bind();
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glTexCoordPointer(2, GL_FLOAT, 0, &v->uv0[0]);
	}

	glDrawElements(s->m_primitiveType, s->indices.size(), GL_UNSIGNED_SHORT, &s->indices[0]);

	glDisableClientState(GL_VERTEX_ARRAY);
	if (diffuse)
		glDisableClientState(GL_COLOR_ARRAY);
	if (textured) {
		m->texture0->Unbind();
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisable(GL_TEXTURE_2D);
	}

	glPopAttrib();

	return true;
}

bool RendererLegacy::DrawPointSprites(int count, const vector3f *positions, const Material *material, float size)
{
	if (count < 1 || !material) return false;

	SetBlendMode(BLEND_ALPHA_ONE);

	glPushAttrib(GL_ENABLE_BIT);
	glEnable(GL_TEXTURE_2D);
	material->texture0->Bind();
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glColor4fv(&material->diffuse[0]);

	glDisable(GL_LIGHTING);
	glDepthMask(GL_FALSE);

	/*if (AreShadersEnabled()) {
		// this is a bit dumb since it doesn't care how many lights
		// the scene has, and this is a constant...
		State::UseProgram(billboardShader);
		billboardShader->set_some_texture(0);
	}*/

	// quad billboards
	matrix4x4f rot;
	glGetFloatv(GL_MODELVIEW_MATRIX, &rot[0]);
	rot.ClearToRotOnly();
	rot = rot.InverseOf();

	const float sz = 0.5f*size;
	const vector3f rotv1 = rot * vector3f(sz, sz, 0.0f);
	const vector3f rotv2 = rot * vector3f(sz, -sz, 0.0f);
	const vector3f rotv3 = rot * vector3f(-sz, -sz, 0.0f);
	const vector3f rotv4 = rot * vector3f(-sz, sz, 0.0f);

	glBegin(GL_QUADS);
	for (int i=0; i<count; i++) {
		const vector3f &pos = positions[i];
		vector3f vert;

		vert = pos+rotv4;
		glTexCoord2f(0.0f,0.0f);
		glVertex3f(vert.x, vert.y, vert.z);

		vert = pos+rotv3;
		glTexCoord2f(0.0f,1.0f);
		glVertex3f(vert.x, vert.y, vert.z);

		vert = pos+rotv2;
		glTexCoord2f(1.0f,1.0f);
		glVertex3f(vert.x, vert.y, vert.z);

		vert = pos+rotv1;
		glTexCoord2f(1.0f,0.0f);
		glVertex3f(vert.x, vert.y, vert.z);
	}
	glEnd();

	material->texture0->Unbind();
	glPopAttrib();

	SetBlendMode(BLEND_SOLID);

	return true;
}

//position, color.
struct UnlitVertex {
	vector3f position;
	Color color;
};

bool RendererLegacy::DrawStaticMesh(StaticMesh *t)
{
	if (!t) return false;

	// XXX the only static mesh is the background, so cutting some corners
	glPushAttrib(GL_LIGHTING_BIT);
	glDisable(GL_LIGHTING);

	GLRenderInfo *info = 0;
	// prepare it
	if (!t->cached) {
		if (t->m_renderInfo == 0)
			t->m_renderInfo = new GLRenderInfo();
		info = static_cast<GLRenderInfo*>(t->m_renderInfo);

		const int numvertices = t->GetNumVerts();
		assert(numvertices > 0);

		UnlitVertex *vts = new UnlitVertex[numvertices];
		int next = 0;
		for (int i=0; i < t->numSurfaces; i++) {
			for(int j=0; j<t->surfaces[i].GetNumVerts(); j++) {
				vts[next].position = t->surfaces[i].GetVertices()->position[j];
				vts[next].color = t->surfaces[i].GetVertices()->diffuse[j];
				next++;
			}
		}

		//buffer
		glBindBuffer(GL_ARRAY_BUFFER, info->vbo);
		glBufferData(GL_ARRAY_BUFFER, sizeof(UnlitVertex)*numvertices, vts, GL_STATIC_DRAW);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		t->cached = true;
		delete[] vts;
	}
	assert(t->cached == true);
	info = static_cast<GLRenderInfo*>(t->m_renderInfo);

	//draw it
	glBindBuffer(GL_ARRAY_BUFFER, info->vbo);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glVertexPointer(3, GL_FLOAT, sizeof(UnlitVertex), reinterpret_cast<const GLvoid *>(offsetof(UnlitVertex, position)));
	glColorPointer(4, GL_FLOAT, sizeof(UnlitVertex), reinterpret_cast<const GLvoid *>(offsetof(UnlitVertex, color)));
	int start = 0;
	// XXX save start & numverts somewhere
	// XXX this is not indexed
	for (int i=0; i < t->numSurfaces; i++) {
		glDrawArrays(t->surfaces[i].m_primitiveType, start, t->surfaces[i].GetNumVerts());
		start += t->surfaces[i].GetNumVerts();
	}
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	glPopAttrib();

	return true;
}
