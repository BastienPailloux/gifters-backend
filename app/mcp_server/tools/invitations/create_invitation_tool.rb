# frozen_string_literal: true

module Tools
  module Invitations
    class CreateInvitationTool < MCP::Tool
      description "Crée une invitation pour rejoindre un groupe et retourne l'URL à partager. Réservé aux admins."
      input_schema(
        properties: {
          group_id: { type: "integer", description: "ID du groupe" },
          role:     { type: "string",  description: "Rôle attribué : 'member' (défaut) ou 'admin'" }
        },
        required: %w[group_id]
      )
      output_schema(
        type: "object",
        properties: {
          id:              { type: "integer" },
          role:            { type: "string" },
          invitation_url:  { type: "string" },
          created_by_id:   { type: "integer" },
          created_by_name: { type: "string" }
        },
        required: %w[id role invitation_url created_by_id]
      )

      class << self
        def authorize!(user, params)
          group = GroupPolicy::Scope.new(user, Group).resolve.find_by(id: params[:group_id])
          return false unless group
          GroupPolicy.new(user, group).manage_invitations?
        end

        def call(server_context:, group_id:, role: nil)
          user  = user_from_context(server_context)
          group = Group.find_by(id: group_id)
          return error_response("Groupe introuvable") unless group

          safe_role  = Invitation::ROLES.include?(role) ? role : 'member'
          invitation = group.create_invitation(user, safe_role)

          unless invitation.persisted?
            return error_response(invitation.errors.full_messages.join(', '))
          end

          data = Serializers::InvitationSerializer.serialize(invitation).transform_keys(&:to_s)
          MCP::Tool::Response.new(
            [{ type: "text", text: data.to_json }],
            structured_content: data
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def error_response(message)
          MCP::Tool::Response.new(
            [{ type: "text", text: { error: message }.to_json }],
            error: true,
            structured_content: { "id" => 0, "role" => "member",
                                  "invitation_url" => "", "created_by_id" => 0 }
          )
        end
      end
    end
  end
end
