1. understand the project
2. containerize app (multi stage)
3. push to docker hub
4. k8s manifest so that project is ready to deploy when cluster is created
5. create eks cluster

aws cert discovery for alb controller:
aws acm import-certificate \
  --certificate fileb://certs/cert.pem \
  --private-key fileb://certs/privkey.pem \
  --certificate-chain fileb://certs/chain.pem \
  --region ap-south-1