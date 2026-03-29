# frozen_string_literal: true

module Api
  module V1
    # Chat avec un assistant IA qui s'appuie sur le serveur MCP (idées de cadeaux, groupes).
    class ChatController < Api::V1::BaseController
      def create
        messages = params[:messages] || []
        if messages.empty?
          return render json: { error: "messages requis" }, status: :unprocessable_entity
        end

        result = Chat::ChatWithMcpService.new(
          auth_header: request.headers["Authorization"],
          model: ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini")
        ).call(messages)

        render json: { message: result }
      end
    end
  end
end
