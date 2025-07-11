// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Manually register controllers if auto-loading fails
import ThemeController from "./theme_controller"
import ClaudeCodeController from "./claude_code_controller"
import ClipboardController from "./clipboard_controller"

application.register("theme", ThemeController)
application.register("claude-code", ClaudeCodeController)
application.register("clipboard", ClipboardController)

console.log("Controllers index.js loaded, registered controllers:", application.controllers.map(c => c.identifier))
