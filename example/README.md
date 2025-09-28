# Example: warp-terminal AppImage, using appimageTools.wrapType2

This example demonstrates how to build a Home Manager configuration that exposes a `warp-terminal` wrapper. It uses a placeholder hash by default so you can run it without a prefetch step. On first build, Nix will fail with a hash mismatch and print the correct hash to use.

Steps
1) Try a dev shell (no HM switch needed):
   nix develop
   # The build will fail with a message showing the correct sha256. Copy it.

2) Update flake.nix with the suggested sha256 (SRI format), then retry:
   # edit ./flake.nix (replace the placeholder hash)
   nix develop
   warp-terminal

Alternative (Home Manager):
- You can also switch your Home Manager to the example:
  home-manager switch --flake .#netbrain
  warp-terminal

Notes
- The wrapper name is set via binName = "warp-terminal"; in the example.
- If the upstream updates the AppImage, update the hash in flake.nix with the new suggested hash from the build error.
