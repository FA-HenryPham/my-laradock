#!/usr/bin/env bash

# The system secret can only be set against a fresh database. Key rotation is currently not supported. This
# secret is used to encrypt the database and needs to be set to the same value every time the process (re-)starts.
# You can use /dev/urandom to generate a secret. But make sure that the secret must be the same anytime you define it.
# You could, for example, store the value somewhere.
SECRETS_SYSTEM=$(export LC_CTYPE=C; cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
#
# Alternatively you can obviously just set a secret:
# $ export SECRETS_SYSTEM=this_needs_to_be_the_same_always_and_also_very_$3cuR3-._

# The database url points us at the postgres instance. This could also be an ephemeral in-memory database (`export DSN=memory`)
# or a MySQL URI.
DSN=postgres://default:secret@postgres:5432/default?sslmode=disable

# Before starting, let's pull the latest ORY Hydra tag from docker.
#docker pull oryd/hydra:v1.9.2
docker pull oryd/hydra

# This command will show you all the environment variables that you can set. Read this carefully.
# It is the equivalent to `hydra help serve`.
docker run -it --rm --entrypoint hydra oryd/hydra help serve

#Starts all HTTP/2 APIs and connects to a database backend.
#[...]

# ORY Hydra does not do magic, it requires conscious decisions, for example running SQL migrations which is required
# when installing a new version of ORY Hydra, or upgrading an existing installation.
# It is the equivalent to `hydra migrate sql --yes postgres://hydra:secret@ory-hydra-example--postgres:5432/hydra?sslmode=disable`
docker run -it --rm \
  --network laradock_hydraguide \
  oryd/hydra \
  migrate sql --yes $DSN


#Applying `client` SQL migrations...
#[...]
#Migration successful!

# Let's run the server (settings explained below):
docker run -d \
  --name ory-hydra-example--hydra \
  --network laradock_hydraguide \
  -p 9000:4444 \
  -p 9001:4445 \
  -e SECRETS_SYSTEM=$SECRETS_SYSTEM \
  -e DSN=$DSN \
  -e URLS_SELF_ISSUER=https://localhost:9000/ \
  -e URLS_CONSENT=http://localhost:9020/consent \
  -e URLS_LOGIN=http://localhost:9020/login \
  -e URLS_ERROR=http://localhost:9020/error \
  oryd/hydra serve all

# And check if it's running:
docker logs ory-hydra-example--hydra

# time="2017-06-29T21:26:26Z" level=info msg="Connecting with postgres://*:*@postgres:5432/hydra?sslmode=disable"
# time="2017-06-29T21:26:26Z" level=info msg="Connected to SQL!"
# [...]
# time="2017-06-29T21:26:34Z" level=info msg="Setting up http server on :4444"

#docker pull oryd/hydra-login-consent-node:v1.3.2
docker pull oryd/hydra-login-consent-node

docker run -d \
  --name ory-hydra-example--consent \
  -p 9020:3000 \
  --network laradock_hydraguide \
  -e HYDRA_ADMIN_URL=http://ory-hydra-example--hydra:4445 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  oryd/hydra-login-consent-node

# docker run --rm -it \
#   -e HYDRA_ADMIN_URL=https://ory-hydra-example--hydra:4445 \
#   --network laradock_hydraguide \
#   oryd/hydra:v1.9.2 \
#   clients create --skip-tls-verify \
#     --id plutus-openid \
#     --secret plutus-openid-secret \
#     --grant-types authorization_code,refresh_token,client_credentials,implicit,password \
#     --response-types token,code,id_token \
#     --scope openid,pos,mobile,external \
#     --callbacks http://127.0.0.1:9010/callback


# docker run --rm -it \
#   --network laradock_hydraguide \
#   -p 9010:9010 \
#   oryd/hydra:v1.9.2 \
#   token user --skip-tls-verify \
#     --port 9010 \
#     --auth-url https://localhost:9000/oauth2/auth \
#     --token-url https://ory-hydra-example--hydra:4444/oauth2/token \
#     --client-id facebook-photo-backup \
#     --client-secret plutus-openid \
#     --scope openid,pos,mobile,external


docker run --rm -it \
  -e HYDRA_ADMIN_URL=https://ory-hydra-example--hydra:4445 \
  --network laradock_hydraguide \
  oryd/hydra \
  clients create --skip-tls-verify \
    --id pos-test1 \
    --secret pos-secret1 \
    --grant-types password,refresh_token \
    --response-types token,code,id_token \
    --scope openid,offline,photos.read


docker run -it --rm \
  -e HYDRA_ADMIN_URL=https://ory-hydra-example--hydra:4445 \
  --network laradock_hydraguide \
  oryd/hydra \
  token client \
    --endpoint http://ory-hydra-example--hydra:4444/ \
    --client-id pos-test1 \
    --client-secret pos-secret1


docker run --rm -it \
  --network laradock_hydraguide \
  -p 9010:9010 \
  oryd/hydra:v1.9.2 \
  token user --skip-tls-verify \
    --port 9010 \
    --auth-url https://localhost:9000/oauth2/auth \
    --token-url https://ory-hydra-example--hydra:4444/oauth2/token \
    --client-id pos-test \
    --client-secret pos-secret \
    --scope openid,offline,photos.read

 docker exec laradock_hydra_1 \
    hydra token client \
    --endpoint http://127.0.0.1:4444/ \
    --client-id my-client \
    --client-secret secret

docker exec laradock_hydra_1 \
    hydra token introspect \
    --endpoint http://127.0.0.1:4445/ \
    emSxKWKNO8ku0zrG3DTB8jhPi5ZkC_cvJj6W3pqu8v8.mVpg-OBD3ZOr0TmY5SJRQBoPXZ6xghXxMdmIk6G_a_4

docker exec laradock_hydra_1 \
    hydra clients create \
    --endpoint http://127.0.0.1:4445 \
    --id auth-code-client \
    --secret secret \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --callbacks http://127.0.0.1:5555/callback

docker exec laradock_hydra_1 \
    hydra clients create \
    --endpoint http://127.0.0.1:4445 \
    --id auth-code-client3 \
    --secret secret \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --token-endpoint-auth-method client_secret_post \
    --callbacks http://127.0.0.1:4477/auth/callback

docker exec laradock_hydra_1 \
    hydra clients create \
    --endpoint http://127.0.0.1:4445 \
    --id auth-code-client4 \
    --secret secret \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --token-endpoint-auth-method client_secret_post \
    --callbacks http://web.ory.localhost/auth/callback

docker exec laradock_hydra_1 \
    hydra clients create \
    --endpoint http://127.0.0.1:4445 \
    --id auth-code-client5 \
    --secret secret \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --token-endpoint-auth-method client_secret_post \
    --callbacks http://web.ory.localhost/auth/callback

docker exec hydra_hydra_1 \
    hydra clients create \
    --endpoint http://id.hungpham.dev.syd.soldi.io:4445 \
    --id auth-code-client2 \
    --secret secret \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --token-endpoint-auth-method client_secret_post \
    --callbacks https://297e4f3c2836.ap.ngrok.io/auth/callback

docker exec hydra_hydra_1 \
    hydra clients create \
    --endpoint http://id.hungpham.dev.syd.soldi.io:4445 \
    --id auth-code-client-petstock \
    --secret secret \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --token-endpoint-auth-method client_secret_post \
    --callbacks https://petstock.oauth-sample.dev.syd.darkwing.io/auth/callback

docker exec laradock_hydra_1 \
    hydra clients update c91506f8-be55-4893-8208-c5ecb610a0d0 \
    --endpoint http://hydra:4445 \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --token-endpoint-auth-method client_secret_post \
    --callbacks https://6fb9160e8398.ap.ngrok.io/oauth2/redirect

docker exec hydra_hydra_1 \
    hydra clients update auth-code-client-petstock \
    --endpoint http://localhost:4445 \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --secret jRvupaJ0tv7LG2lougBCNClwsmM3WQz754WfdXYG \
    --token-endpoint-auth-method client_secret_post \
    --callbacks https://petstock.oauth-sample-new.dev.syd.darkwing.io/auth/redirect,https://petstock.oauth-sample-new.dev.syd.darkwing.io/auth/callback,https://plutus.oauth-sample-new.dev.syd.darkwing.io/auth/redirect

docker exec soldi-ory-hydra_hydra_1 \
    hydra clients update abfa83c9-065b-4a64-a6e3-49a1f279229f \
    --endpoint http://localhost:4445 \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --token-endpoint-auth-method client_secret_post \
    --callbacks https://pos-api-oauth-test.dev.syd.darkwing.io/oauth2/redirect,https://petstock.oauth-sample-new.dev.syd.darkwing.io/auth/redirect,https://plutus.oauth-sample-new.dev.syd.darkwing.io/auth/redirect,http://local.petstock.com.au/login/validate,https://local.petstock.com.au/login/validate,https://testing.petstock.com.au/login/validate,https://staging.petstock.com.au/login/validate,http://local.petstock.co.nz/login/validate,https://local.petstock.co.nz/login/validate,https://testing.petstock.co.nz/login/validate,https://staging.petstock.co.nz/login/validate

docker exec soldi-ory-hydra_hydra_1 \
    hydra clients get abfa83c9-065b-4a64-a6e3-49a1f279229f \
    --endpoint http://localhost:4445

docker exec laradock_hydra_1 \
    hydra clients get c91506f8-be55-4893-8208-c5ecb610a0d0 \
    --endpoint http://localhost:4445

docker exec laradock_hydra_1 \
    hydra clients update af3beeab-b634-4a37-876e-e7428297df3d \
    --endpoint http://localhost:4445 \
    --secret AbRbKhy4eXme69cNa2s6BlxSD6ZQ0OqaBNc6EK0w \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --token-endpoint-auth-method client_secret_post \
    --post-logout-callbacks http://ory.dev.local/auth/redirect \
    --callbacks http://ory.dev.local/auth/redirect

docker exec laradock_hydra_1 \
    hydra clients get af3beeab-b634-4a37-876e-e7428297df3d \
    --endpoint http://localhost:4445

docker exec hydra_hydra_1 \
    hydra clients update auth-code-client1 \
    --endpoint http://id.hungpham.dev.syd.soldi.io:4445 \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --token-endpoint-auth-method client_secret_post \
    --callbacks https://5a36e9409c48.ap.ngrok.i

docker exec hydra_hydra_1 \
    hydra clients update d937f831-e236-4fda-b629-6508a63c5c23 \
    --endpoint http://localhost:4445 \
    --grant-types authorization_code,refresh_token \
    --response-types code,id_token \
    --scope openid,offline \
    --token-endpoint-auth-method client_secret_post \
    --secret sCKSXrUOejOJ95899pQiPpzdDmVbEvIkYanN6yK2 \
    --callbacks http://ory.dev.localhost/auth/redirect

docker exec laradock_hydra_1 \
    hydra token user \
    --client-id auth-code-client \
    --client-secret secret \
    --endpoint http://127.0.0.1:4444/ \
    --port 5555 \
    --scope openid,offline


<?php

use Illuminate\Support\Str;
use DB;

DB::table('user')->where('organisation_id', 4)->get()->each(function ($user) {
    DB::table('user')->where('id', $user->id)->update([
        'sso_uuid' => (string) Str::uuid(),
        'password' => bcrypt('Plutus123'),
        'is_verified' => true,
        'is_offline' => false,
        'is_onboarding' => false,
        'is_active' => true,
    ]);
});
