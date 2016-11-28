Oven.bake :'CF::UAA::Client', destination: 'lib/' do
  format :json

  post :token, '/oauth/token'
  get :authorize, '/oauth/authorize', as: :authorize

  get :userinfo, '/userinfo'
  get :users,    '/Users'
  get :user,     '/Users/:id'

  post :autologin, '/autologin', as: :autologin
end
