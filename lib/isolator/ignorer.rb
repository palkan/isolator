# frozen_string_literal: true

module Isolator
  # Handle ignoring isolator errors using a yml file
  class Ignorer
    TODO_PATH = ".isolator_todo.yml"

    class << self
      def prepare(path: TODO_PATH, regex_string: "^.*(#ignores#):.*$")
        return unless File.exist?(path)

        todos = YAML.load_file(path)

        Isolator.adapters.each do |id, adapter|
          ignored_paths = todos.fetch(id, [])
          AdapterIgnore.new(adapter: adapter, ignored_paths: ignored_paths, regex_string: regex_string).prepare
        end
      end
    end

    private

    class AdapterIgnore
      def initialize(adapter:, ignored_paths:, regex_string:)
        self.adapter = adapter
        self.ignored_paths = ignored_paths
        self.regex_string = regex_string
      end

      def prepare
        return if ignores.blank?

        adapter.ignore_if { caller.any? { |row| regex =~ row } }
      end

      private

      attr_accessor :adapter, :ignored_paths, :regex_string

      def ignores
        return @ignores if defined? @ignores

        @ignores = ignored_paths.each_with_object([]) do |path, result|
          ignored_files = Dir[path]

          if ignored_files.blank?
            result << path.to_s
          else
            result.concat(ignored_files)
          end
        end
      end

      def regex
        Regexp.new(regex_string.gsub("#ignores#", ignores.join("|")))
      end
    end
  end
end
