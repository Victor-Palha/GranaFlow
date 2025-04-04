# GranaFlow

GranaFlow is a smart finance management **API** designed for individuals and businesses. It enables users to track expenses, set budgets, and gain actionable financial insights with ease. Built with Elixir and Phoenix, GranaFlow is optimized for performance, scalability, and reliability.

---

## Features

- **Expense Tracking**: Monitor and categorize your expenses in real-time.
- **Budget Management**: Set budgets and receive alerts when nearing limits.
- **Financial Insights**: Gain insights into spending patterns and trends.
- **User Authentication**: Secure login with OAuth (Google integration).
- **File Uploads**: Upload and manage files with R2-compatible storage.
- **Premium Features**: Access advanced tools with premium subscriptions.

---

## Installation

To set up and run the GranaFlow API locally, follow these steps:

### Prerequisites

- **Elixir**: Version `~> 1.14`
- **Docker**: Installed and running
- **Node.js**: Required for asset compilation
- **PostgreSQL**: Database for storing application data

### Steps

1. Clone the repository:

2. Install dependencies and set up the project:
   ```bash
   mix setup
   ```

3. Start the required services using Docker:
   ```bash
   docker compose up -d
   ```

4. Create an `.env` file based on the provided `.env.example`:
   ```bash
   cp .env.example .env
   ```

5. Start the Phoenix server:
   ```bash
   ./run.sh
   ```

6. Access the application at [`http://localhost:4000`](http://localhost:4000).

---

## Configuration

### Environment Variables

The application relies on the following environment variables:

- **Authentication**:
  - `GOOGLE_CLIENT_ID`: Google OAuth client ID
  - `GOOGLE_CLIENT_SECRET`: Google OAuth client secret
  - `GUARDIAN_SECRET_KEY`: Secret key for token generation

- **Storage**:
  - `R2_ACCESS_KEY`: Access key for R2-compatible storage
  - `R2_SECRET_KEY`: Secret key for R2-compatible storage
  - `R2_ENDPOINT_URL`: Endpoint URL for R2-compatible storage

- **Other**:
  - `DNS_CLUSTER_QUERY`: DNS query for clustering
  - `MP_ACCESS_TOKEN`: Access token for payment services

### Configuration Files

- **`config/config.exs`**: General application configuration.
- **`config/runtime.exs`**: Runtime-specific configurations.
- **`fly.toml`**: Deployment configuration for Fly.io.

---

## Deployment

GranaFlow is configured for deployment on [Fly.io](https://fly.io). To deploy:

1. Install the Fly CLI:
   ```bash
   brew install flyctl
   ```

2. Authenticate with Fly:
   ```bash
   fly auth login
   ```

3. Deploy the application:
   ```bash
   fly deploy
   ```

---

## Development

### Running Tests

To run the test suite:

```bash
mix test
```

### Code Formatting

Ensure consistent code formatting:

```bash
mix format
```

### Linting

Run static analysis with Credo:

```bash
mix credo
```

---

## Contributing

We welcome contributions! To contribute:

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add feature description"
   ```
4. Push to your fork:
   ```bash
   git push origin feature-name
   ```
5. Open a pull request.

---

## License

GranaFlow is licensed under the [MIT License](LICENSE).

---

## Acknowledgments

- Built with [Phoenix Framework](https://www.phoenixframework.org/).
- File uploads powered by [ExAws](https://hexdocs.pm/ex_aws/ExAws.html).
- Authentication via [Ueberauth](https://hexdocs.pm/ueberauth/readme.html).

For more information, visit our [documentation](https://your-docs-url.com).