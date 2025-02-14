require "../lock"
require "../spec"
require "../override"

module Geode
  abstract class Command
    getter path : String
    getter spec_path : String
    getter lockfile_path : String
    getter override_path : String?

    @spec : Spec?
    @locks : Lock?
    @override : Override?

    def initialize(path)
      if File.directory?(path)
        @path = path
        @spec_path = File.join(path, SPEC_FILENAME)
      else
        @path = File.dirname(path)
        @spec_path = path
      end
      @lockfile_path = File.join(@path, LOCK_FILENAME)

      # If global override is defined via GEODE_OVERRIDE env var we use that.
      # Otherwise we check if the is a shard.override.yml file next to the shard.yml
      @override_path = Geode.global_override_filename
      unless @override_path
        local_override = File.join(@path, OVERRIDE_FILENAME)
        @override_path = File.exists?(local_override) ? local_override : nil
      end
    end

    def self.run(path, *args, **kwargs)
      new(path).run(*args, **kwargs)
    end

    def spec
      @spec ||= if File.exists?(spec_path)
                  Spec.from_file(spec_path)
                else
                  raise Error.new("Missing #{spec_filename}. Please run 'shards init'")
                end
    end

    def spec_filename
      File.basename(spec_path)
    end

    def locks
      @locks ||= if lockfile?
                   Geode::Lock.from_file(lockfile_path)
                 else
                   raise Error.new("Missing #{LOCK_FILENAME}. Please run 'shards install'")
                 end
    end

    def lockfile?
      File.exists?(lockfile_path)
    end

    def override
      @override ||= override_path.try { |p| Geode::Override.from_file(p) }
    end

    def write_lockfile(packages)
      Log.info { "Writing #{LOCK_FILENAME}" }

      override_path = @override_path
      override_path = File.basename(override_path) if override_path && File.dirname(override_path) == @path

      Geode::Lock.write(packages, override_path, LOCK_FILENAME)
    end

    def handle_resolver_errors
      yield
    rescue e : Molinillo::ResolverError
      Log.error { e.message }
      raise Geode::Error.new("Failed to resolve dependencies")
    end

    def check_crystal_version(packages)
      crystal_version = Geode::Version.new Geode.crystal_version

      packages.each do |package|
        crystal_req = MolinilloSolver.crystal_version_req(package.spec)

        if !Geode::Versions.matches?(crystal_version, crystal_req)
          Log.warn { "Shard \"#{package.name}\" may be incompatible with Crystal #{Geode.crystal_version}" }
        end
      end
    end

    def touch_install_path
      Dir.mkdir_p(Geode.install_path)
      File.touch(Geode.install_path)
    end
  end
end
