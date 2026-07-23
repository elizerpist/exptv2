import 'browser_fullscreen_controller.dart';
import 'browser_fullscreen_driver_stub.dart'
    if (dart.library.js_interop) 'browser_fullscreen_driver_web.dart'
    as platform;

BrowserFullscreenController createBrowserFullscreenController() =>
    BrowserFullscreenController(platform.createBrowserFullscreenDriver());
