.DEFAULT_GOAL := help

help:
	@echo "${PROJECT}"
	@echo "${DESCRIPTION}"
	@echo ""
	@echo "	layer - prepare the layer"
	@echo "	package - prepare the package"
	@echo "	deploy - deploy the lambda function"
	@echo "	destroy - destroy the CloudFormation stack"
	@echo "	clean - clean the build folder"
	@echo "	clean-layer - clean the layer folder"
	@echo "	cleaning - clean build and layer folders"

####################### Project #######################
PROJECT ?= instance-watcher
DESCRIPTION ?= Instance Watcher Stack
#######################################################

###################### Variables ######################
S3_BUCKET ?= ${PROJECT}-artifacts
AWS_REGION ?= eu-west-1
# Recipients are space delimited (ie: john@doe.com david@doe.com)
RECIPIENTS := john@doe.com
SENDER := john@doe.com
ENV ?= dev
#######################################################

package: clean
	@echo "Consolidating python code in ./build"
	mkdir -p build

	cp -R *.py ./build/

	@echo "zipping python code, uploading to S3 bucket, and transforming template"
	aws cloudformation package \
		--template-file sam.yml \
		--s3-bucket ${S3_BUCKET} \
		--output-template-file build/template-lambda.yml

	@echo "Copying updated cloud template to S3 bucket"
	aws s3 cp build/template-lambda.yml 's3://${S3_BUCKET}/template-lambda.yml'

layer: clean-layer
	pip3 install \
		--isolated \
		--disable-pip-version-check \
		-Ur requirements.txt -t ./layer/

deploy:
	aws cloudformation deploy \
		--template-file build/template-lambda.yml \
		--region ${AWS_REGION} \
		--stack-name "${PROJECT}-${ENV}" \
		--capabilities CAPABILITY_IAM \
		--parameter-overrides \
			ENV=${ENV} \
			RECIPIENTS="${RECIPIENTS}" \
			SENDER=${SENDER} \
			PROJECT=${PROJECT} \
			AWSREGION=${AWS_REGION} \
		--no-fail-on-empty-changeset

tear-down:
	@read -p "Are you sure that you want to destroy stack '${PROJECT}-${ENV}'? [y/N]: " sure && [ $${sure:-N} = 'y' ]
	aws cloudformation delete-stack --stack-name "${PROJECT}-${ENV}"

clean-layer:
	@rm -fr layer/
	@rm -fr dist/
	@rm -fr htmlcov/
	@rm -fr site/
	@rm -fr .eggs/
	@rm -fr .tox/
	@find . -name '*.egg-info' -exec rm -fr {} +
	@find . -name '.DS_Store' -exec rm -fr {} +
	@find . -name '*.egg' -exec rm -f {} +
	@find . -name '*.pyc' -exec rm -f {} +
	@find . -name '*.pyo' -exec rm -f {} +
	@find . -name '*~' -exec rm -f {} +
	@find . -name '__pycache__' -exec rm -fr {} +

clean:
	@rm -fr build/
	@rm -fr dist/
	@rm -fr htmlcov/
	@rm -fr site/
	@rm -fr .eggs/
	@rm -fr .tox/
	@find . -name '*.egg-info' -exec rm -fr {} +
	@find . -name '.DS_Store' -exec rm -fr {} +
	@find . -name '*.egg' -exec rm -f {} +
	@find . -name '*.pyc' -exec rm -f {} +
	@find . -name '*.pyo' -exec rm -f {} +
	@find . -name '*~' -exec rm -f {} +
	@find . -name '__pycache__' -exec rm -fr {} +

cleaning: clean clean-layer
