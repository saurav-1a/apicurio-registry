# used for mem, sql & kafkasql. Hardcoded for tenant manager api, since the build workspace is different
# 'override' keyword prevents the variable from being overrideen
override DOCKERFILE_LOCATION := ./distro/docker/target/docker

MEM_DOCKERFILE ?= Dockerfile.jvm
SQL_DOCKERFILE ?= Dockerfile.sql.jvm
KAFKASQL_DOCKERFILE ?= Dockerfile.kafkasql.jvm
DOCKER_BUILD_WORKSPACE ?= $(DOCKERFILE_LOCATION)

# Special variable that sets the default target
.DEFAULT_GOAL := help

# You can override these variables from the command line.
IMAGE_REPO ?= docker.io
IMAGE_TAG ?= latest
IMAGE_PLATFORMS ?= linux/amd64,linux/arm64,linux/s390x,linux/ppc64le
SKIP_TESTS ?= false
INTEGRATION_TESTS_PROFILE ?= ci
BUILD_FLAGS ?=


# Colour Codes for help message
override RED := \033[0;31m
override BLUE := \033[36m
override NC := \033[0m
override BGreen := \033[1;32m

# run 'make' or 'make help' to get a list of available targets and their description
.PHONY: help
help:
	@echo ""
	@echo "================================================================="
	@printf "$(BGreen)Please use 'make <target>', where target is one of:-$(NC)\n"
	@echo "================================================================="
	@grep -E '^\.PHONY: [a-zA-Z_-]+ .*?## .*$$' $(MAKEFILE_LIST)  | awk 'BEGIN {FS = "(: |##)"}; {printf "\033[36m%-42s\033[0m %s\n", $$2, $$3}'
	@echo ""
	@echo "================================================================="
	@printf "$(BGreen)Variables available for override:-$(NC)\n"		
	@echo "================================================================="
	@printf "$(BLUE)SKIP_TESTS$(NC)             Skips Tests. The Default value is '$(SKIP_TESTS)'\n"
	@printf "$(BLUE)BUILD_FLAGS$(NC)            Additional maven build flags. By Default, it doesn't pass any additional flags.\n"
	@printf "$(BLUE)IMAGE_REPO$(NC)             Image Repository of the image. Default is '$(IMAGE_REPO)'\n"
	@printf "$(BLUE)IMAGE_TAG$(NC)              Image tag. Default is '$(IMAGE_TAG)'\n"
	@printf "$(BLUE)IMAGE_PLATFORMS$(NC)        Supported Platforms for Multi-arch Images. Default platforms are '$(IMAGE_PLATFORMS)'\n"
	@printf "$(BLUE)DOCKERFILE_LOCATION$(NC)    Path to the dockerfile. Default is '$(DOCKERFILE_LOCATION)'\n"
	@printf "$(BLUE)DOCKER_BUILD_WORKSPACE$(NC) Image build workspace. Default is '$(DOCKER_BUILD_WORKSPACE)'\n"
	@echo ""



.PHONY: build-all ## Builds and test all modules. Variables available for override [SKIP_TESTS, BUILD_FLAGS]
build-all:
	@echo "----------------------------------------------------------------------"
	@echo "                   Building All Modules                               "
	@echo "----------------------------------------------------------------------"
	./mvnw clean install -Pprod -Psql -Pkafkasql -Pmultitenancy -DskipTests=$(SKIP_TESTS) $(BUILD_FLAGS)

.PHONY: build-sql-native ## Builds sql storage variant native executable. Variables available for override [SKIP_TESTS, BUILD_FLAGS]
build-sql-native:
	@echo "----------------------------------------------------------------------"
	@echo "             Building SQL Storage Variant Natively                    "
	@echo "----------------------------------------------------------------------"
	./mvnw package -Pnative -Dquarkus.native.container-build=true -Pprod -Psql -pl storage/sql -DskipTests=$(SKIP_TESTS) $(BUILD_FLAGS)

.PHONY: build-kafkasql-native ## Builds kafkasql storage variant native executable. Variables available for override [SKIP_TESTS, BUILD_FLAGS]
build-kafkasql-native:
	@echo "----------------------------------------------------------------------"
	@echo "             Building Kafkasql Storage Variant Natively               "
	@echo "----------------------------------------------------------------------"
	./mvnw package -Pnative -Dquarkus.native.container-build=true -Pprod -Pkafkasql -pl storage/kafkasql -DskipTests=$(SKIP_TESTS) $(BUILD_FLAGS)

.PHONY: build-tenant-manager-native ## Builds tenant manager natively [SKIP_TESTS, BUILD_FLAGS]
build-tenant-manager-native:
	@echo "----------------------------------------------------------------------"
	@echo "                Building Tenant Manager Natively                      "
	@echo "----------------------------------------------------------------------"
	./mvnw package -Pnative -Dquarkus.native.container-build=true -Pprod -Pmultitenancy -pl 'multitenancy/tenant-manager-api' -DskipTests=$(SKIP_TESTS) $(BUILD_FLAGS)



.PHONY: build-mem-image ## Builds docker image for 'in-memory' storage variant. Variables available for override [MEM_DOCKERFILE, IMAGE_REPO, IMAGE_TAG, DOCKER_BUILD_WORKSPACE]
build-mem-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Image For In-Memory Storage Variant"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f $(DOCKERFILE_LOCATION)/$(MEM_DOCKERFILE) -t $(IMAGE_REPO)/apicurio/apicurio-registry-mem:$(IMAGE_TAG) $(DOCKER_BUILD_WORKSPACE)


.PHONY: push-mem-image ## Pushes docker image for 'in-memory' storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-mem-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Image For In-Memory Storage Variant"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-mem:$(IMAGE_TAG)



.PHONY: build-sql-image ## Builds docker image for 'sql' storage variant. Variables available for override [SQL_DOCKERFILE, IMAGE_REPO, IMAGE_TAG, DOCKER_BUILD_WORKSPACE]
build-sql-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Image For SQL Storage Variant "
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f $(DOCKERFILE_LOCATION)/$(SQL_DOCKERFILE) -t $(IMAGE_REPO)/apicurio/apicurio-registry-sql:$(IMAGE_TAG) $(DOCKER_BUILD_WORKSPACE)

.PHONY: push-sql-image ## Pushes docker image for 'sql' storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-sql-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Image For SQL Storage Variant"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-sql:$(IMAGE_TAG)

.PHONY: build-sql-native-image ## Builds native docker image for 'sql' storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
build-sql-native-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Image For SQL Storage Variant (using Native Executable)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f $(DOCKERFILE_LOCATION)/Dockerfile.native -t $(IMAGE_REPO)/apicurio/apicurio-registry-sql-native:$(IMAGE_TAG) storage/sql

.PHONY: push-sql-native-image ## Pushes native docker image for 'sql' storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-sql-native-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Image For SQL Storage Variant (using Native Executable)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-sql-native:$(IMAGE_TAG)

.PHONY: build-kafkasql-image ## Builds docker image for kafkasql storage variant. Variables available for override [KAFKASQL_DOCKERFILE, IMAGE_REPO, IMAGE_TAG, DOCKER_BUILD_WORKSPACE]
build-kafkasql-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Image For Kafkasql Storage Variant "
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f $(DOCKERFILE_LOCATION)/$(KAFKASQL_DOCKERFILE) -t $(IMAGE_REPO)/apicurio/apicurio-registry-kafkasql:$(IMAGE_TAG) $(DOCKER_BUILD_WORKSPACE)


.PHONY: push-kafkasql-image ## Pushes docker image for 'kafkasql' storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-kafkasql-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Image For Kafkasql Storage Variant"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-kafkasql:$(IMAGE_TAG)

.PHONY: build-kafkasql-native-image ## Builds native docker image for kafkasql storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
build-kafkasql-native-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Image For Kafkasql Storage Variant (using Native Executable)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f $(DOCKERFILE_LOCATION)/Dockerfile.native -t $(IMAGE_REPO)/apicurio/apicurio-registry-kafkasql-native:$(IMAGE_TAG) storage/kafkasql


.PHONY: push-kafkasql-native-image ## Pushes native docker image for 'kafkasql' storage variant. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-kafkasql-native-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Image For Kafkasql Storage Variant (using Native Executable)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-kafkasql-native:$(IMAGE_TAG)


.PHONY: build-tenant-manager-image ## Builds docker image for tenant manager. Variables available for override [IMAGE_REPO, IMAGE_TAG]
build-tenant-manager-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Image For Tenant Manager API"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f multitenancy/tenant-manager-api/src/main/docker/Dockerfile.jvm -t $(IMAGE_REPO)/apicurio/apicurio-registry-tenant-manager-api:$(IMAGE_TAG) ./multitenancy/tenant-manager-api/


.PHONY: push-tenant-manager-image ## Pushes docker image for tenant-manager-api. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-tenant-manager-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Image For Tenant Manager API"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-tenant-manager-api:$(IMAGE_TAG)

.PHONY: build-tenant-manager-native-image ## Builds native docker image for tenant manager. Variables available for override [IMAGE_REPO, IMAGE_TAG]
build-tenant-manager-native-image:
	@echo "------------------------------------------------------------------------"
	@echo " Building Native Image For Tenant Manager API"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker build -f multitenancy/tenant-manager-api/src/main/docker/Dockerfile.native -t $(IMAGE_REPO)/apicurio/apicurio-registry-tenant-manager-api-native:$(IMAGE_TAG) ./multitenancy/tenant-manager-api/


.PHONY: push-tenant-manager-native-image ## Pushes native docker image for tenant-manager-api. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-tenant-manager-native-image:
	@echo "------------------------------------------------------------------------"
	@echo " Pushing Native Image For Tenant Manager API"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker push $(IMAGE_REPO)/apicurio/apicurio-registry-tenant-manager-api-native:$(IMAGE_TAG)



.PHONY: build-all-images ## Builds all the Images. Variables available for override [IMAGE_REPO, IMAGE_TAG]
build-all-images: build-mem-image build-sql-image build-kafkasql-image build-tenant-manager-image

.PHONY: push-all-images ## Pushes all the Images. Variables available for override [IMAGE_REPO, IMAGE_TAG]
push-all-images: push-mem-image push-sql-image push-kafkasql-image push-tenant-manager-image


.PHONY: mem-multiarch-images ## Builds and pushes multi-arch images for 'in-memory' storage variant. Variables available for override [MEM_DOCKERFILE, IMAGE_REPO, IMAGE_TAG, DOCKER_BUILD_WORKSPACE]
mem-multiarch-images:
	@echo "------------------------------------------------------------------------"
	@echo " Building Multi-arch Images For In-Memory Storage Variant"
	@echo " Supported Platforms: $(IMAGE_PLATFORMS)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker buildx build --push -f $(DOCKERFILE_LOCATION)/$(MEM_DOCKERFILE) -t $(IMAGE_REPO)/apicurio/apicurio-registry-mem:$(IMAGE_TAG) --platform $(IMAGE_PLATFORMS) $(DOCKER_BUILD_WORKSPACE)


.PHONY: sql-multiarch-images ## Builds and pushes multi-arch images for 'sql' storage variant. Variables available for override [SQL_DOCKERFILE, IMAGE_REPO, IMAGE_TAG, DOCKER_BUILD_WORKSPACE]
sql-multiarch-images:
	@echo "------------------------------------------------------------------------"
	@echo " Building Multi-arch Images For SQL Storage Variant "
	@echo " Supported Platforms: $(IMAGE_PLATFORMS)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker buildx build --push -f $(DOCKERFILE_LOCATION)/$(SQL_DOCKERFILE) -t $(IMAGE_REPO)/apicurio/apicurio-registry-sql:$(IMAGE_TAG) --platform $(IMAGE_PLATFORMS) $(DOCKER_BUILD_WORKSPACE)


.PHONY: kafkasql-multiarch-images ## Builds and pushes multi-arch images for kafkasql storage variant. Variables available for override [KAFKASQL_DOCKERFILE, IMAGE_REPO, IMAGE_TAG, DOCKER_BUILD_WORKSPACE]
kafkasql-multiarch-images:
	@echo "------------------------------------------------------------------------"
	@echo " Building Multi-arch Images For Kafkasql Storage Variant "
	@echo " Supported Platforms: $(IMAGE_PLATFORMS)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker buildx build --push -f $(DOCKERFILE_LOCATION)/$(KAFKASQL_DOCKERFILE) -t $(IMAGE_REPO)/apicurio/apicurio-registry-kafkasql:$(IMAGE_TAG) --platform $(IMAGE_PLATFORMS) $(DOCKER_BUILD_WORKSPACE)


.PHONY: tenant-manager-multiarch-images ## Builds and pushes multi-arch images for tenant manager. Variables available for override [IMAGE_REPO, IMAGE_TAG]
tenant-manager-multiarch-images:
	@echo "------------------------------------------------------------------------"
	@echo " Building Multi-arch Images For Tenant Manager API"
	@echo " Supported Platforms: $(IMAGE_PLATFORMS)"
	@echo " Repository: $(IMAGE_REPO)"
	@echo " Tag: $(IMAGE_TAG)"
	@echo "------------------------------------------------------------------------"
	docker buildx build --push -f multitenancy/tenant-manager-api/src/main/docker/Dockerfile.jvm -t $(IMAGE_REPO)/apicurio/apicurio-registry-tenant-manager-api:$(IMAGE_TAG) --platform $(IMAGE_PLATFORMS) ./multitenancy/tenant-manager-api/


.PHONY: multiarch-registry-images ## Builds and pushes multi-arch registry images for all variants. Variables available for override [IMAGE_REPO, IMAGE_TAG]
multiarch-registry-images: mem-multiarch-images sql-multiarch-images kafkasql-multiarch-images tenant-manager-multiarch-images





.PHONY: pr-check ## Builds and runs basic tests for multitenant registry pipelines
pr-check:
	CURRENT_ENV=mas mvn clean install -Pno-docker -Dskip.yarn -Pprod -Psql -Pmultitenancy -am -pl storage/sql,multitenancy/tenant-manager-api \
		-Dmaven.javadoc.skip=true --no-transfer-progress -DtrimStackTrace=false
	./scripts/clean-postgres.sh
	CURRENT_ENV=mas NO_DOCKER=true mvn verify -Pintegration-tests -Pmultitenancy -Psql -am -pl integration-tests/testsuite \
		-Dmaven.javadoc.skip=true --no-transfer-progress -DtrimStackTrace=false

.PHONY: build-project ## Builds the components for multitenant registry pipelines
build-project:
# run unit tests for app module
	CURRENT_ENV=mas mvn clean install -Pno-docker -Dskip.yarn -Pprod -Psql -Pmultitenancy -am -pl app -Dmaven.javadoc.skip=true --no-transfer-progress -DtrimStackTrace=false
# build everything without running tests in order to be able to build container images
	CURRENT_ENV=mas mvn clean install -Pprod -Pno-docker -Dskip.yarn -Psql -Pmultitenancy -Dmaven.javadoc.skip=true --no-transfer-progress -DtrimStackTrace=false -DskipTests

.PHONY: build-integration-tests-common ## Builds integration-tests-common
build-integration-tests-common:
	@echo "----------------------------------------------------------------------"
	@echo "                 Building Integration Tests Common                    "
	@echo "----------------------------------------------------------------------"
	./mvnw install -Pintegration-tests -pl integration-tests/integration-tests-common

.PHONY: run-ui-tests ## Runs sql integration tests
run-ui-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                         Running UI Tests                             "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pui -Pinmemory -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress -DtrimStackTrace=false

.PHONY: run-sql-integration-tests ## Runs sql integration tests
run-sql-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                 Running Sql Integration Tests                        "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -P$(INTEGRATION_TESTS_PROFILE) -Psql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-sql-clustered-integration-tests ## Runs sql clustered integration tests
run-sql-clustered-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "               Running Sql clustered Integration Tests                "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pclustered -Psql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-kafkasql-integration-tests ## Runs kafkasql integration tests
run-kafkasql-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                 Running KafkaSql Integration Tests                        "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -P$(INTEGRATION_TESTS_PROFILE) -Pkafkasql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-kafkasql-clustered-integration-tests ## Runs kafkasql clustered integration tests
run-kafkasql-clustered-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "               Running KafkaSql clustered Integration Tests                "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pclustered -Pkafkasql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-multitenancy-integration-tests ## Runs multitenancy integration tests
run-multitenancy-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "               Running Multitenancy Integration Tests                 "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pmultitenancy -Psql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress -DtrimStackTrace=false

.PHONY: run-sql-migration-integration-tests ## Runs sql migration integration tests
run-sql-migration-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "               Running SQL Migration Integration Tests                "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pmigration -Psql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-kafkasql-migration-integration-tests ## Runs kafkasql migration integration tests
run-kafkasql-migration-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "             Running KafkaSQL Migration Integration Tests             "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pmigration -Pkafkasql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-sql-auth-integration-tests ## Runs sql auth integration tests
run-sql-auth-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                  Running SQL Auth Integration Tests                  "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pauth -Psql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-kafkasql-auth-integration-tests ## Runs kafkasql auth integration tests
run-kafkasql-auth-integration-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                Running KafkaSQL Auth Integration Tests               "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -Pauth -Pkafkasql -pl integration-tests/testsuite -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-sql-legacy-tests ## Runs sql legacy tests
run-sql-legacy-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                        Running SQL Legacy Tests                      "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -P$(INTEGRATION_TESTS_PROFILE) -Pkafkasql -pl integration-tests/legacy-tests -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: run-kafkasql-legacy-tests ## Runs kafkasql legacy tests
run-kafkasql-legacy-tests: build-integration-tests-common
	@echo "----------------------------------------------------------------------"
	@echo "                     Running KafkaSQL Legacy Tests                    "
	@echo "----------------------------------------------------------------------"
	./mvnw verify -Pintegration-tests -P$(INTEGRATION_TESTS_PROFILE) -Psql -pl integration-tests/legacy-tests -Dmaven.javadoc.skip=true --no-transfer-progress

.PHONY: integration-tests ## Runs all integration tests [SKIP_TESTS, BUILD_FLAGS]
integration-tests: build-all build-integration-tests-common run-ui-tests run-sql-integration-tests run-sql-clustered-integration-tests run-kafkasql-integration-tests run-kafkasql-clustered-integration-tests run-multitenancy-integration-tests run-sql-migration-integration-tests run-kafkasql-migration-integration-tests run-sql-auth-integration-tests run-kafkasql-auth-integration-tests run-sql-legacy-tests run-kafkasql-legacy-tests

# Please declare your targets as .PHONY in the format shown below, so that the 'make help' parses the information correctly.
#
# .PHONY: <target-name>  ## Description of what target does
