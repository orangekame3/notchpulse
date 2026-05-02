class Notchpulse < Formula
  desc "System monitor that extends your MacBook's notch"
  homepage "https://github.com/orangekame3/notchpulse"
  url "https://github.com/orangekame3/notchpulse/releases/download/v#{version}/NotchPulse-#{version}-arm64.tar.gz"
  version "0.1.0"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on macos: :ventura
  depends_on arch: :arm64

  def install
    prefix.install "NotchPulse.app"
  end

  def post_install
    system "ln", "-sf", "#{prefix}/NotchPulse.app", "/Applications/NotchPulse.app"
  end

  def caveats
    <<~EOS
      NotchPulse.app has been installed to #{prefix}/NotchPulse.app
      and symlinked to /Applications.

      To start NotchPulse:
        open /Applications/NotchPulse.app
    EOS
  end

  test do
    assert_predicate prefix/"NotchPulse.app/Contents/MacOS/NotchCPUMonitor", :exist?
  end
end
