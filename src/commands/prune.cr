require "file_utils"
require "./command"
require "../helpers"

module Geode
  module Commands
    class Prune < Command
      def run
        return unless lockfile?

        Dir.each_child(Geode.install_path) do |name|
          path = File.join(Geode.install_path, name)
          next unless File.directory?(path)

          if locks.shards.none? { |d| d.name == name }
            Log.debug { "rm -rf '#{Process.quote(path)}'" }
            Geode::Helpers.rm_rf(path)

            Geode.info.installed.delete(name)
            Log.info { "Pruned #{File.join(File.basename(Geode.install_path), name)}" }
          end
        end

        Geode.info.save
      end
    end
  end
end
