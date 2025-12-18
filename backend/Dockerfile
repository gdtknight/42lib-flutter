# Backend API Container
FROM node:20-alpine

# Install OpenSSL for Prisma
RUN apk add --no-cache openssl openssl-dev

# 작업 디렉토리 설정
WORKDIR /app

# 패키지 파일 복사 및 의존성 설치
COPY package*.json ./
RUN npm install

# TypeScript 및 개발 도구 글로벌 설치
RUN npm install -g typescript ts-node prisma

# 소스 코드 복사
COPY . .

# Prisma 클라이언트 생성
RUN npx prisma generate || true

# 포트 노출
EXPOSE 3000

# 개발 모드로 실행
CMD ["npm", "run", "dev"]
