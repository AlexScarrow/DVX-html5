components {
  id: "cell_sprite1"
  component: "/main/cell_sprite.script"
}
embedded_components {
  id: "cell_sprite"
  type: "sprite"
  data: "default_animation: \"cell_open\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/cells.atlas\"\n"
  "}\n"
  ""
}
