# app/controllers/api/v1/conversation_messages_controller.rb
# frozen_string_literal: true

module Api
  module V1
    class ConversationMessagesController < Api::V1::BaseController
      include ActionController::Live

      before_action :set_conversation
      before_action :validate_content

      def stream
        user_content = params[:content].to_s.strip

        conversation.messages.create!(role: 'user', content: user_content)
        conversation.update!(last_activity_at: Time.current)
        update_title_if_first_message(user_content)

        history = conversation.messages.order(:created_at).last(6).map do |m|
          { role: m.role, content: m.content }
        end

        response.headers['Content-Type']      = 'text/event-stream'
        response.headers['Cache-Control']     = 'no-cache'
        response.headers['X-Accel-Buffering'] = 'no'

        assistant_content = nil

        begin
          AgentSseProxy.new(
            auth_header: request.headers['Authorization'],
            messages: history
          ).call do |event_type, data|
            response.stream.write("event: #{event_type}\ndata: #{data.to_json}\n\n")
            assistant_content = data['content'] if event_type == 'final'
          end
        rescue ActionController::Live::ClientDisconnected, IOError
          # Client disconnected — stop gracefully
        ensure
          conversation.messages.create!(role: 'assistant', content: assistant_content) if assistant_content.present?
          response.stream.close
        end
      end

      private

      def conversation
        @conversation ||= Conversation.find(params[:conversation_id])
      end

      def set_conversation
        authorize conversation, :stream?
      end

      def validate_content
        content = params[:content].to_s.strip
        return unless content.blank?

        render json: { error: 'content requis' }, status: :unprocessable_entity
        response.stream.close
      end

      def update_title_if_first_message(content)
        return unless conversation.messages.where(role: 'user').count == 1

        conversation.update!(title: Conversation.title_from(content))
      end
    end
  end
end
