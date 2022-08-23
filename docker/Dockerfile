FROM python:3.9.1-slim-buster

RUN pip install pandas numpy sklearn


COPY score.py /usr/local/bin/.

RUN chmod +x /usr/local/bin/score.py
