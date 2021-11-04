module Standby
  class ConnectionHolder < ActiveRecord::Base
    self.abstract_class = true

    CONNECTION_NAME_MAP = {"StandbyStandbyConnectionHolder" => "ActiveRecord::Base", "StandbyStandbyUserdbConnectionHolder" => "MysqlRecord"}

    class << self
      # for delayed activation
      def activate(target)
        env_name = ActiveRecord::ConnectionHandling::RAILS_ENV.call
        spec = ActiveRecord::Base.configurations.configs_for(env_name: env_name, name: target.to_s, include_replicas: true)&.configuration_hash
        raise Error.new("Standby target '#{target}' is invalid!") if spec.nil?
        establish_connection spec
      end

      def name
        CONNECTION_NAME_MAP[super] || "ActiveRecord::Base"
      end
    end
  end

  class << self
    def connection_holder(target)
      klass_name = "Standby#{target.to_s.camelize}ConnectionHolder"
      standby_connections[klass_name] ||= begin
        klass = Class.new(Standby::ConnectionHolder) do
          self.abstract_class = true
        end
        Object.const_set(klass_name, klass)
        klass.activate(target)
        klass
      end
    end
  end
end
