# Flutter 개발 환경 Docker 이미지
FROM ubuntu:22.04

# 타임존 설정 (대화형 프롬프트 방지)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

# 기본 패키지 설치
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK 설치
ENV FLUTTER_HOME=/opt/flutter
ENV FLUTTER_VERSION=3.24.0
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME} \
    && ${FLUTTER_HOME}/bin/flutter --version

# PATH 설정
ENV PATH=${FLUTTER_HOME}/bin:${PATH}

# Flutter 사전 설정
RUN flutter doctor --android-licenses || true \
    && flutter config --no-analytics \
    && flutter precache

# 작업 디렉토리 설정
WORKDIR /workspace

# Flutter doctor 실행 (의존성 확인)
RUN flutter doctor

# 기본 명령어
CMD ["/bin/bash"]
