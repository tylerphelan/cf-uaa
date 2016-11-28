require 'json'
require 'delegate'

class CF::UAA::Client
  class JsonResponse < DelegateClass(Net::HTTPResponse)
    alias headers to_hash
    HAS_SYMBOL_GC = RUBY_VERSION > '2.2.0'

    def json
      parsable? ? JSON.parse(body, symbolize_names: HAS_SYMBOL_GC) : nil
    end

    private

    def parsable?
      !!body
    end
  end

  class JsonSerializer
    APPLICATION_JSON     = 'application/json'.freeze
    JSON_REQUEST_HEADERS = {
      'Content-Type' => APPLICATION_JSON,
      'Accept'       => APPLICATION_JSON
    }.freeze

    def before_request(uri, body, headers, options)
      if body.nil?
        [uri, body, headers, options]
      elsif uri.path == '/oauth/token'
        [uri, URI.encode_www_form(body), headers, options]
      else
        [uri, JSON.dump(body), headers.merge(JSON_REQUEST_HEADERS), options]
      end
    end
  end

  class JsonDeserializer
    def received_response(response)
      JsonResponse.new(response)
    end
  end

  private_constant :JsonSerializer, :JsonDeserializer
end
