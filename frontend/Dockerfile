FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache dependencies separately for faster rebuilds.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter config --enable-web
RUN flutter build web --release

FROM nginx:1.29-alpine

RUN apk update && apk upgrade --no-cache

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
