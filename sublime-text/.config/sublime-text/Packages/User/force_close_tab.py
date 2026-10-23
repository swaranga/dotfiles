import sublime
import sublime_plugin

class ForceCloseTabCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        self.view.set_scratch(True)
        self.view.close()