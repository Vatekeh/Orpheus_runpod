FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies AND build tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    ffmpeg \
    espeak-ng \
    build-essential \
    cmake \
    python3.10-dev \
    ninja-build \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Update pip
RUN pip3 install --upgrade pip

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
# Install PyTorch/Torchaudio first
RUN pip3 install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cu118
# Download the vllm wheel first, then install locally
RUN wget https://github.com/vllm-project/vllm/releases/download/v0.7.3/vllm-0.7.3+cu118-cp310-cp310-manylinux1_x86_64.whl -O /tmp/vllm.whl
RUN pip3 install --no-cache-dir /tmp/vllm.whl -vvv
RUN rm /tmp/vllm.whl
# Install packages from requirements.txt (should just be runpod now)
RUN pip3 install --no-cache-dir -r requirements.txt -vvv

# Copy the rest of the application code
COPY . .

# Copy the handler script (just to be explicit, though COPY . . includes it)
COPY handler.py /app/handler.py

# Expose port if necessary (RunPod typically handles this)
# EXPOSE 8080 

# Set the entrypoint for RunPod Serverless
ENTRYPOINT ["python3", "-u", "handler.py"] 