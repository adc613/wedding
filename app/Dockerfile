# Extend from the official Elixir image.
FROM elixir:latest

# Create app directory and copy the Elixir projects into it.
RUN mkdir /app
WORKDIR /app

COPY mix.exs /app/mix.exs
RUN mix deps.get --prod

COPY assets/ /app/assets/
COPY config/ /app/config/
COPY lib /app/lib/
COPY priv /app/priv/

ENV MIX_ENV=prod
# Install Hex package manager.
# By using `--force`, we don’t need to type “Y” to confirm the installation.
RUN mix compile
RUN mix assets.deploy
ENV DATABASE_PATH=/var/app/app.db
ENV PORT=4001

CMD ["mix", "phx.server"]
