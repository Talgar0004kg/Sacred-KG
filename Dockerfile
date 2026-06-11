FROM python:3.11-slim

WORKDIR /app

RUN mkdir -p ./backend
COPY backend/ ./backend/

RUN pip install --no-cache-dir -r backend/requirements.txt

EXPOSE 7860
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]
