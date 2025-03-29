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
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
# Install PyTorch/Torchaudio first
RUN pip3 install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cu118
# Install specific vllm version recommended by Orpheus docs
RUN pip3 install --no-cache-dir vllm==0.7.3 
# Install packages from requirements.txt with high verbosity
RUN pip3 install --no-cache-dir -r requirements.txt -vvv

# Copy the rest of the application code
COPY . .

# Copy the handler script (just to be explicit, though COPY . . includes it)
COPY handler.py /app/handler.py

# Expose port if necessary (RunPod typically handles this)
# EXPOSE 8080 

# Set the entrypoint for RunPod Serverless
ENTRYPOINT ["python3", "-u", "handler.py"] 