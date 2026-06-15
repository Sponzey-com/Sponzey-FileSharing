import Cocoa
import FlutterMacOS
import ObjectiveC.runtime

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    FirstMouseInstaller.install(on: flutterViewController.view)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.initialFirstResponder = flutterViewController.view
    self.makeFirstResponder(flutterViewController.view)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

private enum FirstMouseInstaller {
  private static var installedClassNames = Set<String>()

  static func install(on view: NSView) {
    guard let viewClass = object_getClass(view) else {
      return
    }

    let className = NSStringFromClass(viewClass)
    guard className.contains("Flutter") else {
      return
    }
    guard !installedClassNames.contains(className) else {
      return
    }

    let selector = #selector(NSView.acceptsFirstMouse(for:))
    let implementation = imp_implementationWithBlock(
      { (_: NSView, _: NSEvent?) -> Bool in
        true
      } as @convention(block) (NSView, NSEvent?) -> Bool
    )
    class_replaceMethod(viewClass, selector, implementation, "c@:@")
    installedClassNames.insert(className)
  }
}
