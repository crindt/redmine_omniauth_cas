# configures public url for our application
OmniAuth.config.full_host = Proc.new do |env|
  url = env["rack.session"]["omniauth.origin"] || env["omniauth.origin"]
  OmniAuth.logger.send(:info, "(cas) URL IS #{url}")
  OmniAuth.logger.send(:info, "(cas) ENVIRONMENT IS #{env}")

  # crindt: fixme: this is reverse engineered by examining env in logs
  if url.blank? && env["rack.url_scheme"] && env["HTTP_HOST"] && env["SCRIPT_NAME"]
    # try HOST_NAME etc.
    url = env["rack.url_scheme"]+"://"+env["HTTP_HOST"]+env["SCRIPT_NAME"]
    OmniAuth.logger.send(:info, "(cas) FORCED URL FROM ENV: #{url}")
  end

  #if no url found, fall back to config/app_config.yml addresses
  if url.blank?
    # crindt: this is from the redmine Admin=>Settings=>Hostname and Path
    OmniAuth.logger.send(:info, "(cas) URL IS BLANK, PULLING FROM Setting")
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
