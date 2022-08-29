def branch(name)
  Geode::GitBranchRef.new(name)
end

def commit(sha1)
  Geode::GitCommitRef.new(sha1)
end

def hg_bookmark(name)
  Geode::HgBookmarkRef.new(name)
end

def hg_branch(name)
  Geode::HgBranchRef.new(name)
end

def fossil_branch(name)
  Geode::FossilBranchRef.new(name)
end

def version(version)
  Geode::Version.new(version)
end

def versions(versions)
  versions.map { |v| version(v) }
end

def version_req(pattern)
  Geode::VersionReq.new(pattern)
end
