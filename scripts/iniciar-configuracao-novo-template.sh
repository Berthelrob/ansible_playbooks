#!/bin/bash

echo ""
echo "ATENCAO!!"
echo "Certifique-se de que o IP da nova máquina foi configurado como sendo 10.150.2.34"
echo "Certifique-se de que foi criado o usuário ansible e inserido a chave pública no arquivo /home/ansible/.ssh/authorized_keys"
echo "Certifique-se de que foram dadas as devidas permissões aos arquivos e pastas:"
echo ""
echo "chmod 700 /home/ansible/.ssh"
echo "chmod 600 /home/ansible/.ssh/authorized_keys"
echo ""

# Pergunta ao usuário se deseja continuar a configuração
read -p "Deseja continuar a configuração? (S/N): " choice
if [[ $choice != "S" && $choice != "s" ]]; then
    echo "Configuração cancelada."
    exit 0
fi

# Executa o playbook do Ansible
        ansible-playbook -i /home/ansible/ansible-files-linux/linux-inventory.ini /home/ansible/ansible-files-linux/playbook-configurar-novo-template/configurar-novo-template.yml --ask-vault-pass

