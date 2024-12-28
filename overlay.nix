self: super: {

  libpromhttp = super.libpromhttp.override {
    stdenv = self.gcc13Stdenv;
  };

  pam_ssh_agent_auth = super.pam_ssh_agent_auth.override {
    stdenv = self.gcc13Stdenv;
  };

  matrix-synapse-unwrapped = super.matrix-synapse-unwrapped.overridePythonAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
  });
  pythonPackagesExtensions = super.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      pysaml2 = python-prev.pysaml2.overridePythonAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
      });

    })
  ];

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
