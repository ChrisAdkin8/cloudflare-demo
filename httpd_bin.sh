#!/bin/bash
docker stop httpbin
docker rm httpbin
docker run -d -v /etc/ssl/certs:/certs -p 443:443 --name httpbin kennethreitz/httpbin \
  bash -c "
  pip install httpbin gunicorn && \
  gunicorn -b 0.0.0.0:443 --certfile=/certs/cert.pem --keyfile=/certs/key.pem httpbin:app"
