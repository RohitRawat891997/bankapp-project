# syntax=docker/dockerfile:1.7

# ---------- Build Stage ----------
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app

# Cache dependencies: only re-downloaded when pom.xml changes
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -q dependency:go-offline

# Copy source and build
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B clean package -DskipTests \
    && cp target/*.jar app.jar

# ---------- Runtime Stage ----------
FROM eclipse-temurin:17-jre-alpine

# Apply latest OS security patches, create non-root user, install minimal tool for healthcheck
RUN apk upgrade --no-cache \
    && addgroup -S spring \
    && adduser -S spring -G spring \
    && apk add --no-cache curl \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Copy jar with correct ownership
COPY --from=builder --chown=spring:spring /app/app.jar /app/app.jar

USER spring

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD curl --silent --fail http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
