# !/bin/bash

if [[ $(aws s3 ls s3://test-asc-sagemaker-fraud/source/ | grep 'Fraud_Detection') ]]; then 
    OBJECT="$(aws s3 ls s3://test-asc-sagemaker-fraud/source/ --recursive | sort | tail -n 1 | awk '{print $4}')"
    aws s3 cp s3://test-asc-sagemaker-fraud/$OBJECT ./$OBJECT
    file1="./source/Fraud_Detection.ipynb"
    file2=$(find . -name 'Fraud_Detection_*')
    if cmp -s "$file1" "$file2"; then
        echo "two files are same";
        IFS='. ' read -r -a array <<< $OBJECT
        IFS='_ ' read -r -a array2 <<< ${array[0]}
        VERSION="${array2[@]: -1:1}"
    else
        echo "two files are different"
        aws s3 cp ./source/Fraud_Detection.ipynb s3://test-asc-sagemaker-fraud/source/Fraud_Detection_${VERSION}.ipynb
    fi
else 
    aws s3 cp ./source/Fraud_Detection.ipynb s3://test-asc-sagemaker-fraud/source/Fraud_Detection_${VERSION}.ipynb
fi

if [[ $(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --region us-west-2 | grep 'test-sagemaker-cicd') ]]; then
    echo 'Updating Stack...'
    aws cloudformation deploy --template-file ./deployment/test.yaml --stack-name test-sagemaker-cicd --capabilities CAPABILITY_NAMED_IAM --parameter-overrides Version=${VERSION}
    if [ "$?" -eq 255 ]; then
        echo "No changes to deploy."
        exit 0;
    else
        aws cloudformation wait stack-update-complete --stack-name test-sagemaker-cicd
        status=$?
        if [[ ${status} -ne 0 ]] ; then
            # Waiter encountered a failure state.
            echo "Stack update failed. AWS error code is ${status}."

            exit ${status}
        fi
        echo "Stopping notbook instance..."
        aws sagemaker stop-notebook-instance --notebook-instance-name $1
        aws sagemaker wait notebook-instance-stopped --notebook-instance-name $1
        echo "Starting notbook instance..."
        aws sagemaker start-notebook-instance --notebook-instance-name $1
        aws sagemaker wait notebook-instance-in-service --notebook-instance-name $1
    fi
else
    echo 'Creating Stack...'
    aws cloudformation deploy --template-file ./deployment/test.yaml --stack-name test-sagemaker-cicd --capabilities CAPABILITY_NAMED_IAM --parameter-overrides Version=${VERSION}
    aws cloudformation wait stack-create-complete --stack-name test-sagemaker-cicd
    status=$?
    if [[ ${status} -ne 0 ]] ; then
        # Waiter encountered a failure state.
        echo "Stack creation failed. AWS error code is ${status}."

        exit ${status}
    fi
fi
