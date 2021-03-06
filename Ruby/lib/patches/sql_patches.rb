class SqlPatches

  def self.patched?
    @patched
  end

  def self.patched=(val)
    @patched = val
  end

	def self.class_exists?(name)
		eval(name + ".class").to_s.eql?('Class')
	rescue NameError
		false
	end
	
  def self.module_exists?(name)
		eval(name + ".class").to_s.eql?('Module')
	rescue NameError
		false
	end
end

## based off https://github.com/newrelic/rpm/blob/master/lib/new_relic/agent/instrumentation/active_record.rb
## fallback for alls sorts of weird dbs
if SqlPatches.module_exists?('ActiveRecord') && !SqlPatches.patched?
  module Rack
    class MiniProfiler  
      module ActiveRecordInstrumentation
        def self.included(instrumented_class)
          instrumented_class.class_eval do
            unless instrumented_class.method_defined?(:log_without_miniprofiler)
              alias_method :log_without_miniprofiler, :log
              alias_method :log, :log_with_miniprofiler
              protected :log
            end
          end
        end

        def log_with_miniprofiler(*args, &block)
          current = ::Rack::MiniProfiler.current
          return log_without_miniprofiler(*args, &block) unless current

          sql, name, binds = args
          t0 = Time.now
          rval = log_without_miniprofiler(*args, &block)
          
          # Don't log schema queries if the option is set
          return rval if Rack::MiniProfiler.config.skip_schema_queries and name =~ /SCHEMA/

          elapsed_time = ((Time.now - t0).to_f * 1000).round(1)
          Rack::MiniProfiler.record_sql(sql, elapsed_time)
          rval
        end
      end
    end

    def self.insert_instrumentation 
      ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
        include ::Rack::MiniProfiler::ActiveRecordInstrumentation
      end
    end

    if defined?(::Rails) && !SqlPatches.patched?
      insert_instrumentation
    end
  end
end
