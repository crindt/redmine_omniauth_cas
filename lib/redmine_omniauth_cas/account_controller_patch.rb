require_dependency 'account_controller'

module Redmine::OmniAuthCAS
  module AccountControllerPatch

    # following the pattern here to override AccountController login method
    # http://stackoverflow.com/questions/2278031/wrapping-class-method-via-alias-method-chain-in-plugin-for-redmine
    def self.included(base)
      base.send(:include, ClassMethods)
      base.class_eval do
        # alias_method_chain calls rename log(in|out) to log(in|out)_without_cas
        # and points log(in|out) to log(in|out)_with_cas.  log(in|out)_with_cas
        # implemented below
        alias_method_chain :login, :cas    
        alias_method_chain :logout, :cas   
      end
    end

    # implementations of (login|logout)_with_cas
    module ClassMethods

      # This will force CAS authentication using OmniAuth
      def login_with_cas
        redirect_to ( ActionController::Base.config.relative_url_root || '' ) + '/auth/cas'
      end

      # This will logout the user from redmine AND force CAS logout 
      def logout_with_cas
        logout_user
        redirect_to cas_url+"/logout?service=#{full_host}"
      end
    end

    # handler for CAS callback (see config/routes.rb)
    def login_with_omniauth
      auth = request.env["omniauth.auth"]
      #user = User.find_by_provider_and_uid(auth["provider"], auth["uid"])
      user = User.find_by_login(auth["uid"]) || User.find_by_mail(auth["uid"])

      # taken from original AccountController
      # maybe it should be splitted in core
      if user.blank?
        invalid_credentials
        error = l(:notice_account_invalid_creditentials)
        if cas_url.present?
          link = self.class.helpers.link_to(l(:text_logout_from_cas), cas_url+"/logout", :target => "_blank")
          error << ". #{l(:text_full_logout_proposal, :value => link)}"
        end
        flash[:error] = error
        redirect_to signin_url
      else
        successful_authentication(user)
      end
    end

    def blank
      render :text => "Not Found", :status => 404
    end

    private
    def cas_url
      Redmine::OmniAuthCAS.cas_server
    end

    # from OmniAuth::Strategy, required for logout redirect.  crindt:FIXME: consider parameterizing the redirect host
    private
    def full_host
      case OmniAuth.config.full_host
        when String
          OmniAuth.config.full_host
        when Proc
          OmniAuth.config.full_host.call(env)
        else
          uri = URI.parse(request.url.gsub(/\?.*$/,''))
          uri.path = ''
          uri.query = nil
          #sometimes the url is actually showing http inside rails because the other layers (like nginx) have handled the ssl termination.
          uri.scheme = 'https' if(request.env['HTTP_X_FORWARDED_PROTO'] == 'https')          
          uri.to_s
      end
    end

  end
end
AccountController.send(:include, Redmine::OmniAuthCAS::AccountControllerPatch)
