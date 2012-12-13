# configures public url for our application
OmniAuth.config.full_host = Proc.new do |env|
  url = env["rack.session"]["omniauth.origin"] || env["omniauth.origin"] || ActionController::Base.config.relative_url_root

  #if no url found, fall back to config/app_config.yml addresses
  if url.blank?
    # crindt: this is from the redmine Admin=>Settings=>Hostname and Path
    url = 'http://'+Setting["host_name"]
  #else, parse it and remove both request_uri and query_string
  else
    OmniAuth.logger.send(:info, "(cas) FULL HOST SET #{url}")
    uri = URI.parse(url)
    url = "#{uri.scheme}://#{uri.host}"
    url << ":#{uri.port}" unless uri.default_port == uri.port
  end
  url
end
