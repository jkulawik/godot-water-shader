# godot-water-shader

![](./water_shader.gif)

A textured water shader for Godot. Made with low-res textures in mind, but it should look fine with better ones.

[Raw shader code link](./WaterShaderDemo/water_simple.shader)

Features:
- waves
- foam
- depth shading
- proximity fade
- UV scroll animation
- basic refraction
- basic PBR parameters (roughness, metallic, normal)

The shader was based on [UnionBytes'](https://github.com/godot-extended-libraries/godot-realistic-water) and [Paddy's](https://github.com/paddy-exe/Godot-3D-Stylized-Water) water shaders. I started from converting a PBR material to a shader and merged the features I wanted from the other shaders.

## Disclaimers
- The attached project doesn't have the terrain in it, but you can still see the config that I used in the preview GIF.
- As far as I know, the waves can only roll. Perhaps it's possible to make a standing wave with it, I'm not sure. Submit an issue with the parameters if you find an interesting config for the waves.
- The waves can only roll in a single direction. It can be reversed by changing the time to be subtracted in the wave function, but still. This is partially alleviated by being able to control the UV animation direction. The wave function from UnionBytes should be possible to port over without much hassle, however.
- The refraction only reflects the bottom of the water and nearby objects. For some reason I couldn't get even a regular material to do this effect (i.e. when the submerged part of an object seems to shift place).
