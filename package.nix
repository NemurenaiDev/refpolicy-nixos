{
  lib,
  pkgs,
  stdenv,
  policyVersion ? null,
  moduleVersion ? null,
}:
stdenv.mkDerivation (finalAttrs: {
  src = ./.;

  pname = "refpolicy-nixos";
  version = "2026-09-11";

  nativeBuildInputs = [
    pkgs.gnum4
    pkgs.python3
    pkgs.getopt
    pkgs.bash
  ];

  configurePhase = ''
    runHook preConfigure


    substituteInPlace policy/modules/kernel/corecommands.fc --replace-fail "/usr/lib/systemd/systemd.*" "/usr/lib/systemd/systemd.+"

    substituteInPlace policy/modules/**/*.fc \
      --replace-quiet "/usr/bin/" "/nix/store/[^/]+/(bin|sbin)/" \
      --replace-quiet "/usr/sbin/" "/nix/store/[^/]+/(sbin|bin)/" \
      --replace-quiet "/usr/lib/" "/nix/store/[^/]+/(lib|libexec)/" \
      --replace-quiet "/usr/libexec/" "/nix/store/[^/]+/(libexec|lib)/" \
      --replace-quiet "/usr/" "/nix/store/[^/]+/" \
      --replace-quiet "/etc" "/(etc|etc/static)"


    make conf ''${makeFlags[@]}

    runHook postConfigure
  '';

  makeFlags = [
    "SHELL=${pkgs.bash}/bin/bash"

    "CHECKPOLICY=${lib.getExe pkgs.checkpolicy}"
    "CHECKMODULE=${lib.getExe' pkgs.checkpolicy "checkmodule"}"

    "SEMODULE=${lib.getExe' pkgs.policycoreutils "semodule"}"
    "SEMOD_PKG=${lib.getExe' pkgs.semodule-utils "semodule_package"}"
    "SEMOD_LNK=${lib.getExe' pkgs.semodule-utils "semodule_link"}"
    "SEMOD_EXP=${lib.getExe' pkgs.semodule-utils "semodule_expand"}"

    "DESTDIR=${placeholder "out"}"
    "prefix=${placeholder "out"}"
    "DISTRO=nixos"
    "SYSTEMD=y"
    "UBAC=y"

    "MONOLITHIC=y"
    "SETFILES=${pkgs.policycoreutils}/bin/setfiles"
  ]
  ++ lib.optional (policyVersion != null) "OUTPUT_POLICY=${toString policyVersion}"
  ++ lib.optional (moduleVersion != null) "OUTPUT_MODULE=${toString moduleVersion}";

  installTargets = "all install install-headers";

  meta = {
    description = "SELinux Reference Policy with experimental NixOS support (WIP)";
    homepage = "http://userspace.selinuxproject.org";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Only;
    maintainers = [ ];
  };
})
