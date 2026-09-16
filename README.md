# modern-persistency-patterns

Database techniques demoed against a schema with enough in it to be worth the
trouble: [Pagila](https://github.com/devrimgunduz/pagila) on PostgreSQL 18 in
Docker.

## Quick start

Requires [Docker](https://docs.docker.com/get-docker/) and
[just](https://github.com/casey/just).

```sh
just up      # build, start, seed from scratch (~1 min)
just down    # stop and discard the data
```

There is no volume: every `just up` gives a virgin database.

```sh
docker compose exec postgres psql -U postgres -d pagila
```

From the host: `postgres://postgres:postgres@localhost:5432/pagila`.

## The dataset

Films are rented from stores by customers and paid for; `address` → `city` →
`country` sits behind customers, staff and stores. Roughly 51k rentals and 51k
payments over 1,000 films — large enough for index choice and join order to
matter, small enough to seed in under a minute.

Postgres surface that ships in the box:

| Feature | Where |
|---|---|
| Range partitioning | `payment`, 55 monthly partitions |
| Full-text search | `film.fulltext` + GiST, trigger-maintained |
| Vector search | `film_embedding.embedding` + HNSW, cosine |
| UUIDv7 defaults | `customer`, `rental`, `payment` |
| Enums, domains, arrays | `mpaa_rating`, `year`, `film.special_features` |
| PL/pgSQL, custom aggregate, matview | `rewards_report`, `group_concat`, `rental_by_category` |

## Sharp edges

- **PostgreSQL 18 is a hard floor** — `uuidv7()` defaults, plus `vector` needed
  at restore time, hence the `pgvector/pgvector:pg18` image.
- **`payment`'s FKs are uneven.** Only the six 2022-01…2022-06 partitions carry
  them; the other 49 enforce nothing.
- **`payment`'s PK is `(payment_date, payment_id)`**, so `payment_id` alone is
  unique nowhere.
- **Partitions stop at 2026-08-01**, so inserting with `now()` fails with *no
  partition of relation "payment" found*. Backdate it or add the partition.
- **`film.fulltext` is trigger-maintained**; a generated column is the modern
  equivalent, and a good before/after demo.

## Schema

`db/01-schema.sql` is `pg_dump --schema-only` output, so it is the reference.
Live:

```sh
docker compose exec postgres psql -U postgres -d pagila -c '\d+ film'
```

Upstream publishes an
[ER diagram](https://github.com/devrimgunduz/pagila/blob/master/pagila-schema-diagram.png).

## Layout

```
compose.yaml          pgvector/pgvector:pg18, port, init mount
justfile              up and down
db/00-extensions.sql  pg_stat_statements
db/01-schema.sql      vendored upstream schema dump
db/02-data.sql        vendored upstream data dump (~13 MB)
```

## Upstream

Pagila is BSD-licensed (see upstream `LICENSE.txt`). The dumps are vendored so
the repo works offline and upstream changes show up as a diff; refresh by
re-pulling `pagila-schema.sql` and `pagila-data.sql` into `db/`. One local edit:
upstream's unused, non-ASCII `"bıgınt"` domain is stripped, so a re-pull brings
it back.
