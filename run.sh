#!/bin/bash

# 1. Git 및 Python 3.12 설치
sudo yum update -y
sudo amazon-linux-extras enable python3.12  # Amazon Linux 2
sudo yum install -y git python3.12 nginx

# Python 버전 확인
python3.12 --version

# 2. Git 저장소 클론
REPO_URL="https://github.com/your-repo/your-project.git"  # 저장소 URL 수정 필요
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

# 5. Django 초기화 작업
if [ -f "manage.py" ]; then
    echo "Running Django migrations and server setup..."

    # 데이터베이스 마이그레이션
    python manage.py makemigrations
    python manage.py migrate

    # Django 슈퍼유저 생성 (자동화)
    echo "Creating superuser..."
    echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'adminpassword')" | python manage.py shell

    # Django 서버 백그라운드 실행
    nohup python manage.py runserver 0.0.0.0:8000 > django.log 2>&1 &
else
    echo "manage.py not found. Please check your Django project structure."
fi

# 6. Nginx 설정 파일 생성
NGINX_CONF="/etc/nginx/conf.d/django.conf"
sudo bash -c "cat > $NGINX_CONF" << EOF
server {
    listen 80;

    server_name _;  # Public IP 또는 도메인 설정 필요

    location / {
        proxy_pass http://127.0.0.1:8000;  # Django 개발 서버의 8000번 포트로 프록시
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# 7. Nginx 서비스 재시작
echo "Restarting Nginx..."
sudo nginx -t && sudo systemctl restart nginx

# 8. 결과 출력
echo "Django development server is running at http://<your-public-ip>"
