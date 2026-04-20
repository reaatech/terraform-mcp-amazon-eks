# MCP Server Runtime
# Lightweight container for the Model Context Protocol server deployed on EKS.
# This is a minimal placeholder runtime — replace with your actual MCP server binary.

FROM python:3.12-slim AS builder

# Install build dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install production Python dependencies only
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Ensure .local exists even if requirements.txt is empty
RUN mkdir -p /root/.local

# ───────────────────────────────────────────────────────────────
# Production stage — no build tools, no dev dependencies
# ───────────────────────────────────────────────────────────────
FROM python:3.12-slim AS production

WORKDIR /app

# Create non-root user for security
RUN groupadd -r mcp && useradd -r -g mcp mcp

# Copy installed packages from builder
COPY --from=builder /root/.local /home/mcp/.local
ENV PATH=/home/mcp/.local/bin:$PATH

# Copy application code
COPY --chown=mcp:mcp src/ ./src/

# Health check endpoint (matches K8s probes in modules/mcp-service/main.tf)
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

USER mcp

EXPOSE 8080

CMD ["python", "-m", "src.server"]
