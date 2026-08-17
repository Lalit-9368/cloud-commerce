FROM python:3.13-alpine

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt \
    && pip uninstall -y pip setuptools

COPY main.py .

EXPOSE 4002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "4002"]