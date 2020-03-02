# frozen_string_literal: true

module Isolator
  # Add .load_ignore_config function for ignoring patterns from file
  module Ignorer
    def load_ignore_config(path)
      return unless File.exist?(path)

      todos = YAML.load_file(path)

      adapters.each do |id, adapter|
        ignored_paths = todos.fetch(id, [])
        configure_adapter(adapter, ignored_paths)
      end
    end

    private

    def configure_adapter(adapter, ignored_paths)
      ignores = build_ignore_list(ignored_paths)
      return if ignores.blank?

      regex = Regexp.new("^.*(#{ignores.join("|")}):.*$")
      adapter.ignore_if { caller.any? { |row| regex =~ row } }
    end

    def build_ignore_list(ignored_paths)
      ignored_paths.each_with_object([]) do |path, result|
        ignored_files = Dir[path]

        if ignored_files.blank?
          result << path.to_s
        else
          result.concat(ignored_files)
        end
      end
    end
  end
end
