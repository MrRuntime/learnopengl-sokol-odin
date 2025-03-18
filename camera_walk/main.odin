package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:log"
import glm "core:math/linalg/glsl"
import sapp "shared:sokol/app"
import sg "shared:sokol/gfx"
import shelpers "shared:sokol/helpers"
import stm "shared:sokol/time"
import stbi "vendor:stb/image"

ctx: runtime.Context

State :: struct {
	shader:      sg.Shader,
	pip:         sg.Pipeline,
	bind:        sg.Bindings,
	pass_action: sg.Pass_Action,
	cube_pos:    [10]glm.vec3,
	cam_pos:     glm.vec3,
	cam_front:   glm.vec3,
	cam_up:      glm.vec3,
	last_time:   u64,
	delta_time:  u64,
}

state: ^State

VERT :: sg.Shader_Function {
	source = `
	#version 410
	layout(location=0) in vec3 a_pos;
	layout(location=1) in vec2 a_tex_coord;

	out vec2 tex_coord;

	uniform mat4 model;
	uniform mat4 view;
	uniform mat4 projection;

	void main() {
		gl_Position = projection * view * model * vec4(a_pos, 1.0);
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
	pos: glm.vec3,
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

	stm.setup()

	stbi.set_flip_vertically_on_load(1)

	state.cam_pos = glm.vec3{0, 0, 3}
	state.cam_front = glm.vec3{0, 0, -1}
	state.cam_up = glm.vec3{0, 1, 0}

	state.cube_pos = [10]glm.vec3 {
		{0, 0, 0},
		{2, 5, -15},
		{-1.5, -2.2, -2.5},
		{-3.8, -2, -12.3},
		{2.4, -0.4, -3.5},
		{-1.7, 3.0, -7.5},
		{1.3, -2, -2.5},
		{1.5, 2, -2.5},
		{1.5, 0.2, -1.5},
		{-1.3, 1, -1.5},
	}

	vertices := []VertexData {
		{pos = {-0.5, -0.5, -0.5}, uv = {0.0, 0.0}},
		{pos = {0.5, -0.5, -0.5}, uv = {1.0, 0.0}},
		{pos = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
		{pos = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
		{pos = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {-0.5, -0.5, -0.5}, uv = {0.0, 0.0}},
		{pos = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
		{pos = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {0.5, 0.5, 0.5}, uv = {1.0, 1.0}},
		{pos = {0.5, 0.5, 0.5}, uv = {1.0, 1.0}},
		{pos = {-0.5, 0.5, 0.5}, uv = {0.0, 1.0}},
		{pos = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
		{pos = {-0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {-0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
		{pos = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
		{pos = {-0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
		{pos = {0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
		{pos = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {0.5, -0.5, -0.5}, uv = {1.0, 1.0}},
		{pos = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {0.5, -0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {-0.5, -0.5, 0.5}, uv = {0.0, 0.0}},
		{pos = {-0.5, -0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}},
		{pos = {0.5, 0.5, -0.5}, uv = {1.0, 1.0}},
		{pos = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {0.5, 0.5, 0.5}, uv = {1.0, 0.0}},
		{pos = {-0.5, 0.5, 0.5}, uv = {0.0, 0.0}},
		{pos = {-0.5, 0.5, -0.5}, uv = {0.0, 1.0}},
	}

	state.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

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

	shader_desc.uniform_blocks[0].stage = .VERTEX
	shader_desc.uniform_blocks[0].layout = .STD140
	shader_desc.uniform_blocks[0].size = 64
	shader_desc.uniform_blocks[0].glsl_uniforms[0].type = .MAT4
	shader_desc.uniform_blocks[0].glsl_uniforms[0].glsl_name = "model"

	shader_desc.uniform_blocks[1].stage = .VERTEX
	shader_desc.uniform_blocks[1].layout = .STD140
	shader_desc.uniform_blocks[1].size = 64
	shader_desc.uniform_blocks[1].glsl_uniforms[0].type = .MAT4
	shader_desc.uniform_blocks[1].glsl_uniforms[0].glsl_name = "view"

	shader_desc.uniform_blocks[2].stage = .VERTEX
	shader_desc.uniform_blocks[2].layout = .STD140
	shader_desc.uniform_blocks[2].size = 64
	shader_desc.uniform_blocks[2].glsl_uniforms[0].type = .MAT4
	shader_desc.uniform_blocks[2].glsl_uniforms[0].glsl_name = "projection"

	state.shader = sg.make_shader(shader_desc)

	layout: sg.Vertex_Layout_State
	layout.attrs[0] = sg.Vertex_Attr_State {
		format = .FLOAT3,
	}
	layout.attrs[1] = sg.Vertex_Attr_State {
		format = .FLOAT2,
	}

	state.pip = sg.make_pipeline(
		{
			shader = state.shader,
			layout = layout,
			depth = sg.Depth_State{compare = .LESS_EQUAL, write_enabled = true},
		},
	)

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
		cam_speed: f32 = 5 * f32(stm.sec(state.delta_time))

		#partial switch ev.key_code {
		case .ESCAPE:
			sapp.request_quit()
		case .W:
			state.cam_pos += state.cam_front * cam_speed
		case .S:
			state.cam_pos -= state.cam_front * cam_speed
		case .A:
			offset := glm.normalize_vec3(glm.cross(state.cam_front, state.cam_up)) * cam_speed
			state.cam_pos -= offset
		case .D:
			offset := glm.normalize_vec3(glm.cross(state.cam_front, state.cam_up)) * cam_speed
			state.cam_pos += offset
		}
	}
}

frame_cb :: proc "c" () {
	context = ctx
	state.delta_time = stm.laptime(&state.last_time)

	view := glm.mat4LookAt(state.cam_pos, state.cam_pos + state.cam_front, state.cam_up)
	projection := glm.mat4Perspective(
		glm.radians_f32(60),
		sapp.widthf() / sapp.heightf(),
		0.1,
		100,
	)

	sg.begin_pass({action = state.pass_action, swapchain = shelpers.glue_swapchain()})
	sg.apply_pipeline(state.pip)
	sg.apply_bindings(state.bind)
	for cube, i in state.cube_pos {
		model := glm.mat4Translate(cube)
		angle := f32(20 * i)
		rotate := glm.mat4Rotate(glm.vec3{1, 0.3, 0.5}, glm.radians(angle))
		model = model * rotate
		sg.apply_uniforms(0, sg_range(&model))
		sg.apply_uniforms(1, sg_range(&view))
		sg.apply_uniforms(2, sg_range(&projection))
		sg.draw(0, 36, 1)
	}
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
	sg_range_from_matrix,
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
