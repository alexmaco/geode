ENV["GEODE_CACHE_PATH"] = ".shards"
ENV["GEODE_INSTALL_PATH"] = File.expand_path(".lib", __DIR__)

require "spec"
require "../../src/config"
require "../../src/helpers"
require "../../src/logger"
require "../../src/resolvers/*"

require "../support/factories"
require "../support/requirement"

module Geode
  set_warning_log_level
end

Spec.before_each do
  clear_repositories
  Geode::Resolver.clear_resolver_cache
  Geode.info.reload
end

private def clear_repositories
  Geode::Helpers.rm_rf_children(tmp_path)
  Geode::Helpers.rm_rf(Geode.cache_path)
  Geode::Helpers.rm_rf(Geode.install_path)
end

def install_path(project, *path_names)
  File.join(Geode.install_path, project, *path_names)
end
