cask "quitly" do
  version "1.0.0"
  sha256 "cff3b8ae107f9fdc4cc34ed58238cd71d8b014844ded80f777844701476e906d"

  url "https://github.com/jotree96/quitly/releases/download/v#{version}/Quitly-#{version}.pkg"
  name "Quitly"
  desc "Zeigt alle offenen Fenster mit Schliessen-Button an"
  homepage "https://github.com/jotree96/quitly"

  depends_on macos: ">= :big_sur"

  pkg "Quitly-#{version}.pkg"

  uninstall quit:    "org.hammerspoon.Hammerspoon",
            pkgutil: "com.github.jotree96.quitly",
            delete:  "/Applications/Hammerspoon.app"

  zap trash: [
    "~/.hammerspoon/quitly",
    "/Library/Application Support/Quitly",
  ]

  caveats <<~EOS
    Quitly liegt auf Cmd + Alt + Ctrl + M.

    Hammerspoon braucht zwei Berechtigungen: Bedienungshilfen und
    Bildschirmaufnahme. Beide sind Pflicht. Nach der Installation
    oeffnet sich ein Fenster mit zwei Knoepfen, die direkt dorthin
    fuehren.

    Quitly laeuft vollstaendig lokal. Kein Konto, kein Server, keine
    Telemetrie. Hammerspoons Update-Pruefung wird abgeschaltet.
  EOS
end
