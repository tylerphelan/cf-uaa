require 'cf/uaa/version'
require 'cf/uaa/client'

module CF
  module UAA
    def self.build_client(domain, client_id, client_secret, access_token: nil)
      client = CF::UAA::Client.new(domain)
      client.register_interceptor(BasicAuthenticator.new(client_id, client_secret))
      client.register_interceptor(AccessTokenAssigner.new(access_token))
      client
    end

    # TODO: Move this class to the oven gem
    class BasicAuthenticator
      attr_reader :username, :password

      def initialize(username, password)
        @username, @password = username, password
      end

      def before_request(uri, body, headers, options)
        if username && password
          headers['Authorization'] = 'Basic ' + ["#{username}:#{password}"].pack('m0')
        end

        [uri, body, headers, options]
      end
    end

    class AccessTokenAssigner
      attr_reader :access_token

      def initialize(access_token)
        @access_token = access_token
      end

      def before_request(uri, body, headers, options)
        headers['Authorization'] = "Bearer #{access_token}" if access_token

        [uri, body, headers, options]
      end
    end
  end
end
