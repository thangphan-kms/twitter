# frozen_string_literal: true

module Api
  module V1
    class MessagesController < BaseController
      before_action :authorize, except: [:public]

      def index
        render json: { message: 'hello' }
      end

      def admin
        render json: { message: 'Admin message' }
      end

      def protected
        render json: { message: 'Protected message' }
      end

      def public
        render json: { message: 'Public message' }
      end
    end
  end
end
