package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:log"
import m "core:math"
import glm "core:math/linalg/glsl"
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
	layout(location=1) in vec2 a_tex_coord;

	out vec2 tex_coord;
	uniform mat4 transform;

	void main() {
		gl_Position = transform * vec4(a_pos, 0.0, 1.0);
		tex_coord = a_tex_coord;
	}
	`,
}

FRAG :: sg.Shader_Function {
	source = `
	#version 410
	in vec2 tex_coord;
	out vec4 frag_color;

	uniform sampler2D tex1;
	uniform sampler2D tex2;

	void main() {
		frag_color = mix(texture(tex1, tex_coord), texture(tex2, tex_coord), 0.2);
	}
	`,
}

// BG: sg.Color = hex_to_vec4(0x181818ff)
BG: sg.Color = hex_to_vec4(0x334c4cff)

VertexData :: struct {
	pos: glm.vec2,
	uv:  glm.vec2,
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
		{pos = {0.5, 0.5}, uv = {1, 1}},
		{pos = {0.5, -0.5}, uv = {1, 0}},
		{pos = {-0.5, -0.5}, uv = {0, 0}},
		{pos = {-0.5, 0.5}, uv = {0, 1}},
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
	shader_desc.image_sampler_pairs[0].glsl_name = "tex1"
	shader_desc.image_sampler_pairs[0].image_slot = 0
	shader_desc.image_sampler_pairs[0].sampler_slot = 0

	shader_desc.images[1].stage = .FRAGMENT
	shader_desc.samplers[1].stage = .FRAGMENT
	shader_desc.image_sampler_pairs[1].stage = .FRAGMENT
	shader_desc.image_sampler_pairs[1].glsl_name = "tex2"
	shader_desc.image_sampler_pairs[1].image_slot = 1
	shader_desc.image_sampler_pairs[1].sampler_slot = 1

    // desc.uniform_blocks[0].stage = .VERTEX
    // desc.uniform_blocks[0].layout = .STD140
    // desc.uniform_blocks[0].size = 64
    // desc.uniform_blocks[0].glsl_uniforms[0].type = .FLOAT4
    // desc.uniform_blocks[0].glsl_uniforms[0].array_count = 4
    // desc.uniform_blocks[0].glsl_uniforms[0].glsl_name = "vs_params"
    shader_desc.uniform_blocks[0].stage = .VERTEX
    shader_desc.uniform_blocks[0].layout = .STD140
    shader_desc.uniform_blocks[0].size = 64
    shader_desc.uniform_blocks[0].glsl_uniforms[0].type = .MAT4
    shader_desc.uniform_blocks[0].glsl_uniforms[0].glsl_name = "transform"

	state.shader = sg.make_shader(shader_desc)

	layout: sg.Vertex_Layout_State
	layout.attrs[0] = sg.Vertex_Attr_State {
		format = .FLOAT2,
	}
	layout.attrs[1] = sg.Vertex_Attr_State {
		format = .FLOAT2,
	}

	state.pip = sg.make_pipeline({index_type = .UINT16, shader = state.shader, layout = layout})

	state.pass_action = sg.Pass_Action {
		colors = {0 = sg.Color_Attachment_Action{load_action = .CLEAR, clear_value = BG}},
	}

	state.bind.images[0] = load_image("stairs.png")
	state.bind.samplers[0] = sg.make_sampler({})

	state.bind.images[1] = load_image("tile.png")
	state.bind.samplers[1] = sg.make_sampler({})
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

	trans: glm.mat4 = 1
	rotate := glm.mat4Rotate(glm.vec3{0, 0, 1}, glm.radians_f32(90))
	scale := glm.mat4Scale(glm.vec3{0.5, 0.5, 0.5})
	trans = rotate * scale

	// proj := glm.mat4Perspective(45, sapp.widthf() / sapp.heightf(), 0.0001, 1000)
	// rotate := glm.mat4Rotate(glm.vec3{0, 0, 1}, glm.radians_f32(90))
	// proj = proj * rotate

	sg.begin_pass({action = state.pass_action, swapchain = shelpers.glue_swapchain()})
	sg.apply_pipeline(state.pip)
	sg.apply_bindings(state.bind)
	sg.apply_uniforms(0, sg_range(&trans))
	sg.draw(0, 6, 1)
	sg.end_pass()
	sg.commit()
}

load_image :: proc(filename: cstring) -> (image: sg.Image) {
	w, h: i32

	pixels := stbi.load(filename, &w, &h, nil, 4)
	defer stbi.image_free(pixels)
	image = sg.make_image(
		sg.Image_Desc {
			width = w,
			height = h,
			pixel_format = .RGBA8,
			data = {subimage = {0 = {0 = {ptr = pixels, size = uint(w * h * 4)}}}},
		},
	)
	return
}

sg_range :: proc {
	sg_range_from_struct,
	sg_range_from_slice,
	sg_range_from_matrix
}

sg_range_from_struct :: proc(s: ^$T) -> sg.Range where intrinsics.type_is_struct(T) {
	return {ptr = s, size = size_of(T)}
}

sg_range_from_slice :: proc(s: []$T) -> sg.Range {
	return {ptr = raw_data(s), size = len(s) * size_of(s[0])}
}

sg_range_from_matrix :: proc(s: ^$T) -> sg.Range where intrinsics.type_is_matrix(T) {
	return {ptr = s, size = size_of(T)}
}

hex_to_vec4 :: proc(hex: u32) -> sg.Color {
	return {
		f32((hex >> 24) & 0xff) / 255.0,
		f32((hex >> 16) & 0xff) / 255.0,
		f32((hex >> 8) & 0xff) / 255.0,
		f32(hex & 0xff) / 255.0,
	}
}
