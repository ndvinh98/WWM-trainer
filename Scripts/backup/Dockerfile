FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LLAMA_CPP_REPO=https://github.com/ggml-org/llama.cpp.git
ENV LLAMA_CPP_DIR=/opt/llama.cpp
ENV MODEL_DIR=/models
ENV PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    curl \
    wget \
    python3 \
    python3-venv \
    libssl-dev \
    libvulkan-dev \
    vulkan-tools \
    mesa-vulkan-drivers \
    glslc \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# install Python tooling first for better layer caching
RUN uv venv /opt/venv && \
    . /opt/venv/bin/activate && \
    uv pip install "huggingface_hub[cli]"

ENV PATH="/opt/venv/bin:/root/.local/bin:${PATH}"

RUN git clone --depth=1 ${LLAMA_CPP_REPO} ${LLAMA_CPP_DIR} && \
    cmake -S ${LLAMA_CPP_DIR} -B ${LLAMA_CPP_DIR}/build \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_VULKAN=ON \
    -DLLAMA_BUILD_TESTS=OFF && \
    cmake --build ${LLAMA_CPP_DIR}/build --config Release -j$(nproc)

RUN mkdir -p /app ${MODEL_DIR}
WORKDIR /app

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8080
ENTRYPOINT ["/app/start.sh"]