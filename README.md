# gql-router

Production Apollo Router for the personal-enterprise federated GraphQL layer. Composes three NestJS subgraphs (`gql-home-maintenance`, `gql-recipes`, `gql-project-mgr`) into a single GraphQL API deployed on Cloud Run.

Config-only — no application code. Apollo Router is downloaded as a binary at Docker build time.

---

## Architecture

```
Client
  └── gql-router (Apollo Router, Cloud Run)
        ├── gql-home-maintenance (NestJS subgraph, Cloud Run)
        ├── gql-recipes          (NestJS subgraph, Cloud Run)
        └── gql-project-mgr     (NestJS subgraph, Cloud Run)
```

For local development, use `gql-local-router` — it composes against localhost subgraphs and includes scripts to start the full local stack.

---

## How CI/CD Works

Each deploy job:
1. Installs rover CLI
2. Substitutes real Cloud Run URLs into `supergraph.yaml` via `envsubst`
3. Runs `rover supergraph compose` — introspects live subgraphs, produces `supergraph-schema.graphql`
4. Builds Docker image with the composed schema baked in
5. Deploys to Cloud Run with subgraph base URLs injected as env vars

At runtime, `router.yaml`'s `override_subgraph_url` config uses those env vars to route requests to the correct subgraphs, regardless of what URLs were baked into the schema at compose time.

---

## Configuration

### `router.yaml`
- Listens on `$PORT` (injected by Cloud Run)
- Introspection and Apollo Sandbox enabled
- CORS configured for Firebase Hosting frontend origins
- Propagates `Authorization` header to all subgraphs
- `override_subgraph_url` for runtime subgraph routing

### `supergraph.yaml`
Rover composition config. Contains `${SUBGRAPH_*_URL}` placeholders — not used directly, only via `envsubst` in CI.

---

## Environment Variables

Injected by Cloud Run at deploy time (set in GitHub Environments):

| Variable | Description |
|---|---|
| `SUBGRAPH_HOME_MAINTENANCE_URL` | Base Cloud Run URL for `gql-home-maintenance` |
| `SUBGRAPH_RECIPES_URL` | Base Cloud Run URL for `gql-recipes` |
| `SUBGRAPH_PROJECT_MGR_URL` | Base Cloud Run URL for `gql-project-mgr` |

Values are base URLs without a trailing slash or `/graphql` path (e.g. `https://gql-home-maintenance-dev-xxx.us-central1.run.app`).

---

## Adding a New Subgraph

See `CLAUDE.md` for the full checklist.
