# ================================
# Linux Test Build
# ================================

FROM swiftarm/swift:latest as build

COPY . .
RUN swift package resolve
RUN swift build -c release