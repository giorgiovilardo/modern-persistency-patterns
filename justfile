[private]
default:
    @just --list --unsorted

# Start and seed from scratch.
up:
    docker compose down --volumes --remove-orphans
    docker compose up -d --wait postgres
    @echo "ready: postgres://postgres:postgres@localhost:5432/pagila"

# Stop and discard the database.
down:
    docker compose down --volumes --remove-orphans
