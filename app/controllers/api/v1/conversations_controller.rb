# frozen_string_literal: true

module Api
  module V1
    class ConversationsController < Api::V1::BaseController
      before_action :set_conversation, only: [:show]

      def index
        @conversations = policy_scope(Conversation).recent
      end

      def create
        @conversation = current_user.conversations.create!(
          title: 'Nouvelle conversation',
          last_activity_at: Time.current
        )
        render :create, status: :created
      end

      def show; end

      private

      def set_conversation
        @conversation = Conversation.find(params[:id])
        authorize @conversation
      end
    end
  end
end
