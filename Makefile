INVENTORY ?= inventory.ini

#
# Python environment
#

.venv:
	python3 -m venv $@

.PHONY: python-setup
python-setup: .venv
	. .venv/bin/activate \
		&& pip install --upgrade pip \
		&& pip install -r requirements.txt \
		&& ansible-galaxy collection install -r requirements.yml

#
# Targets
#
.PHONY: setup-all
setup-all: .venv
	. .venv/bin/activate && \
		ansible-playbook -i $(INVENTORY) playbook.yml \
		--vault-password-file vault_pwd.txt  -v

.PHONY: setup-from-images-onwards
setup-from-images-onwards: .venv
	. .venv/bin/activate && \
		ansible-playbook -i $(INVENTORY) playbook.yml\
		--vault-password-file vault_pwd.txt -v	\
		--start-at-task='Create /opt/container-images'

.PHONY: setup-from-service-onwards
setup-from-service-onwards: .venv
	. .venv/bin/activate && \
		ansible-playbook -i $(INVENTORY) playbook.yml \
		--vault-password-file vault_pwd.txt -v	\
		--start-at-task='Repull images'

.PHONY: cert
cert: .venv
	. ..venv/bin/activate && \
		ansible-playbook -i $(INVENTORY) playbook.yml \
		--vault-password-file vault_pwd.txt -v	\
		--tags=self-signed-cert
