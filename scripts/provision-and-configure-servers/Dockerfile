FROM alpine:3.7

RUN apk add --no-cache python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache

RUN apk update && apk add openssh

ADD . /data
RUN rm -rf /data/venv # ignore 'venv' directory

WORKDIR /data

RUN pip install -r requirements.txt

RUN chmod 400 id_rsa.pem
RUN chmod +x run.sh

ENTRYPOINT sh run.sh



