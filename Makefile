ENV       ?= lab
INVENTORY := inventories/$(ENV)/hosts.yml
VAULT     := $(if $(wildcard .vault_pass),--vault-password-file .vault_pass)
ANSIBLE   := ansible-playbook -i $(INVENTORY) $(VAULT)

.PHONY: deps lint syntax ping proxmox template vms site security ceph slurm monitoring rolling verify

deps:            ## Install Ansible collections
	ansible-galaxy collection install -r requirements.yml -p ./collections

lint:            ## yamllint + ansible-lint
	yamllint .
	ansible-lint

syntax:          ## Syntax-check every playbook
	for p in playbooks/*.yml; do $(ANSIBLE) --syntax-check $$p || exit 1; done

ping:
	ansible -i $(INVENTORY) all -m ansible.builtin.ping

proxmox:   ; $(ANSIBLE) playbooks/proxmox.yml
template:  ; $(ANSIBLE) playbooks/golden-image.yml
vms:       ; $(ANSIBLE) playbooks/provision-vms.yml
site:      ; $(ANSIBLE) playbooks/site.yml
security:  ; $(ANSIBLE) playbooks/security.yml
ceph:      ; $(ANSIBLE) playbooks/ceph.yml
slurm:     ; $(ANSIBLE) playbooks/slurm.yml
monitoring:; $(ANSIBLE) playbooks/monitoring.yml
rolling:   ; $(ANSIBLE) playbooks/rolling-update.yml
verify:    ; $(ANSIBLE) playbooks/verify.yml
