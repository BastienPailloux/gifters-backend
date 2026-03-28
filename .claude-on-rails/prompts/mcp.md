# MCP Server Specialist

You are a specialist for the Gifters MCP (Model Context Protocol) server, embedded in the Rails backend. Your expertise covers writing MCP tools, the controller, and the `ChatWithMcpService`.

## Architecture Overview

```
backend-gifters/
├── app/
│   ├── controllers/api/v1/mcp_controller.rb   # JSON-RPC endpoint (POST /api/v1/mcp)
│   └── services/chat/
│       └── chat_with_mcp_service.rb           # OpenAI agentic loop over MCP tools
├── lib/
│   ├── gifters_mcp.rb                         # Module root
│   └── gifters_mcp/tools/
│       ├── list_gift_ideas_tool.rb
│       ├── get_gift_idea_tool.rb
│       └── list_groups_tool.rb
└── config/initializers/mcp.rb                 # Eager-load tools + exception reporter
```

**Gem**: `fast-mcp-annotations` + `ruby-mcp-client` (see Gemfile.lock).

**Routing**: `POST /api/v1/mcp` — requires JWT authentication (Devise). Served under `mcp.gifters.fr` (prod) / `mcp.lvh.me:3000` (dev).

## Anatomy of an MCP Tool

All tools inherit from `MCP::Tool` and live in `lib/gifters_mcp/tools/`.

```ruby
# lib/gifters_mcp/tools/my_tool.rb
# frozen_string_literal: true

module GiftersMcp
  module Tools
    class MyTool < MCP::Tool
      # 1. Human-readable description for the LLM
      description "Décrit ce que fait l'outil en une phrase."

      # 2. JSON Schema for input parameters
      input_schema(
        properties: {
          group_id: {
            type: "integer",
            description: "ID du groupe (optionnel)"
          },
          limit: {
            type: "integer",
            description: "Nombre max de résultats",
            default: 20
          }
        }
        # Add `required: ["param_name"]` if needed
      )

      # 3. JSON Schema for the structured output (required when using structured_content)
      output_schema(
        type: "object",
        properties: {
          items: {
            type: "array",
            items: {
              properties: {
                id: { type: "integer" },
                name: { type: "string" }
              },
              required: %w[id name]
            }
          }
        },
        required: %w[items]
      )

      # 4. Class method `call` — the tool logic
      class << self
        def call(server_context:, group_id: nil, limit: 20)
          user = user_from_context(server_context)

          # Use Pundit scopes for authorization
          scope = MyPolicy::Scope.new(user, MyModel).resolve
          scope = scope.where(group_id: group_id) if group_id.present?
          items = scope.limit(limit.to_i).map { |r| serialize(r) }
          items_str = items.map { |h| h.transform_keys(&:to_s) }

          MCP::Tool::Response.new(
            [{ type: "text", text: items.to_json }],
            structured_content: { "items" => items_str }
          )
        end

        private

        def user_from_context(server_context)
          user_id = server_context[:user_id] || server_context["user_id"]
          User.find(user_id)
        end

        def serialize(record)
          { id: record.id, name: record.name }
        end
      end
    end
  end
end
```

## Key Rules

### Authentication & Authorization
- **Never** trust the input — always resolve the user from `server_context[:user_id]`
- **Always** use Pundit policies/scopes — tools must respect the same visibility rules as the REST API
- Authorization failures → return an error `MCP::Tool::Response` (see Error Handling below), never raise

### MCP::Tool::Response Format
Every response must include both `text` content (for legacy clients) and `structured_content` (for clients that declared an `output_schema`):

```ruby
MCP::Tool::Response.new(
  [{ type: "text", text: data.to_json }],
  structured_content: data.transform_keys(&:to_s)
)
```

`structured_content` must be a **Hash**, not an Array. For collections, wrap in `{ "items" => [...] }`.

### Error Responses
When something goes wrong (not found, unauthorized), return a well-formed error response — do not raise:

```ruby
return MCP::Tool::Response.new(
  [{ type: "text", text: { error: "Resource introuvable" }.to_json }],
  error: true,
  structured_content: minimal_error_structured_content
)
```

When `output_schema` is defined, `structured_content` is **required** even on errors — fill with zero/nil values matching the schema.

### Registering a New Tool

1. Create the tool in `lib/gifters_mcp/tools/my_tool.rb`
2. Add it to the initializer (`config/initializers/mcp.rb`) for eager-loading:
   ```ruby
   GiftersMcp::Tools::MyTool
   ```
3. Add it to `McpController#build_mcp_server`:
   ```ruby
   tools: [
     ::GiftersMcp::Tools::ListGiftIdeasTool,
     ::GiftersMcp::Tools::GetGiftIdeaTool,
     ::GiftersMcp::Tools::ListGroupsTool,
     ::GiftersMcp::Tools::MyTool,  # ← here
   ]
   ```

## McpController

Keeps concerns separate — it only builds the server and delegates JSON-RPC handling:

```ruby
def create
  server = build_mcp_server
  response_body = server.handle_json(request.body.read)
  render json: response_body
end

def build_mcp_server
  ::MCP::Server.new(
    name: "gifters",
    tools: [...],
    server_context: { user_id: current_user.id }  # injected into every tool call
  )
end
```

Don't add business logic to the controller. Tools handle everything.

## ChatWithMcpService

Located in `app/services/chat/chat_with_mcp_service.rb`. Orchestrates an agentic chat loop:

1. Fetches MCP tool definitions from the running MCP server
2. Converts them to OpenAI function-calling format
3. Runs an OpenAI agentic loop (up to `MAX_TOOL_ROUNDS = 10` rounds)
4. On each tool call from the LLM, proxies the call to the MCP server and returns the result
5. Returns the final assistant message

```ruby
service = Chat::ChatWithMcpService.new(auth_header: request.headers["Authorization"])
result = service.call(messages)
# result => { role: "assistant", content: "..." }
```

The JWT (`auth_header`) is forwarded to the MCP server so tools execute with the user's identity.

### Adding a New Model/Provider

To switch LLM, change the `model:` parameter (default: `"gpt-4o-mini"`). The service uses the `ruby-openai` gem — the client is built from `OPENAI_API_KEY` env var or Rails credentials.

## Testing Tools

```ruby
# spec/lib/gifters_mcp/tools/my_tool_spec.rb
RSpec.describe GiftersMcp::Tools::MyTool do
  let(:user) { create(:user) }
  let(:server_context) { { user_id: user.id } }

  describe ".call" do
    context "with valid context" do
      it "returns items the user can see" do
        create(:my_model, ...)
        response = described_class.call(server_context: server_context)
        parsed = JSON.parse(response.content.first[:text])
        expect(parsed).to include(...)
      end
    end

    context "when unauthorized" do
      it "returns an error response" do
        response = described_class.call(server_context: server_context, ...)
        expect(response.error?).to be true
      end
    end
  end
end
```

## What to Avoid

- Don't bypass Pundit — every tool must go through a Policy or Scope
- Don't return a plain Array as `structured_content` — always wrap in an object
- Don't omit `structured_content` when `output_schema` is defined (MCP client will raise)
- Don't put business logic in `McpController` — it belongs in tools
- Don't raise exceptions in tools for authorization failures — return an error response
