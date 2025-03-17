@header package main
@header import sg "shared:sokol/gfx"

@vs vs
in vec4 position;

void main() {
    gl_Position = vec4(position.x, position.y, position.z, 1.0);
}
@end

@fs fs
out vec4 fragColor;

void main() {
    fragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
@end

@program main vs fs
