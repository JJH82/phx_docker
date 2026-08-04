FROM registry.access.redhat.com/ubi9/ubi-minimal:9.6 AS builder

# Jenkins 에이전트의 UID/GID를 전달받기 위한 변수 선언
ARG UID=1000
ARG GID=1000

# 필수 패키지 설치
RUN microdnf install -y \
    git make gcc gcc-c++ perl autoconf \
    tar gzip unzip glibc-langpack-en openssl openssl-devel \
    ncurses ncurses-devel ncurses-libs libnsl2 zlib zlib-devel

# kerl 다운로드 및 설정 (erlang build 툴) 
RUN curl -O https://raw.githubusercontent.com/kerl/kerl/master/kerl && \
    chmod +x kerl && \
    mv kerl /usr/local/bin/

# 빌드 시 wx 및 불필요한 GUI 지원 명시적 비활성화
ENV KERL_CONFIGURE_OPTIONS="--without-wx --without-javac"

# Erlang 28.5 빌드 및 설치 (시간이 약간 소요됩니다)
RUN kerl build 28.5.0.3 28.5.0.3 && \ 
    kerl install 28.5.0.3 /usr/local/erlang/28.5.0.3

# 환경 변수 적용
ENV PATH="/usr/local/erlang/28.5.0.3/bin:$PATH"

# Elixir 1.20.2 (OTP 28) 설치
RUN curl -fsSL https://repo.hex.pm/builds/elixir/v1.20.2-otp-28.zip -o elixir.zip && \
    unzip elixir.zip -d /usr/local/elixir && \
    rm elixir.zip && \
    ln -s /usr/local/elixir/bin/* /usr/local/bin/

# =================================================================
# Jenkins 사용자 추가 섹션
# =================================================================
# 전달받은 GID로 'jenkins' 그룹 생성
RUN groupadd -g ${GID} jenkins

# 전달받은 UID와 GID로 'jenkins' 사용자 생성하고 홈 디렉토리 지정
RUN useradd -u ${UID} -g ${GID} -m -s /bin/bash jenkins

# jenkins 사용자의 홈 디렉토리를 작업 디렉토리로 설정
WORKDIR /home/jenkins
# =================================================================

# 환경 변수 
ENV MIX_ENV=prod
