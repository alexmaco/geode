require "./command"

module Geode
  module Commands
    class Build < Command
      def run(targets, options)
        if spec.targets.empty?
          raise Error.new("Targets not defined in #{SPEC_FILENAME}")
        end

        unless Dir.exists?(Geode.bin_path)
          Log.debug { "mkdir #{Geode.bin_path}" }
          Dir.mkdir(Geode.bin_path)
        end

        if targets.empty?
          targets = spec.targets.map(&.name)
        end

        targets.each do |name|
          if target = spec.targets.find { |t| t.name == name }
            build(target, options)
          else
            raise Error.new("Error target #{name} was not found in #{SPEC_FILENAME}.")
          end
        end
      end

      private def build(target, options)
        Log.info { "Building: #{target.name}" }

        args = [
          "build",
          "-o", File.join(Geode.bin_path, target.name),
          target.main,
        ]
        unless Geode.colors?
          args << "--no-color"
        end
        if Geode::Log.level <= ::Log::Severity::Debug
          args << "--verbose"
        end
        options.each { |option| args << option }
        Log.debug { "#{Geode.crystal_bin} #{args.join(' ')}" }

        error = IO::Memory.new
        status = Process.run(Geode.crystal_bin, args: args, output: Process::Redirect::Inherit, error: error)
        if status.success?
          STDERR.puts error unless error.empty?
        else
          raise Error.new("Error target #{target.name} failed to compile:\n#{error}")
        end
      end
    end
  end
end
