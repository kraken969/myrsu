# Build the Flutter web frontend.
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# Run the combined frontend + backend service.
FROM node:22-bookworm-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production

COPY server/package.json server/package-lock.json ./server/
RUN npm --prefix server ci --omit=dev

COPY server ./server
COPY --from=flutter-build /app/build/web ./build/web

EXPOSE 8080
CMD ["npm", "--prefix", "server", "start"]
