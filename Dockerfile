FROM registry.access.redhat.com/ubi8/ubi-minimal AS builder

# Jenkins 에이전트의 UID/GID를 전달받기 위한 변수 선언
ARG UID=1000
ARG GID=1000

# 필수 패키지 설치
RUN microdnf install -y git make gcc gcc-c++ glibc-langpack-en tar ncurses openssl unzip && microdnf clean all

# Erlang Solutions 공식 저장소 추가 및 Erlang/OTP 27 설치
RUN curl -fsSL https://binaries2.erlang-solutions.com/centos/esl-erlang-27/esl-erlang_27.3.4_1~centos~8_x86_64.rpm -o erlang.rpm && \
    rpm -ivh ./erlang.rpm && \
    rm ./erlang.rpm

# Elixir 1.18.4 (OTP 27) 설치
RUN curl -fsSL https://repo.hex.pm/builds/elixir/v1.18.4-otp-27.zip -o elixir.zip && \
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
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV MIX_ENV=prod
