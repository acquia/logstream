require 'net/https'
require 'json'

module Logstream
    class CloudAPIV2
    class Error < StandardError; end

    attr_accessor :client_id, :client_secret, :endpoint
    CLOUDAPI_ENDPOINT = 'https://cloud.acquia.com/api'

    def initialize(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
    end
  
    def get(path)
      bearer_token = get_token
      uri = URI.parse("#{CLOUDAPI_ENDPOINT}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "Bearer #{bearer_token}"
      response = http.request(request)
      parsed = JSON.parse(response.body) rescue nil
      case response.code.to_i
      when 200
        raise Error, "Unexpected reply #{response.body}" unless parsed
        parsed
      else
        raise Error, "HTTP #{response.code}: #{response.body}"
      end
    end

    def get_application_environments(application_uuid)
      response = get("/applications/#{application_uuid}/environments") #, { :query => { "filter" => "name%3D#{env}"}})
      raise Error, "No Environments found." if response['total'] == 0
      raise Error, "Unexpected reply #{response}" unless response['_embedded']['items']
      response['_embedded']['items']
    end

    def get_envirornment_logstream(environment_uuid)
      response = get("/environments/#{environment_uuid}/logstream")
      raise Error, "Unexpected reply #{response}" unless response['logstream']
      response['logstream']
    end
  
    def get_token
      uri = URI.parse("https://accounts.acquia.com/api/auth/oauth/token")
      response = Net::HTTP.post_form(uri, 'client_id' => @client_id, 'client_secret' => @client_secret, 'grant_type' => 'client_credentials')
      parsed = JSON.parse(response.body) rescue nil
      case response.code.to_i
      when 200
        raise Error, "Unexpected reply #{response.body}" unless parsed["access_token"]
        parsed["access_token"]
      else
        raise Error, "HTTP #{response.code}: #{response.body}"
      end
    end
  end
end
