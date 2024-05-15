ARG INSTALLER=yarn

FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
ARG INSTALLER

# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ "${INSTALLER}" == "yarn" ]; then yarn --frozen-lockfile; \
  elif [ "${INSTALLER}" == "npm" ]; then npm ci; \
  elif [ "${INSTALLER}" == "pnpm" ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Valid installer not set." && exit 1; \
  fi
FROM base AS build
WORKDIR /app
COPY package*.json ./
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG INSTALLER
RUN \
  if [ "${INSTALLER}" == "yarn" ]; then yarn build; \
  elif [ "${INSTALLER}" == "npm" ]; then npm run build; \
  elif [ "${INSTALLER}" == "pnpm" ]; then pnpm run build; \
  else echo "Valid installer not set." && exit 1; \
  fi

FROM nginx:alpine AS runtime
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
