require "file_utils"
require "./helpers"

module Geode
  class Package
    getter name : String
    getter resolver : Resolver
    getter version : Version
    getter is_override : Bool
    @spec : Spec?

    def initialize(@name, @resolver, @version, @is_override = false)
    end

    def_equals @name, @resolver, @version

    def report_version
      resolver.report_version(version)
    end

    def spec
      @spec ||= begin
        if installed?
          read_installed_spec
        else
          resolver.spec(version)
        end
      end
    end

    private def read_installed_spec
      path = File.join(install_path, SPEC_FILENAME)
      unless File.exists?(path)
        return resolver.spec(version)
      end

      begin
        spec = Spec.from_file(path)
        spec.version = version
        spec
      rescue error : ParseError
        error.resolver = resolver
        raise error
      end
    end

    def installed?
      return false unless File.exists?(install_path)
      if installed = Geode.info.installed[name]?
        installed.resolver == resolver && installed.version == version
      else
        false
      end
    end

    def install_path
      File.join(Geode.install_path, name)
    end

    def install
      cleanup_install_directory

      # install the shard:
      resolver.install_sources(version, install_path)

      # link the project's lib path as the shard's lib path, so the dependency
      # can access transitive dependencies:
      unless resolver.is_a?(PathResolver)
        lib_path = File.join(install_path, Geode::INSTALL_DIR)
        Log.debug { "Link #{Geode.install_path} to #{lib_path}" }
        Dir.mkdir_p(File.dirname(lib_path))
        target = File.join(Path.new(Geode::INSTALL_DIR).parts.map { ".." })
        File.symlink(target, lib_path)
      end

      Geode.info.installed[name] = self
      Geode.info.save
    end

    protected def cleanup_install_directory
      Log.debug { "rm -rf #{Process.quote(install_path)}" }
      Geode::Helpers.rm_rf(install_path)
    end

    def postinstall
      run_script("postinstall", Geode.skip_postinstall?)
    rescue ex : Script::Error
      cleanup_install_directory
      raise ex
    end

    def run_script(name, skip)
      if installed? && (command = spec.scripts[name]?)
        if !skip
          Log.info { "#{name.capitalize} of #{self.name}: #{command}" }
          Script.run(install_path, command, name, self.name)
        else
          Log.info { "#{name.capitalize} of #{self.name}: #{command} (skipped)" }
        end
      end
    end

    def install_executables
      return if !installed? || spec.executables.empty? || Geode.skip_executables?

      Dir.mkdir_p(Geode.bin_path)

      spec.executables.each do |name|
        exe_name = Geode::Helpers.exe(name)
        Log.debug { "Install bin/#{exe_name}" }
        source = File.join(install_path, "bin", exe_name)
        destination = File.join(Geode.bin_path, exe_name)

        if File.exists?(destination)
          next if File.same?(destination, source)
          File.delete(destination)
        end

        begin
          File.link(source, destination)
        rescue File::Error
          FileUtils.cp(source, destination)
        end
      end
    end

    def to_yaml(builder)
      Dependency.new(name, resolver, version).to_yaml(builder)
    end

    def to_s(io)
      io << name << " (" << report_version << ")"
    end
  end
end
