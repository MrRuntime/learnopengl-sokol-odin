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
	pass_action: sg.Pass_Action,
}

state: State

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
	fmt.println("init")
	sg.setup(
		{
			environment = shelpers.glue_environment(),
			allocator = sg.Allocator(shelpers.allocator(&ctx)),
			logger = {func = slog.func},
		},
	)

	state.pass_action.colors[0] = sg.Color_Attachment_Action {
		load_action = .CLEAR,
		clear_value = sg.Color{r = 1, g = 1, b = 0, a = 1},
	}

	fmt.println("Backend: ", sg.query_backend())
}

cleanup_cb :: proc "c" () {
	context = ctx
	fmt.println("cleanup")
	sg.shutdown()
}

event_cb :: proc "c" (ev: ^sapp.Event) {
	context = ctx
	if ev.type == .KEY_DOWN {
		if ev.key_code == .ESCAPE {
			sapp.request_quit()
			// sapp.quit()
		}
		// fmt.println(ev.key_code)
	}
}

frame_cb :: proc "c" () {
	context = ctx
	g := state.pass_action.colors[0].clear_value.g + 0.01
	state.pass_action.colors[0].clear_value.g = g > 1.0 ? 0.0 : g
	sg.begin_pass({swapchain = shelpers.glue_swapchain(), action = state.pass_action})
	sg.end_pass()
	sg.commit()
}
