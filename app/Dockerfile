# Extend from the official Elixir image.
FROM elixir:latest

# Create app directory and copy the Elixir projects into it.
RUN mkdir /app
RUN mkdir /app/priv/
WORKDIR /app

ENV MIX_ENV=prod
ENV DATABASE_PATH=/var/app/app.db
ENV PORT=4001

COPY mix.exs /app/mix.exs
RUN mix deps.get --prod

COPY config/ /app/config/
COPY assets/ /app/assets/
COPY lib /app/lib/
COPY priv/repo /app/priv/repo/

RUN mix assets.deploy
RUN mix compile


CMD ["mix", "phx.server"]
