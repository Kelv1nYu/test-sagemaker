#!/bin/bash

git log

# changeFiles=$(git diff --name-only HEAD~ HEAD)
changeFiles=$(git log --name-only)
echo $changeFiles

# aws s3 cp ./source/Fraud_Detection.ipynb s3://test-asc-sagemaker-fraud/source/Fraud_Detection_${VERSION}.ipynb