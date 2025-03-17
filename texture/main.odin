package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:log"
import m "core:math"
import glm "core:math/linalg"
import sapp "shared:sokol/app"
import sg "shared:sokol/gfx"
import shelpers "shared:sokol/helpers"
import stbi "vendor:stb/image"

ctx: runtime.Context

State :: struct {
	shader:      sg.Shader,
	pip:         sg.Pipeline,
	bind:        sg.Bindings,
	pass_action: sg.Pass_Action,
}

state: ^State

VERT :: sg.Shader_Function {
	source = `
	#version 410
	layout(location=0) in vec2 a_pos;
	layout(location=1) in vec3 a_color;
	layout(location=2) in vec2 a_tex_coord;

	out vec3 color;
	out vec2 tex_coord;

	void main() {
		gl_Position = vec4(a_pos, 0.0, 1.0);
		color = a_color;
		tex_coord = a_tex_coord;
	}
	`,
}

FRAG :: sg.Shader_Function {
	source = `
	#version 410
	in vec3 color;
	in vec2 tex_coord;
	out vec4 frag_color;

	uniform sampler2D tex_smp;

	void main() {
		frag_color = texture(tex_smp, tex_coord);
	}
	`,
}

// BG: sg.Color = hex_to_vec4(0x181818ff)
BG: sg.Color = hex_to_vec4(0x334c4cff)

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32

VertexData :: struct {
	pos: Vec2,
	col: Vec3,
	uv:  Vec2,
}

main :: proc() {
	context.logger = log.create_console_logger()
	ctx = context
	sapp.run(
		{
			width = 800,
			height = 600,
			window_title = "Texture",
			icon = {sokol_default = true},
			allocator = sapp.Allocator(shelpers.allocator(&ctx)),
			logger = sapp.Logger(shelpers.logger(&ctx)),
			init_cb = init_cb,
			cleanup_cb = cleanup_cb,
			event_cb = event_cb,
			frame_cb = frame_cb,
		},
	)
}

init_cb :: proc "c" () {
	context = ctx
	sg.setup(
		{
			environment = shelpers.glue_environment(),
			allocator = sg.Allocator(shelpers.allocator(&ctx)),
			logger = sg.Logger(shelpers.logger(&ctx)),
		},
	)

	state = new(State)

	stbi.set_flip_vertically_on_load(1)

	vertices := []VertexData {
		{pos = {0.5, 0.5}, col = {1, 0, 0}, uv = {1, 1}},
		{pos = {0.5, -0.5}, col = {0, 1, 0}, uv = {1, 0}},
		{pos = {-0.5, -0.5}, col = {0, 0, 1}, uv = {0, 0}},
		{pos = {-0.5, 0.5}, col = {1, 1, 0}, uv = {0, 1}},
	}
	state.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

	ids := []u16{0, 1, 3, 1, 2, 3}
	state.bind.index_buffer = sg.make_buffer({type = .INDEXBUFFER, data = sg_range(ids)})

	shader_desc := sg.Shader_Desc {
		vertex_func   = VERT,
		fragment_func = FRAG,
	}

	shader_desc.images[0].stage = .FRAGMENT
	shader_desc.samplers[0].stage = .FRAGMENT
	shader_desc.image_sampler_pairs[0].stage = .FRAGMENT
	shader_desc.image_sampler_pairs[0].glsl_name = "tex_smp"

	state.shader = sg.make_shader(shader_desc)

	layout: sg.Vertex_Layout_State
	layout.attrs[0] = sg.Vertex_Attr_State {
		format = .FLOAT2,
	}
	layout.attrs[1] = sg.Vertex_Attr_State {
		format = .FLOAT3,
	}
	layout.attrs[2] = sg.Vertex_Attr_State {
		format = .FLOAT2,
	}

	state.pip = sg.make_pipeline({index_type = .UINT16, shader = state.shader, layout = layout})

	state.pass_action = sg.Pass_Action {
		colors = {0 = sg.Color_Attachment_Action{load_action = .CLEAR, clear_value = BG}},
	}

	w, h: i32
	pixels := stbi.load("stairs.png", &w, &h, nil, 4)
	defer stbi.image_free(pixels)

	state.bind.images[0] = sg.make_image(
		sg.Image_Desc {
			width = w,
			height = h,
			pixel_format = .RGBA8,
			data = {subimage = {0 = {0 = {ptr = pixels, size = uint(w * h * 4)}}}},
		},
	)
	state.bind.samplers[0] = sg.make_sampler({})
}

cleanup_cb :: proc "c" () {
	context = ctx
	sg.destroy_buffer(state.bind.vertex_buffers[0])
	sg.destroy_pipeline(state.pip)
	sg.destroy_shader(state.shader)
	free(state)
	sg.shutdown()
}

event_cb :: proc "c" (ev: ^sapp.Event) {
	context = ctx
	if ev.type == .KEY_DOWN {
		if ev.key_code == .ESCAPE {
			sapp.request_quit()
		}
	}
}

frame_cb :: proc "c" () {
	context = ctx
	sg.begin_pass({action = state.pass_action, swapchain = shelpers.glue_swapchain()})
	sg.apply_pipeline(state.pip)
	sg.apply_bindings(state.bind)
	sg.draw(0, 6, 1)
	sg.end_pass()
	sg.commit()
}

sg_range :: proc {
	sg_range_from_struct,
	sg_range_from_slice,
}

sg_range_from_struct :: proc(s: ^$T) -> sg.Range where intrinsics.type_is_struct(T) {
	return {ptr = s, size = size_of(T)}
}

sg_range_from_slice :: proc(s: []$T) -> sg.Range {
	return {ptr = raw_data(s), size = len(s) * size_of(s[0])}
}

hex_to_vec4 :: proc(hex: u32) -> sg.Color {
	return {
		f32((hex >> 24) & 0xff) / 255.0,
		f32((hex >> 16) & 0xff) / 255.0,
		f32((hex >> 8) & 0xff) / 255.0,
		f32(hex & 0xff) / 255.0,
	}
}
