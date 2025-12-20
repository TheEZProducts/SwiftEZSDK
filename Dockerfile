# ================================
# Linux Test Build
# ================================

FROM swift:latest

WORKDIR /app
COPY . .

RUN swift package resolve
RUN swift build -c release