#!/bin/bash


changeFiles=$(git diff --name-only HEAD~ HEAD)

echo $changeFiles

# aws s3 cp ./source/Fraud_Detection.ipynb s3://test-asc-sagemaker-fraud/source/Fraud_Detection_${VERSION}.ipynb