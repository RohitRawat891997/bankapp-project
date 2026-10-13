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
    && mv target/*.jar app.jar


# ---------- Runtime Stage ----------
FROM eclipse-temurin:17-jre-alpine

# Apply latest OS security patches, then create non-root user
RUN apk upgrade --no-cache \
    && addgroup -S spring \
    && adduser -S spring -G spring

WORKDIR /app

# Copy jar with correct ownership
COPY --from=builder --chown=spring:spring /app/app.jar app.jar

USER spring

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
