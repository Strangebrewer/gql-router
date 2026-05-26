# gql-router — Claude Context

## What This Is

The production Apollo Router for the personal-enterprise federated GraphQL layer. Config-only — no application code, no Node.js, no package.json. Just Apollo Router YAML config and CI/CD.

The local development equivalent is `gql-local-router`, which uses the same router binary but composes against localhost subgraphs.

---

## How It Works

### Schema composition
Rover introspects the live deployed subgraphs at CI time and composes `supergraph-schema.graphql`. This file is generated in each deploy job and baked into the Docker image — it is never committed to the repo.

`supergraph.yaml` contains `${SUBGRAPH_*_URL}` shell-style placeholders. CI uses `envsubst` to substitute the real Cloud Run base URLs (from the GitHub Environment) before passing the file to rover.

### Runtime routing
The composed schema has routing URLs baked in from composition time, but `override_subgraph_url` in `router.yaml` overrides those at runtime using `${env.SUBGRAPH_*_URL}` (Apollo Router's env var expansion syntax). The Cloud Run env vars injected at deploy time are the source of truth for actual routing.

This means:
- Schema shape (types, fields) comes from composition against live subgraphs in CI
- Routing destinations come from Cloud Run env vars at runtime

### GitHub Environment variables
Both `dev` and `prod` environments need these three variables (base URL, no trailing slash, no `/graphql`):
- `SUBGRAPH_HOME_MAINTENANCE_URL`
- `SUBGRAPH_RECIPES_URL`
- `SUBGRAPH_PROJECT_MGR_URL`

### Dockerfile
Two-stage build: downloads the Apollo Router Linux binary via the official Apollo script, then copies it alongside `router.yaml` and the composed `supergraph-schema.graphql` into a slim Debian runtime image.

---

## Key Files

| File | Purpose |
|---|---|
| `router.yaml` | Apollo Router config — CORS, introspection, header propagation, runtime URL overrides |
| `supergraph.yaml` | Rover composition config — URL placeholders substituted by `envsubst` in CI |
| `Dockerfile` | Downloads router binary; COPYs config + composed schema |
| `.github/workflows/ci.yml` | Installs rover, composes schema, builds image, deploys to Cloud Run |

`supergraph-schema.graphql` and `supergraph-resolved.yaml` are gitignored — both are generated in CI.

---

## Adding a New Subgraph

1. Add an entry to `supergraph.yaml` with the new subgraph's name and `${NEW_SUBGRAPH_URL}/graphql` for both `routing_url` and `subgraph_url`
2. Add `override_subgraph_url` entry to `router.yaml` using `${env.NEW_SUBGRAPH_URL}/graphql`
3. Add `NEW_SUBGRAPH_URL` to the `envsubst` and `--set-env-vars` steps in both deploy jobs in `ci.yml`
4. Add `NEW_SUBGRAPH_URL` to both `dev` and `prod` GitHub Environments
5. Add the new Firebase Hosting origin to the `cors.policies.origins` list in `router.yaml` if needed

---

## Updating the Schema

When a subgraph changes its SDL, redeploy the router — the CI compose step will pick up the new schema automatically on the next push to `dev` or `main`.

---

## CORS

`router.yaml` currently lists the four dev Firebase Hosting origins. Add prod origins when deploying to prod:
- `https://pe-shell.web.app`
- `https://pe-mfe-dashboard.web.app`
- `https://pe-mfe-job-search.web.app`
- `https://pe-mfe-budget.web.app`

(Verify these names before adding — prod Firebase project IDs were not confirmed at time of writing.)

---

## Current State

- Deployed to dev and working
- `prod` GitHub Environment needs the three subgraph URL vars once prod subgraphs are deployed
- Prod CORS origins need to be confirmed and added to `router.yaml` before prod deploy
