#!/bin/bash
docker stop httpbin
docker rm httpbin
docker run -d --name httpbin kennethreitz/httpbin \
  -v /etc/ssl/certs:/certs
  -p 443:443 \
  python:3.9-slim bash -c "
  pip install httpbin gunicorn && \
  gunicorn -b 0.0.0.0:443 --certfile=/certs/cert.pem --keyfile=/certs/key.pem httpbin:app"
