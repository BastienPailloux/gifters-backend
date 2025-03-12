# 🎁 Gifters Backend API

[![Ruby](https://img.shields.io/badge/Ruby-3.2.x-red)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1.x-red)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15.x-blue)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> The backend API for Gifters, an open-source application that helps you manage your gift ideas and events with friends and family.

## ✨ Features

- 🔐 Secure user authentication system with JWT
- 👥 Group and membership management
- 🎁 Gift ideas and wishlists management
- 📅 Events and reminders
- 🔍 Search and filtering capabilities
- 📊 RESTful API with comprehensive documentation
- 🧪 Extensive test coverage with RSpec

## 🚀 Getting Started

### Prerequisites

- Ruby 3.2.x
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

#### Docker Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/BastienPailloux/gifters-backend.git
   cd gifters-backend
   ```

2. Build and start the containers:
   ```bash
   docker-compose build
   docker-compose up
   ```

3. In a separate terminal, set up the database:
   ```bash
   docker-compose exec app bin/rails db:create db:migrate db:seed
   ```

### Development

Start the Rails server:

```bash
bin/rails server
# or with Docker
docker-compose up
```

The API will be available at http://localhost:3000.

### Testing

Run the test suite:

```bash
bin/rails spec
# or
bundle exec rspec
```

With Docker:
```bash
docker-compose exec app bin/rails spec
```

### API Documentation

We use Swagger for API documentation. After starting the server, you can access the documentation at:

```
http://localhost:3000/api-docs
```

## 🧩 Project Structure

```
backend-gifters/
├── app/                 # Application code
│   ├── controllers/     # Controllers
│   ├── models/          # Models
│   ├── services/        # Service objects
│   ├── serializers/     # JSON serializers
│   └── views/           # Views (for admin interface)
├── config/              # Configuration files
├── db/                  # Database migrations and seeds
├── lib/                 # Library code
├── public/              # Public files
├── spec/                # Tests
├── .env.example         # Example environment variables
└── Dockerfile           # Docker configuration
```

## 📝 Database Schema

Here's a simplified overview of our database schema:

```
users                # User accounts
  ├── groups         # Groups that users belong to
  ├── memberships    # User membership in groups
  ├── gift_ideas     # Gift ideas created by users
  ├── events         # Events created by users
  ├── wishlists      # User wishlists
  └── reservations   # Gift reservations
```

## 🛠️ Technologies

- **Ruby on Rails**: Web framework
- **PostgreSQL**: Database
- **JWT**: Authentication
- **RSpec**: Testing
- **Swagger**: API documentation
- **Docker**: Containerization
- **Puma**: Web server
- **Redis**: Caching (if used)
- **Sidekiq**: Background jobs (if used)

## 🔒 Security

- All endpoints requiring authentication are protected with JWT tokens
- CORS protection for API endpoints
- Rate limiting to prevent abuse
- SQL injection protection through ActiveRecord
- Regular security updates

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
- Write tests for all new features
- Follow the existing coding style
- Document new API endpoints
- Update API documentation when changing endpoints

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- [Ruby on Rails](https://rubyonrails.org/)
- [PostgreSQL](https://www.postgresql.org/)
- [RSpec](https://rspec.info/)
- [Swagger](https://swagger.io/)

## 📞 Contact

For any questions or suggestions, please open an issue on GitHub or contact the maintainers directly.
