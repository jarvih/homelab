TF ?= tofu

.PHONY: init fmt validate plan apply destroy

init:
	$(TF) init

fmt:
	$(TF) fmt

validate:
	$(TF) validate

plan:
	$(TF) plan

apply:
	$(TF) apply

destroy:
	$(TF) destroy
