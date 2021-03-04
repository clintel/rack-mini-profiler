# frozen_string_literal: true

class SqlPatches
  def self.correct_version?(required_version, klass)
    Gem::Dependency.new('', required_version).match?('', klass::VERSION)
  rescue NameError
    false
  end

  def self.record_sql(statement, parameters = nil, &block)
    start  = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    record = ::Rack::MiniProfiler.record_sql(statement, elapsed_time(start), parameters)
    [result, record]
  end

  def self.should_measure?
    current = ::Rack::MiniProfiler.current
    (current && current.measure)
  end

  def self.elapsed_time(start_time)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).to_f * 1000).round(1)
  end

  def self.patch_rails?
    ::Rack::MiniProfiler.patch_rails?
  end

  def self.sql_patches
    patches = []
    patches << 'activerecord' if defined?(ActiveRecord) && ActiveRecord.class == Module
    Rack::MiniProfiler.subscribe_sql_active_record = patches.empty? && !patch_rails?
    patches
  end

  def self.other_patches
    patches = []
    patches
  end

  def self.all_patch_files
    env_var = ENV["RACK_MINI_PROFILER_PATCH"]
    return [] if env_var == "false"
    env_var ? env_var.split(",").map(&:strip) : sql_patches + other_patches
  end

  def self.patch(patch_files = all_patch_files)
    patch_files.each do |patch_file|
      require "patches/db/#{patch_file}"
    end
  end
end

SqlPatches.patch
