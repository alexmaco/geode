require "./command"

module Geode
  module Commands
    class List < Command
      @tree = false

      def run(@tree = false)
        return unless has_dependencies?
        puts "Shards installed:"
        list(spec.dependencies)
        list(spec.development_dependencies) if Geode.with_development?
      end

      private def list(dependencies, level = 1)
        dependencies.each do |dependency|
          package = Geode.info.installed[dependency.name]?
          unless package
            Log.debug { "#{dependency.name}: not installed" }
            raise Error.new("Dependencies aren't satisfied. Install them with 'shards install'")
          end

          indent = "  " * level
          puts "#{indent}* #{package}"

          indent_level = @tree ? level + 1 : level
          list(package.spec.dependencies, indent_level)
        end
      end

      # FIXME: duplicates Check#has_dependencies?
      private def has_dependencies?
        spec.dependencies.any? || (Geode.with_development? && spec.development_dependencies.any?)
      end
    end
  end
end
