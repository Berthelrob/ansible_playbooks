#!/bin/bash

# Início da contagem de tempo
start_time=$(date +%s)

# Variaveis
ansible="/home/ansible/ansible-files-linux"
ansible_playbook="$ansible/playbook-configurar-nova-vm-a-partir-template"
vars_file_gnome="$ansible_playbook/configurar-nova-vm-com-gnome/vars/main.yml"

# Função para solicitar um valor do usuário
prompt_value() {
    local prompt="$1"
    local default_value="$2"
    local value

    read -p "$prompt" value

    # Se nenhum valor for fornecido, usar o valor padrão
    if [ -z "$value" ]; then
        value="$default_value"
    fi

    echo "$value"
}

echo "Informe o nome da maquina que vai ser instalado o ambiente grafico."
nova_maquina=$(prompt_value "Nome da maquina: " )

# Atualizar as variáveis no arquivo
sed -i "s/^nova_maquina:.*/nova_maquina: \"$nova_maquina\"/" "$vars_file_gnome"

# Configura nova maquina com ou sem interface grafica
echo "Iniciando configuracao via playbook..."
ansible-playbook -i $ansible/linux-inventory.ini $ansible_playbook/configurar-nova-vm-com-gnome.yml -l $nova_maquina

echo ""
echo "ATENCAO!!"
echo "Instalado e configurado ambiente grafico com sucesso."
echo "Abra um chamado para a infosafe cadastrar o X11 para acesso via cofre."
echo ""

# Fim da contagem de tempo
end_time=$(date +%s)

# Cálculo do tempo de execução em segundos
execution_time=$((end_time - start_time))

# Imprimir o tempo de execução
echo "Tempo total da execucao do script: $execution_time segundos"

#EOF
