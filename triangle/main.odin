package main

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:os"
import sapp "shared:sokol/app"
import sg "shared:sokol/gfx"
import shelpers "shared:sokol/helpers"
import slog "shared:sokol/log"

ctx: runtime.Context

State :: struct {
	shader:        sg.Shader,
	pip:           sg.Pipeline,
	vertex_buffer: sg.Buffer,
	pass_action:   sg.Pass_Action,
}

state: ^State

VERT :: sg.Shader_Function {
	source = `
	#version 410
	layout(location=0) in vec4 position;
	layout(location=1) in vec4 color0;
	out vec4 color;
	void main() {
		gl_Position = position;
		color = color0;
	}
	`,
}

FRAG :: sg.Shader_Function {
	source = `
	#version 410

	in vec4 color;
	out vec4 frag_color;

	void main() {
		frag_color = color;
	}
	`,
}

BG: sg.Color = hex_to_vec4(0x181818ff)

Vec3 :: [3]f32
Vec4 :: [4]f32

main :: proc() {
	ctx = context
	sapp.run(
		{
			width = 800,
			height = 600,
			window_title = "Demo sokol",
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

	state = new(State)
	VertexData :: struct {
		pos: Vec3,
		col: sg.Color,
	}
	vertices := []VertexData {
		{pos = {0.0, 0.5, 0.5}, col = {1.0, 0.0, 0.0, 1.0}},
		{pos = {0.5, -0.5, 0.5}, col = {0.0, 1.0, 0.0, 1.0}},
		{pos = {-0.5, -0.5, 0.5}, col = {0.0, 0.0, 1.0, 1.0}},
	}
	state.vertex_buffer = sg.make_buffer(
		{data = {ptr = raw_data(vertices), size = len(vertices) * size_of(vertices[0])}},
	)

	state.shader = sg.make_shader(sg.Shader_Desc{vertex_func = VERT, fragment_func = FRAG})

	state.pip = sg.make_pipeline(
		{
			shader = state.shader,
			layout = {attrs = {0 = {format = .FLOAT3}, 1 = {format = .FLOAT4}}},
		},
	)

	state.pass_action = sg.Pass_Action {
		colors = {0 = sg.Color_Attachment_Action{load_action = .CLEAR, clear_value = BG}},
	}
}

cleanup_cb :: proc "c" () {
	context = ctx
	sg.destroy_buffer(state.vertex_buffer)
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
	sg.apply_bindings({vertex_buffers = {0 = state.vertex_buffer}})
	sg.draw(0, 3, 1)
	sg.end_pass()
	sg.commit()
}

hex_to_vec4 :: proc(hex: u32) -> sg.Color {
	return {
		f32((hex >> 24) & 0xff) / 255.0,
		f32((hex >> 16) & 0xff) / 255.0,
		f32((hex >> 8) & 0xff) / 255.0,
		f32(hex & 0xff) / 255.0,
	}
}
