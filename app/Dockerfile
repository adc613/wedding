# Extend from the official Elixir image.
FROM elixir:latest

# Create app directory and copy the Elixir projects into it.
RUN mkdir /app
WORKDIR /app

COPY mix.exs /app/mix.exs
RUN mix deps.get --prod

COPY config/ /app/config/
COPY assets/ /app/assets/
COPY priv /app/priv/
RUN mix assets.deploy

COPY lib /app/lib/

ENV MIX_ENV=prod
RUN mix compile

ENV DATABASE_PATH=/var/app/app.db
ENV PORT=4001

CMD ["mix", "phx.server"]
