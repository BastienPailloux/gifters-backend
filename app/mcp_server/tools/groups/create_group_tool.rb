# frozen_string_literal: true

module Tools
  module Groups
    class CreateGroupTool < MCP::Tool
      description "Crée un nouveau groupe. Le créateur est automatiquement ajouté comme admin."
      input_schema(
        properties: {
          name: { type: "string", description: "Nom du groupe" }
        },
        required: %w[name]
      )
      output_schema(
        type: "object",
        properties: {
          id:                { type: "integer" },
          name:              { type: "string" },
          members_count:     { type: "integer" },
          current_user_role: { type: "string" },
          members:           { type: "array", items: { type: "object" } },
          invitations:       { type: "array", items: { type: "object" } }
        },
        required: %w[id name members_count current_user_role members invitations]
      )

      class << self
        def authorize!(_user, _params) = true

        def call(server_context:, name:)
          user  = user_from_context(server_context)
          group = Group.new(name: name)
          group.creator = user

          unless group.save
            message = group.errors.full_messages.join(', ')
            return error_response(message)
          end

          group.add_user(user, 'admin')
          data = Serializers::GroupSerializer.serialize_full(group, user)
                                             .transform_keys(&:to_s)
          data["members"]     = data["members"].map { |m| m.transform_keys(&:to_s) }
          data["invitations"] = data["invitations"].map { |i| i.transform_keys(&:to_s) }

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
            structured_content: { "id" => 0, "name" => message, "members_count" => 0,
                                  "current_user_role" => nil, "members" => [], "invitations" => [] }
          )
        end
      end
    end
  end
end
