cask "quitly" do
  version "1.0.0"
  sha256 "683f800938df2155bfcaa1bd8f5fd29c9b3d67807a6cc0ca6dbca27feb8ff5b8"

  url "https://github.com/DEIN-GITHUB-NAME/quitly/releases/download/v#{version}/Quitly-#{version}.pkg"
  name "Quitly"
  desc "Zeigt alle offenen Fenster mit Schliessen-Button an"
  homepage "https://github.com/DEIN-GITHUB-NAME/quitly"

  depends_on macos: ">= :big_sur"

  pkg "Quitly-#{version}.pkg"

  uninstall quit:    "org.hammerspoon.Hammerspoon",
            pkgutil: "de.humandigitals.quitly",
            delete:  "/Applications/Hammerspoon.app"

  zap trash: [
    "~/.hammerspoon/quitly",
    "/Library/Application Support/Quitly",
  ]

  caveats <<~EOS
    Quitly liegt auf Cmd + Alt + Ctrl + M.

    Hammerspoon braucht zwei Berechtigungen: Bedienungshilfen und
    Bildschirmaufnahme. Nach der Installation oeffnet sich ein Fenster
    mit zwei Knoepfen, die direkt dorthin fuehren.
  EOS
end
