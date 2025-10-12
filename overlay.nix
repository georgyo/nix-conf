self: super: {

  opengl_dir = super.callPacakge { } (
    {
      buildEnv,
      mesa,
      nvidia_x11,
    }:
    buildEnv {
      name = "opengl_dir";
      paths = [
        mesa.drivers
        nvidia_x11.out
      ];

    }
  );
}
