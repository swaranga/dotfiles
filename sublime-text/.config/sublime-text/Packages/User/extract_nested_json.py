import sublime
import sublime_plugin
import json


class ExtractNestedJsonCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        self.view.window().show_input_panel("Enter the key:", "", self.on_done, None, None)

    def on_done(self, key):
        # Store the key and trigger the secondary command
        self.view.run_command("perform_replacement", {"key": key})


class PerformReplacementCommand(sublime_plugin.TextCommand):
    def run(self, edit, key):
        # Get the selected text
        selected_text = self.view.substr(self.view.sel()[0])

        # Try to parse the selected text as JSON
        try:
            outer_json = json.loads(selected_text)
            if key in outer_json:
                # Extract the specified key's field and parse it as JSON
                inner_json = json.loads(outer_json[key])

                # Convert the inner JSON back to a string with pretty print
                pretty_inner_json = json.dumps(inner_json, indent=4)

                # Replace the selected text with the pretty printed JSON
                self.view.replace(edit, self.view.sel()[0], pretty_inner_json)
            else:
                sublime.error_message(f"The selected JSON does not contain the key '{key}'.")
        except json.JSONDecodeError:
            sublime.error_message("Invalid JSON selected.")


class DequoteJsonStringCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        self.view.run_command("perform_dequote_replacement")


class PerformDequoteReplacementCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        # Get the selected region
        sel = self.view.sel()[0]
        selected_text = self.view.substr(sel)
        print("Selected text:", selected_text)  # Debug statement

        # Try to parse the selected text as JSON
        try:
            # Load the JSON string
            inner_json = json.loads(selected_text)
            print("Parsed JSON:", inner_json)  # Debug statement

            # Replace the selected text with the pretty printed JSON
            self.view.replace(edit, sel, inner_json)
            print("Replacement done.")  # Debug statement
        except json.JSONDecodeError:
            sublime.error_message("Invalid JSON selected.")
            print("Invalid JSON selected.")  # Debug statement

    def pretty_print_json(self, json_obj):
        """Pretty print a JSON object with indentation."""
        return json.dumps(json_obj, indent=4, separators=(',', ': '))
