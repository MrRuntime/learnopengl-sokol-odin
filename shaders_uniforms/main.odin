package main

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import m "core:math"
import sapp "shared:sokol/app"
import sg "shared:sokol/gfx"
import shelpers "shared:sokol/helpers"
import slog "shared:sokol/log"
import stm "shared:sokol/time"

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
	layout(location=0) in vec3 pos;

	void main() {
		gl_Position = vec4(pos, 1.0);
	}
	`,
}

FRAG :: sg.Shader_Function {
	source = `
	#version 410
	uniform vec4 ucolor;
	out vec4 frag_color;

	void main() {
		frag_color = ucolor;
	}
	`,
}

// BG: sg.Color = hex_to_vec4(0x181818ff)
BG: sg.Color = hex_to_vec4(0x334c4cff)

Vec3 :: [3]f32
Vec4 :: [4]f32

VertexData :: struct {
	pos: Vec3,
}

main :: proc() {
	ctx = context
	sapp.run(
		{
			width = 800,
			height = 600,
			window_title = "In-Out",
			icon = {sokol_default = true},
			logger = {func = slog.func},
			allocator = sapp.Allocator(shelpers.allocator(&ctx)),
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
			logger = {func = slog.func},
		},
	)

	stm.setup()

	state = new(State)

	vertices := []Vec3{{-0.5, -0.5, 0.0}, {0.5, -0.5, 0.0}, {0.0, 0.5, 0.0}}
	state.bind.vertex_buffers[0] = sg.make_buffer({data = sg_range(vertices)})

	// ids := []u16{0, 1, 1, 3, 3, 0, 1, 2, 2, 3, 3, 1}
	// state.index_buffer = sg.make_buffer(
	// 	{type = .INDEXBUFFER, data = {ptr = raw_data(ids), size = len(ids) * size_of(ids[0])}},
	// )
	shader_desc := sg.Shader_Desc {
		vertex_func   = VERT,
		fragment_func = FRAG,
	}

	shader_desc.uniform_blocks[0].stage = .FRAGMENT
	shader_desc.uniform_blocks[0].glsl_uniforms[0].type = .FLOAT4
	shader_desc.uniform_blocks[0].glsl_uniforms[0].glsl_name = "ucolor"

	state.shader = sg.make_shader(shader_desc)

	state.pip = sg.make_pipeline(
		{shader = state.shader, layout = {attrs = {0 = {format = .FLOAT3}}}},
	)

	state.pass_action = sg.Pass_Action {
		colors = {0 = sg.Color_Attachment_Action{load_action = .CLEAR, clear_value = BG}},
	}
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
	now := stm.sec(stm.now())
	greenValue := m.sin_f64(now) / 2.0 + 0.5

	sg.apply_uniforms(0, sg_range([]f32{0.0, f32(greenValue), 0.0, 1.0}))

	sg.draw(0, 3, 1)
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
