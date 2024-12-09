#!/bin/bash

set -e

# 1. Git 및 Python 3.12 설치
sudo yum update -y
sudo amazon-linux-extras enable python3.12  # Amazon Linux 2
sudo yum install -y git python3.12

# Python 버전 확인
python3.12 --version

# 2. Git 저장소 클론
REPO_URL="https://github.com/Samiiz/ytrapi.git"  # 저장소 URL 수정 필요
echo "Cloning repository..."
git clone $REPO_URL
REPO_NAME=$(basename "$REPO_URL" .git)
cd $REPO_NAME

# 3. 가상 환경 생성 및 활성화
echo "Creating and activating Python virtual environment..."
python3.12 -m venv .venv
source .venv/bin/activate

# 4. requirements.txt 설치
if [ -f "requirements.txt" ]; then
    echo "Installing requirements..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "requirements.txt not found. Skipping package installation."
fi

# 5. Django 개발 서버 실행
if [ -d "app" ]; then
    cd app
    echo "Running Django development server..."
    python3.12 manage.py makemigrations
    python3.12 manage.py migrate
    python3.12 manage.py createsuperuser
    python3.12 manage.py runserver
else
    echo "App directory not found. Please check the folder structure."
fi
