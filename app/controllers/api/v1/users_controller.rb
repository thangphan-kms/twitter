module Api
  module V1
    class UsersController < BaseController
      # before_action :authorize, except: [:public]

      def create
        # TODO: get users credentials and check if the database exists this one or not
        render json: { access_token: Auth0Client.generate_token }
      end
    end
  end
end
