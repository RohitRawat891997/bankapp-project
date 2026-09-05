# ---------- Build Stage ----------
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy pom.xml for dependency caching
COPY pom.xml .

# Download dependencies (leverage Docker layer caching)
RUN mvn dependency:resolve

# Copy source code
COPY . .

# Build application
RUN mvn clean package -DskipTests


# ---------- Runtime Stage ----------
FROM eclipse-temurin:17-jre-alpine

# Install required packages for HEALTHCHECK
RUN apk add --no-cache wget

# Create non-root user
RUN addgroup -S spring && \
    adduser -S spring -G spring

WORKDIR /app

# Copy jar from builder with specific naming
COPY --from=builder /app/target/app*.jar app.jar

# Change ownership
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

# JVM arguments for production use
ENTRYPOINT ["java", "-XX:+UseG1GC", "-XX:MaxRAMPercentage=75.0", "-XX:InitialRAMPercentage=25.0", "-jar", "app.jar"]
