package main
import sg "shared:sokol/gfx"
/*
    #version:1# (machine generated, don't edit!)

    Generated by sokol-shdc (https://github.com/floooh/sokol-tools)

    Cmdline:
        sokol-shdc -i shaders.glsl -o shaders.odin -l glsl430 -f sokol_odin

    Overview:
    =========
    Shader program: 'main':
        Get shader desc: main_shader_desc(sg.query_backend())
        Vertex Shader: vs
        Fragment Shader: fs
        Attributes:
            ATTR_main_position => 0
    Bindings:
*/
ATTR_main_position :: 0
/*
    #version 430

    layout(location = 0) in vec4 position;

    void main()
    {
        gl_Position = vec4(position.x, position.y, position.z, 1.0);
    }

*/
@(private = "file")
vs_source_glsl430 := [137]u8 {
	0x23,
	0x76,
	0x65,
	0x72,
	0x73,
	0x69,
	0x6f,
	0x6e,
	0x20,
	0x34,
	0x33,
	0x30,
	0x0a,
	0x0a,
	0x6c,
	0x61,
	0x79,
	0x6f,
	0x75,
	0x74,
	0x28,
	0x6c,
	0x6f,
	0x63,
	0x61,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x20,
	0x3d,
	0x20,
	0x30,
	0x29,
	0x20,
	0x69,
	0x6e,
	0x20,
	0x76,
	0x65,
	0x63,
	0x34,
	0x20,
	0x70,
	0x6f,
	0x73,
	0x69,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x3b,
	0x0a,
	0x0a,
	0x76,
	0x6f,
	0x69,
	0x64,
	0x20,
	0x6d,
	0x61,
	0x69,
	0x6e,
	0x28,
	0x29,
	0x0a,
	0x7b,
	0x0a,
	0x20,
	0x20,
	0x20,
	0x20,
	0x67,
	0x6c,
	0x5f,
	0x50,
	0x6f,
	0x73,
	0x69,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x20,
	0x3d,
	0x20,
	0x76,
	0x65,
	0x63,
	0x34,
	0x28,
	0x70,
	0x6f,
	0x73,
	0x69,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x2e,
	0x78,
	0x2c,
	0x20,
	0x70,
	0x6f,
	0x73,
	0x69,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x2e,
	0x79,
	0x2c,
	0x20,
	0x70,
	0x6f,
	0x73,
	0x69,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x2e,
	0x7a,
	0x2c,
	0x20,
	0x31,
	0x2e,
	0x30,
	0x29,
	0x3b,
	0x0a,
	0x7d,
	0x0a,
	0x0a,
	0x00,
}
/*
    #version 430

    layout(location = 0) out vec4 fragColor;

    void main()
    {
        fragColor = vec4(1.0, 0.5, 0.20000000298023223876953125, 1.0);
    }

*/
@(private = "file")
fs_source_glsl430 := [141]u8 {
	0x23,
	0x76,
	0x65,
	0x72,
	0x73,
	0x69,
	0x6f,
	0x6e,
	0x20,
	0x34,
	0x33,
	0x30,
	0x0a,
	0x0a,
	0x6c,
	0x61,
	0x79,
	0x6f,
	0x75,
	0x74,
	0x28,
	0x6c,
	0x6f,
	0x63,
	0x61,
	0x74,
	0x69,
	0x6f,
	0x6e,
	0x20,
	0x3d,
	0x20,
	0x30,
	0x29,
	0x20,
	0x6f,
	0x75,
	0x74,
	0x20,
	0x76,
	0x65,
	0x63,
	0x34,
	0x20,
	0x66,
	0x72,
	0x61,
	0x67,
	0x43,
	0x6f,
	0x6c,
	0x6f,
	0x72,
	0x3b,
	0x0a,
	0x0a,
	0x76,
	0x6f,
	0x69,
	0x64,
	0x20,
	0x6d,
	0x61,
	0x69,
	0x6e,
	0x28,
	0x29,
	0x0a,
	0x7b,
	0x0a,
	0x20,
	0x20,
	0x20,
	0x20,
	0x66,
	0x72,
	0x61,
	0x67,
	0x43,
	0x6f,
	0x6c,
	0x6f,
	0x72,
	0x20,
	0x3d,
	0x20,
	0x76,
	0x65,
	0x63,
	0x34,
	0x28,
	0x31,
	0x2e,
	0x30,
	0x2c,
	0x20,
	0x30,
	0x2e,
	0x35,
	0x2c,
	0x20,
	0x30,
	0x2e,
	0x32,
	0x30,
	0x30,
	0x30,
	0x30,
	0x30,
	0x30,
	0x30,
	0x32,
	0x39,
	0x38,
	0x30,
	0x32,
	0x33,
	0x32,
	0x32,
	0x33,
	0x38,
	0x37,
	0x36,
	0x39,
	0x35,
	0x33,
	0x31,
	0x32,
	0x35,
	0x2c,
	0x20,
	0x31,
	0x2e,
	0x30,
	0x29,
	0x3b,
	0x0a,
	0x7d,
	0x0a,
	0x0a,
	0x00,
}
main_shader_desc :: proc(backend: sg.Backend) -> sg.Shader_Desc {
	desc: sg.Shader_Desc
	desc.label = "main_shader"
	#partial switch backend {
	case .GLCORE:
		desc.vertex_func.source = transmute(cstring)&vs_source_glsl430
		desc.vertex_func.entry = "main"
		desc.fragment_func.source = transmute(cstring)&fs_source_glsl430
		desc.fragment_func.entry = "main"
		desc.attrs[0].glsl_name = "position"
	}
	return desc
}
