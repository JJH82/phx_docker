FROM registry.access.redhat.com/ubi8/ubi-minimal AS builder

# 필수 패키지 설치
RUN microdnf install -y git make gcc gcc-c++ ncurses-devel openssl-devel unzip && \
    microdnf clean all
  
# Erlang Solutions 공식 저장소 추가 및 Erlang/OTP 27 설치
RUN curl -fsSL https://binaries2.erlang-solutions.com/rockylinux/8/esl-erlang_27.1_1~rockylinux~8_x86_64.rpm -o erlang.rpm && \
    rpm -ivh ./erlang.rpm && \
    rm ./erlang.rpm

# Elixir 1.17.3 (OTP 27) 설치
RUN curl -fsSL https://repo.hex.pm/builds/elixir/v1.17.3-otp-27.zip -o elixir.zip && \
    unzip elixir.zip -d /usr/local/elixir && \
    rm elixir.zip && \
    ln -s /usr/local/elixir/bin/* /usr/local/bin/


# 작업 디렉토리 설정
WORKDIR /app
COPY mix.exs mix.lock ./
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mkdir -p /root/.cache/rebar3 && \
    mix deps.get && \
    mix assets.setup
    

# 최종 실행 이미지
FROM registry.access.redhat.com/ubi8/ubi-minimal
RUN microdnf install -y git make gcc gcc-c++ glibc-langpack-en tar ncurses openssl unzip && microdnf clean all

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV r=prod

# Erlang Solutions 공식 저장소 추가 및 Erlang/OTP 27 설치
RUN curl -fsSL https://binaries2.erlang-solutions.com/rockylinux/8/esl-erlang_27.1_1~rockylinux~8_x86_64.rpm -o erlang.rpm && \
    rpm -ivh ./erlang.rpm && \
    rm ./erlang.rpm

# Elixir 1.17.3 (OTP 27) 설치
RUN curl -fsSL https://repo.hex.pm/builds/elixir/v1.17.3-otp-27.zip -o elixir.zip && \
    unzip elixir.zip -d /usr/local/elixir && \
    rm elixir.zip && \
    ln -s /usr/local/elixir/bin/* /usr/local/bin/

WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY --from=builder /app/_build /app/_build
COPY --from=builder /root/.mix /root/.mix
COPY --from=builder /root/.hex /root/.hex
COPY --from=builder /root/.cache/rebar3 /root/.cache/rebar3
RUN rm -Rf /app/_build/dev
RUN mix hex.config offline true