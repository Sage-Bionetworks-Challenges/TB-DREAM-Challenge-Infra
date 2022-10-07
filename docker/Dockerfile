FROM python:3.9.1-slim-buster

RUN pip install pandas numpy sklearn
RUN apt-get --force-yes update \
    && apt-get --assume-yes install r-base-core

RUN pip install rpy2
RUN pip install Pandas

COPY requirements.r /usr/local/bin/.
COPY two_way_partial_AUC.R /usr/local/bin/.

COPY score.py /usr/local/bin/.
COPY validate.py /usr/local/bin/.

RUN chmod +x /usr/local/bin/requirements.r
RUN chmod +x /usr/local/bin/two_way_partial_AUC.R
RUN Rscript requirements.r

RUN chmod +x /usr/local/bin/score.py
RUN chmod +x /usr/local/bin/validate.py
