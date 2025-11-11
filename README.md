# 🎁 Gifters Backend API

[![Ruby](https://img.shields.io/badge/Ruby-3.4.2-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0.3-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.x-blue)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI Status](https://github.com/BastienPailloux/gifters/actions/workflows/rails-ci.yml/badge.svg)](https://github.com/BastienPailloux/gifters/actions/workflows/rails-ci.yml)
[![Maintainability](https://img.shields.io/badge/Maintainability-A-brightgreen)](https://codeclimate.com)
[![Test Coverage](https://img.shields.io/badge/Coverage-87.8%25-brightgreen)](https://codecov.io)

> The backend API for Gifters, an open-source application that helps you manage your gift ideas and events with friends and family.
> The project is still on going, not all functionnalities are implemented or are susceptible of changes

## ✨ Features

- 🔐 Secure user authentication system with JWT
- 👥 Group and membership management - DONE
- 🎁 Gift ideas and wishlists management - DONE
- 👶 Managed accounts (children/dependents) - ONGOING
- 📅 Events and reminders - NOT YET STARTED
- 🔍 Search and filtering capabilities - NOT YET STARTED
- 📊 RESTful API with comprehensive documentation
- 🧪 Extensive test coverage with RSpec
- 🚀 CI/CD pipeline with GitHub Actions

## 🚀 Getting Started

### Prerequisites

- Ruby 3.4.x
- PostgreSQL 15.x+
- Bundler
- (Optional) Docker & Docker Compose for containerized setup

### Installation

#### Standard Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/BastienPailloux/gifters-backend.git
   cd gifters-backend
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   ```
   Edit the `.env` file to include your database credentials and other required configuration.

4. Setup the database:
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

### Development

Start the Rails server:

```bash
bin/rails server
```

The API will be available at http://localhost:3000.

### Testing

Run the test suite:

```bash
bin/rails spec
# or
bundle exec rspec

# Run tests with coverage report
COVERAGE=true bundle exec rspec
```

### API Documentation

NOT YET IMPLEMENTED
We will use Swagger for API documentation. After starting the server, you can access the documentation at:

```
http://localhost:3000/api-docs
```

## 🧩 Project Structure

```
backend-gifters/
├── app/                        # Application code
│   ├── controllers/            # API controllers
│   │   └── api/v1/            # API v1 endpoints
│   │       ├── groups_controller.rb
│   │       ├── children_controller.rb
│   │       └── ...
│   ├── models/                # Models
│   │   ├── concerns/          # Reusable model concerns
│   │   │   └── childrenable.rb
│   │   ├── user.rb
│   │   ├── group.rb
│   │   └── ...
│   ├── policies/              # Pundit authorization policies
│   │   ├── concerns/          # Reusable policy concerns
│   │   │   └── child_authorization.rb
│   │   ├── application_policy.rb
│   │   ├── group_policy.rb
│   │   ├── gift_idea_policy.rb
│   │   └── ...
│   ├── services/              # Service objects
│   ├── serializers/           # ActiveModel Serializers
│   └── views/                 # Jbuilder views
│       └── api/v1/groups/    # Group JSON templates
│           ├── _group.json.jbuilder    # Reusable partial
│           ├── index.json.jbuilder     # List/Hierarchical view
│           ├── show.json.jbuilder      # Detail view
│           ├── create.json.jbuilder    # Create response
│           └── update.json.jbuilder    # Update response
├── config/                    # Configuration files
├── db/                        # Database migrations and seeds
│   └── migrate/              # Migration files
│       ├── *_add_parent_and_account_type_to_users.rb
│       └── *_allow_nil_email_in_user.rb
├── lib/                       # Library code
├── spec/                      # RSpec tests (638+ examples)
│   ├── models/               # Model tests
│   │   ├── concerns/         # Concern tests
│   │   │   └── childrenable_spec.rb
│   │   └── user_spec.rb
│   ├── policies/             # Policy tests
│   │   ├── group_policy_spec.rb
│   │   ├── gift_idea_policy_spec.rb
│   │   └── ...
│   ├── requests/             # Request/Integration tests
│   │   └── api/v1/
│   │       ├── groups_spec.rb
│   │       └── children_spec.rb
│   └── views/                # View/Jbuilder tests
│       └── api/v1/groups/
│           ├── _group.json.jbuilder_spec.rb
│           ├── index.json.jbuilder_spec.rb
│           └── ...
└── .env.example              # Example environment variables
```

## 📝 Database Schema

Here's a simplified overview of our database schema:

```
users                # User accounts
  ├── parent_id      # Reference to parent user (for managed accounts)
  ├── account_type   # 'standard' or 'managed'
  ├── groups         # Groups that users belong to
  ├── memberships    # User membership in groups
  ├── gift_ideas     # Gift ideas created by users
  ├── events         # Events created by users
  ├── invitations    # Invitations to join a Group
  └── children       # Child (managed) accounts
```

## 🛠️ Technologies

### Core Stack
- **Ruby 3.4.2**: Programming language
- **Rails 8.0.3**: Web framework
- **PostgreSQL 15.x**: Database
- **Puma**: Web server

### Authentication & Security
- **JWT (JSON Web Tokens)**: Stateless authentication
- **Devise**: User authentication framework
- **Devise-JWT**: JWT integration for Devise
- **Pundit**: Authorization framework for fine-grained access control

### API & Views
- **Jbuilder**: JSON template engine for API responses
- **ActiveModel::Serializers**: JSON serialization
- **CORS**: Cross-Origin Resource Sharing support

### Testing & Quality
- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **SimpleCov**: Code coverage analysis
- **Shoulda Matchers**: RSpec matchers for common use cases
- **Pundit Matchers**: RSpec matchers for testing authorization policies

### Development Tools
- **RuboCop**: Ruby code analyzer and formatter
- **Brakeman**: Security vulnerability scanner
- **Bundle Audit**: Gem vulnerability checker

## 🔄 CI/CD

Ce projet utilise un pipeline CI/CD complet via GitHub Actions pour automatiser le processus de test, build.

### ✅ Intégration Continue (CI)

Le workflow CI (`rails-ci.yml`) s'exécute à chaque push sur les branches principales ou lors de pull requests pour garantir la qualité du code :

- **Tests automatisés** : Exécution de la suite de tests RSpec complète
- **Analyse de code** : Vérification du style de code avec RuboCop
- **Scans de sécurité** : Analyse via Brakeman et Bundle Audit
- **Couverture de tests** : Génération de rapports de couverture avec SimpleCov


### 🔧 Maintenance automatisée

- **Dependabot** : Mises à jour automatiques des dépendances via des pull requests
- **Tests de pull requests** : Vérification automatique des nouvelles contributions

## 🔒 Security

- **Authentication**: JWT tokens pour tous les endpoints protégés
- **Authorization**: Pundit policies pour contrôle d'accès fin-grain
- **CORS**: Protection contre les requêtes cross-origin non autorisées
- **Rate limiting**: Protection contre les abus
- **SQL injection**: Protection via ActiveRecord
- **XSS**: Protection automatique Rails
- **Regular updates**: Mises à jour de sécurité via Dependabot

## 🤝 Contributing

We welcome contributions to Gifters Backend! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

Please make sure to update tests as appropriate and follow our code style.

### Development Guidelines

- Follow Ruby and Rails best practices
- Write tests for all new features (models, controllers, views)
- Follow the existing coding style
- Document new API endpoints
- Update API documentation when changing endpoints
- Use Jbuilder views for JSON responses (separation of concerns)
- Extract reusable logic into concerns
- Ensure test coverage remains above 85%

## 🏗️ Architecture & Design Patterns

### Concerns
We use Rails Concerns to encapsulate reusable logic:
- Self-referencing associations
- Scopes and helper methods
- Can be included in any model needing parent-child functionality

### Jbuilder Views
API responses are rendered using Jbuilder templates:
- **Separation of concerns**: Presentation logic separate from controllers
- **Reusable partials**: DRY principle with shared templates
- **Hierarchical data**: Easy nested JSON structures
- **Performance**: Optimized eager loading

### Testing Strategy
- **Model tests**: Validations, associations, methods
- **Policy tests**: Authorization rules avec `pundit-matchers`
- **Controller tests**: Request specs for API endpoints
- **View tests**: Jbuilder template rendering
- **Integration tests**: End-to-end user flows

### Performance Optimizations
- **Eager loading**: `.includes()` to prevent N+1 queries
- **Scopes**: Database-level filtering
- **Policy scopes**: Nombre fixe de requêtes (pas de N+1)
- **Authorization caching**: Queries optimisées pour relations parent-enfant
- **Partial caching**: Future implementation for frequently accessed data

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- [Ruby on Rails](https://rubyonrails.org/)
- [PostgreSQL](https://www.postgresql.org/)
- [RSpec](https://rspec.info/)

## 📞 Contact

For any questions or suggestions, please open an issue on GitHub or contact the maintainers directly.
