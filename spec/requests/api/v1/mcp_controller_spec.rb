# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V1::McpController", type: :request do
  let(:user) { create(:user) }
  let(:headers) do
    auth_headers(user).merge('HOST' => 'mcp.lvh.me')
  end

  # A tool class that does NOT respond to authorize!
  let(:tool_without_authorize) { Tools::GiftIdeas::ListGiftIdeasTool }

  # The tool name as the MCP gem derives it
  let(:tool_without_authorize_name) { tool_without_authorize.tool_name }

  describe "POST / (tools/call authorization)" do
    context "when the JSON body is invalid" do
      it "does not raise and lets the server handle the error" do
        post "/", params: "not valid json", headers: headers.merge('CONTENT_TYPE' => 'text/plain')
        # authorize_tool_call! returns early on JSON::ParserError; the MCP server will handle it
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context "when the method is not tools/call" do
      let(:body) do
        { jsonrpc: "2.0", method: "tools/list", id: 1 }.to_json
      end

      it "passes through without 403" do
        post "/", params: body, headers: headers.merge('CONTENT_TYPE' => 'application/json')
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    context "when the tool does not have an authorize! method" do
      let(:body) do
        {
          jsonrpc: "2.0",
          method: "tools/call",
          id: 1,
          params: { name: tool_without_authorize_name, arguments: {} }
        }.to_json
      end

      it "passes through without 403" do
        post "/", params: body, headers: headers.merge('CONTENT_TYPE' => 'application/json')
        expect(response).not_to have_http_status(:forbidden)
      end
    end

    # These contexts test the authorize! flow using a tool that has the method stubbed.
    # We use without_partial_double_verification because authorize! is a future extension
    # point not yet defined on any tool class.
    context "when the tool has authorize! returning true" do
      let(:tool_klass) { Tools::GiftIdeas::DeleteGiftIdeaTool }

      before do
        RSpec::Mocks.with_temporary_scope do
          without_partial_double_verification do
            allow(tool_klass).to receive(:respond_to?).and_call_original
            allow(tool_klass).to receive(:respond_to?).with(:authorize!).and_return(true)
            allow(tool_klass).to receive(:authorize!).and_return(true)
          end
        end
      end

      let(:body) do
        {
          jsonrpc: "2.0",
          method: "tools/call",
          id: 1,
          params: { name: tool_klass.tool_name, arguments: { id: 1 } }
        }.to_json
      end

      it "passes through without 403" do
        without_partial_double_verification do
          allow(tool_klass).to receive(:respond_to?).and_call_original
          allow(tool_klass).to receive(:respond_to?).with(:authorize!).and_return(true)
          allow(tool_klass).to receive(:authorize!).and_return(true)
          post "/", params: body, headers: headers.merge('CONTENT_TYPE' => 'application/json')
          expect(response).not_to have_http_status(:forbidden)
        end
      end
    end

    context "when the tool has authorize! returning false" do
      let(:tool_klass) { Tools::GiftIdeas::DeleteGiftIdeaTool }

      let(:body) do
        {
          jsonrpc: "2.0",
          method: "tools/call",
          id: 42,
          params: { name: tool_klass.tool_name, arguments: { id: 1 } }
        }.to_json
      end

      it "returns 403 Forbidden" do
        without_partial_double_verification do
          allow(tool_klass).to receive(:respond_to?).and_call_original
          allow(tool_klass).to receive(:respond_to?).with(:authorize!).and_return(true)
          allow(tool_klass).to receive(:authorize!).and_return(false)
          post "/", params: body, headers: headers.merge('CONTENT_TYPE' => 'application/json')
          expect(response).to have_http_status(:forbidden)
        end
      end

      it "returns a JSON-RPC error response" do
        without_partial_double_verification do
          allow(tool_klass).to receive(:respond_to?).and_call_original
          allow(tool_klass).to receive(:respond_to?).with(:authorize!).and_return(true)
          allow(tool_klass).to receive(:authorize!).and_return(false)
          post "/", params: body, headers: headers.merge('CONTENT_TYPE' => 'application/json')
          json = JSON.parse(response.body)
          expect(json["jsonrpc"]).to eq("2.0")
          expect(json["error"]["code"]).to eq(4003)
          expect(json["error"]["message"]).to eq("Forbidden")
          expect(json["id"]).to eq(42)
        end
      end

      it "uses 0 as fallback id when request has no id" do
        body_no_id = {
          jsonrpc: "2.0",
          method: "tools/call",
          params: { name: tool_klass.tool_name, arguments: { id: 1 } }
        }.to_json
        without_partial_double_verification do
          allow(tool_klass).to receive(:respond_to?).and_call_original
          allow(tool_klass).to receive(:respond_to?).with(:authorize!).and_return(true)
          allow(tool_klass).to receive(:authorize!).and_return(false)
          post "/", params: body_no_id, headers: headers.merge('CONTENT_TYPE' => 'application/json')
          json = JSON.parse(response.body)
          expect(json["id"]).to eq(0)
        end
      end
    end
  end
end
