RedmineApp::Application.routes.draw do
  match 'login_without_cas', :to => 'account#login_without_cas'
  match 'logout_without_cas', :to => 'account#logout_without_cas'
  match 'auth/:provider/callback', :to => 'account#login_with_omniauth'
  match 'auth/:provider', :to => 'account#blank'
end
