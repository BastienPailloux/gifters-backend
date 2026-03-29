# ClaudeOnRails Context

This project uses ClaudeOnRails with a swarm of specialized agents for Rails development.

## Project Information
- **Rails Version**: 8.0.3
- **Ruby Version**: 3.4.2
- **Project Type**: API-only
- **Test Framework**: RSpec

## Swarm Configuration

The claude-swarm.yml file defines specialized agents for different aspects of Rails development:
- Each agent has specific expertise and works in designated directories
- Agents collaborate to implement features across all layers
- The architect agent coordinates the team

## Key Models

- `User` — `account_type: standard | managed`, lié via `parent_id` pour les comptes enfants
- `GiftIdea` — statuts `proposed → buying → bought`, avec `created_by`, `buyer`, `recipients` (via `GiftRecipient`)
- `Group` / `Membership` / `Invitation`
- `Conversation` — conversation IA, `belongs_to :user`, `title` auto-généré via `Conversation.title_from(text)`, scope `recent`
- `Message` — `belongs_to :conversation`, `role: user | assistant`

## Chat IA — Architecture critique

**Le frontend ne doit JAMAIS appeler agent-gifters directement.**
Flux obligatoire : `Frontend → POST /api/v1/conversations/:id/messages/stream → AgentSseProxy → agent-gifters`

- `AgentSseProxy` (`app/services/agent_sse_proxy.rb`) : proxy Net::HTTP streaming SSE, normalise `\r\n` → `\n`, utilise `String.new` (frozen_string_literal safe)
- `ConversationMessagesController#stream` : `include ActionController::Live`, autorise via `ConversationPolicy#stream?`, persiste les messages user/assistant
- Variable d'env : `AGENT_URL=http://localhost:8000`

## MCP Tools — Gift Ideas Write

Les tools MCP sont dans `lib/gifters_mcp/tools/`. Nouveaux tools d'écriture :

- `SearchGiftIdeasTool` — recherche sémantique via pgvector + `MistralEmbeddingService`
- `CreateGiftIdeaTool` — crée un `GiftIdea` avec recipients
- `UpdateGiftIdeaTool` — met à jour titre/description/prix d'un cadeau
- `DeleteGiftIdeaTool` — supprime un cadeau (status `proposed` uniquement)
- `MarkAsBuyingTool` — passe un cadeau au statut `buying`
- `MarkAsBoughtTool` — passe un cadeau au statut `bought`
- `CancelPurchaseTool` — annule un achat (repasse en `proposed`)

### Services et concerns clés

- `MistralEmbeddingService` (`app/services/mistral_embedding_service.rb`) — appelle l'API Mistral pour générer des embeddings vectoriels
- `Backgroundable` (`app/models/concerns/backgroundable.rb`) — concern permettant d'exécuter des méthodes en arrière-plan via ActiveJob
- `BackgroundMethodJob` (`app/jobs/background_method_job.rb`) — job générique qui invoque une méthode sur un modèle en arrière-plan
- Les embeddings sont stockés dans `gift_ideas.embedding` (colonne pgvector), générés automatiquement après `create`/`update`

## Development Guidelines

When working on this project:
- Follow Rails conventions and best practices
- Write tests for all new functionality (TDD: red → green → refactor)
- Use strong parameters in controllers
- Keep models focused with single responsibilities
- Extract complex business logic to service objects
- Ensure proper database indexing for foreign keys and queries
- `# frozen_string_literal: true` est présent sur tous les fichiers — utiliser `String.new` pour les buffers mutables