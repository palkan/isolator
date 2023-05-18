# frozen_string_literal: true

module Isolator
  # Handle ignoring isolator errors using a yml file
  class Ignorer
    class ParseError < StandardError
      def initialize(file_path, klass)
        @file_path = file_path
        @klass = klass
      end

      def message
        "Unable to parse ignore config file #{@file_path}. Expected Hash, got #{@klass}."
      end
    end

    class << self
      def prepare(path:, regex_string: "^.*(#ignores#):.*$")
        return unless File.exist?(path)

        ignores = begin
          YAML.load_file(path, aliases: true)
        rescue ArgumentError # support for older rubies https://github.com/rails/rails/commit/179d0a1f474ada02e0030ac3bd062fc653765dbe
          YAML.load_file(path)
        end

        raise ParseError.new(path, ignores.class) unless ignores.respond_to?(:fetch)

        Isolator.adapters.each do |id, adapter|
          ignored_paths = ignores.fetch(id, [])
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
