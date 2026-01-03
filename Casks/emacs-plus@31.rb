cask "emacs-plus@31" do
  # Version format: <emacs-version>-<build-number>
  # Build number corresponds to GitHub Actions run number
  version "31.0.50-1"

  # Base URL for release assets (versioned releases: cask-31-<build>)
  base_url = "https://github.com/d12frosted/homebrew-emacs-plus/releases/download/cask-31-#{version.sub(/^[\d.]+-/, "")}"
  emacs_ver = version.sub(/-\d+$/, "")

  on_intel do
    sha256 "0f7481e5bd3e439cb2c83757e3121744c7bf10e5d8ab98a67b94dc5cb3cdb08a"
    url "#{base_url}/emacs-plus-#{emacs_ver}-x86_64-15.zip",
        verified: "github.com/d12frosted/homebrew-emacs-plus"
  end

  on_arm do
    if MacOS.version >= :tahoe # macOS 26
      sha256 "fe4c74206bef854cf7417b1c737a5bc3206fc8af756a59fe3338add330af4df9"
      url "#{base_url}/emacs-plus-#{emacs_ver}-arm64-26.zip",
          verified: "github.com/d12frosted/homebrew-emacs-plus"
    elsif MacOS.version >= :sequoia # macOS 15
      sha256 "b2d3847c69a2b07ea222648a1173b46c13f85b8d3dd5f10cdbc33237c454452a"
      url "#{base_url}/emacs-plus-#{emacs_ver}-arm64-15.zip",
          verified: "github.com/d12frosted/homebrew-emacs-plus"
    else # macOS 14 (Sonoma) and 13 (Ventura)
      sha256 "bd7f9ef5802a877cfedb039ccb5c430f22cf65ac469977301c5320c0e43d91e8"
      url "#{base_url}/emacs-plus-#{emacs_ver}-arm64-14.zip",
          verified: "github.com/d12frosted/homebrew-emacs-plus"
    end
  end

  name "Emacs+ (Development)"
  desc "GNU Emacs text editor with patches for macOS (development version)"
  homepage "https://github.com/d12frosted/homebrew-emacs-plus"

  # Conflict with other Emacs cask installations
  conflicts_with cask: [
    "emacs",
    "emacs-mac",
    "emacs-mac-spacemacs-icon",
    "emacs-plus",
    "emacs-plus@30",
  ]

  # Install the app
  app "Emacs.app"
  app "Emacs Client.app"

  # Remove quarantine attribute and apply custom icon
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Emacs.app"],
                   sudo: false
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Emacs Client.app"],
                   sudo: false

    # Apply custom icon from ~/.config/emacs-plus/build.yml if configured
    tap = Tap.fetch("d12frosted", "emacs-plus")
    load "#{tap.path}/Library/IconApplier.rb"
    if IconApplier.apply("#{appdir}/Emacs.app", "#{appdir}/Emacs Client.app")
      # Re-sign after icon change
      system_command "/usr/bin/codesign",
                     args: ["--force", "--deep", "--sign", "-", "#{appdir}/Emacs.app"],
                     sudo: false
      system_command "/usr/bin/codesign",
                     args: ["--force", "--deep", "--sign", "-", "#{appdir}/Emacs Client.app"],
                     sudo: false
    end
  end

  # Symlink binaries
  binary "#{appdir}/Emacs.app/Contents/MacOS/Emacs", target: "emacs"
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/emacsclient"
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/ebrowse"
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/etags"

  # Man pages (not gzipped in the build)
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/emacs.1"
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/emacsclient.1"
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/ebrowse.1"
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/etags.1"

  # Cleanup on uninstall
  zap trash: [
    "~/Library/Caches/org.gnu.Emacs",
    "~/Library/Preferences/org.gnu.Emacs.plist",
    "~/Library/Saved Application State/org.gnu.Emacs.savedState",
    "~/.emacs.d",
  ]

  caveats <<~EOS
    Emacs+ (development) has been installed to /Applications.

    This is a pre-built binary from the Emacs master branch.
    For custom patches or build options, use the formula instead:
      brew install emacs-plus@31 --with-...

    Custom icons can be configured via ~/.config/emacs-plus/build.yml:
      icon: dragon-plus

    To re-apply an icon after changing build.yml:
      brew reinstall --cask emacs-plus@31

    Note: Emacs Client.app requires Emacs to be running as a daemon.
    Add to your Emacs config: (server-start)
  EOS
end
