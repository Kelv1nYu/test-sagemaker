# !/bin/bash

if [[ $(aws s3 ls s3://test-asc-sagemaker-fraud/source/ | grep 'Fraud_Detection') ]]; then 
    OBJECT="$(aws s3 ls s3://test-asc-sagemaker-fraud/source/ --recursive | sort | tail -n 1 | awk '{print $4}')"
    aws s3 cp s3://test-asc-sagemaker-fraud/$OBJECT ./source/$OBJECT
else 
    exit 1;
fi

file1="./source/Fraud_Detection.ipynb"
file2=$(find . -name 'Fraud_Detection_*')

if cmp -s "$file1" "$file2"; then
    exit 1;
else
    aws s3 cp ./source/Fraud_Detection.ipynb s3://test-asc-sagemaker-fraud/source/Fraud_Detection_${VERSION}.ipynb
fi