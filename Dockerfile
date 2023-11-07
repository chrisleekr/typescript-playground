# Define the Node version
ARG NODE_VERSION=18.18.2

# Build TypeScript Image
FROM node:$NODE_VERSION-bullseye-slim AS build

WORKDIR /usr/src/app

# Set the npm registry
RUN yarn config set registry "https://registry.npmjs.org/" -g

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
    yarn install --frozen-lockfile && \
    rm -f .npmrc

# Copy source files
COPY tsconfig.* ./
COPY src ./src

# Build the app
RUN yarn build

# Dependencies Image
FROM node:$NODE_VERSION-bullseye-slim AS dependencies

WORKDIR /usr/src/app

# Copy package files
COPY package.json yarn.lock ./

# Install production dependencies
ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
    yarn install --frozen-lockfile --production=true && \
    rm -f .npmrc

# Production Image
FROM node:$NODE_VERSION-bullseye-slim AS production

# Install necessary packages and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends dumb-init=1.2.5-1 curl=7.74.0-1.3+deb11u10 && \
    rm -rf /var/lib/apt/lists/*

# Set user to node
USER node

WORKDIR /usr/src/app

# Copy package files
COPY --chown=node:node package.json yarn.lock ./

# Copy node_modules from dependencies image
COPY --chown=node:node --from=dependencies /usr/src/app/node_modules node_modules

# Copy built files from build image
COPY --chown=node:node --from=build /usr/src/app/dist dist

# Set environment variables
ENV NODE_ENV production
ENV PORT 8091

# Expose the port
EXPOSE 8091

# Set the command to run the app
CMD ["dumb-init", "node", "dist/index.js"]
