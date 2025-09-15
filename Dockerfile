FROM elixir:latest
WORKDIR /app
COPY ./app/mix.exs /app/mix.exs
COPY ./app/config /app/config
COPY ./app/priv /app/priv
COPY ./app/lib /app/lib
COPY ./app/test /app/test

COPY ./app/assets /app/assets
RUN mix deps.get
RUN mix assets.deploy
RUN mix compile

CMD ["mix", "test"]
