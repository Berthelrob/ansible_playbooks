#!/bin/bash

# Início da contagem de tempo
start_time=$(date +%s)

# Variaveis
nome_maquina="template"
ip_padrao="10.150.15.211"
ansible="/home/ansible/ansible-files-linux"
ansible_playbook="$ansible/playbook-configurar-nova-vm-a-partir-template"
vars_file="$ansible_playbook/configurar-nova-vm/vars/main.yml"

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

# Atualizar as variáveis interativamente
echo "-----------------------"
echo "Configuração da Nova VM"
echo "-----------------------"

# Solicitar valores ao usuário
novo_hostname=$(prompt_value "Nome da maquina: " )
usuario_cofre=$novo_hostname.cofre
objetivo=$(prompt_value "Objetivo da nova maquina: ")
responsaveis=$(prompt_value "Responsáveis (exemplo: Responsavel01 <responsavel01@estacio.br> e Responsavel02 <responsavel02@estacio.br>): ")
ip_producao=$(prompt_value "IP de Producao + mascara da sub-rede (exemplo: 10.150.x.x/28): ")
ip_gateway_producao=$(prompt_value "IP Gateway de Producao (exemplo: 10.150.x.x): ")
mascara_gerencia="22"
ip_gerencia=$(prompt_value "IP de Gerência (exemplo: 10.230.x.x): ")

# Verifica o tipo de sistema operacional
comando_so="cat /etc/oracle-release || cat /etc/redhat-release || echo 'Tipo de SO desconhecido'"
tipo_so=$(ssh "ansible@$ip_padrao" "$comando_so")

if [[ $tipo_so == *"Red Hat"* ]]; then
    # Pergunta se a máquina é uma máquina SAP
    read -p "A máquina é uma máquina SAP? (S/N): " is_sap

    # Verifica a resposta e atribui o valor correto à variável
    if [[ $is_sap == [Ss]* ]]; then
        pool_id_rhel_subscription="8a82c49481811a8e0181ac59bdf40239"
    else
        pool_id_rhel_subscription="2c942b0683d72c500183f69cff2a20ba"
    fi
fi

# Atualizar as variáveis no arquivo
sed -i "s/^novo_hostname:.*/novo_hostname: \"$novo_hostname\"/" "$vars_file"
sed -i "s/^usuario_cofre:.*/usuario_cofre: \"$usuario_cofre\"/" "$vars_file"
sed -i "s/^pool_id_rhel_subscription:.*/pool_id_rhel_subscription: \"$pool_id_rhel_subscription\"/" "$vars_file"
sed -i "s/^objetivo:.*/objetivo: \"$objetivo\"/" "$vars_file"
sed -i "s/^responsaveis:.*/responsaveis: \"$responsaveis\"/" "$vars_file"
sed -i "s/^ip_producao:.*/ip_producao: \"$(sed 's/\//\\\//g' <<< "$ip_producao")\"/" "$vars_file"
sed -i "s/^ip_gateway_producao:.*/ip_gateway_producao: \"$ip_gateway_producao\"/" "$vars_file"
sed -i "s/^ip_gerencia:.*/ip_gerencia: \"${ip_gerencia}\/${mascara_gerencia}\"/" "$vars_file"
sed -i "s/^nome_maquina:.*/nome_maquina: \"$nome_maquina\"/" "$vars_file"

# Configura nova maquina com ou sem interface grafica
echo "Iniciando configuracao via playbook..."
read -p "Máquina tera interface grafica?? (S/N): " is_graph

if [[ $is_graph == [Nn]* ]]; then
    ansible-playbook -i $ansible/linux-inventory.ini $ansible_playbook/configurar-nova-vm.yml -l $nome_maquina --ask-vault-pass
else
    ansible-playbook -i $ansible/linux-inventory.ini $ansible_playbook/configurar-nova-vm.yml -l $nome_maquina --ask-vault-pass
    ansible-playbook -i $ansible/linux-inventory.ini $ansible_playbook/configurar-nova-vm-com-gnome.yml -l $nome_maquina
fi

# Aplica chave da trend micro
echo "Aplicando chave da Trend Micro...."
echo "Insira o password do Antivirus, aperte ENTER e insira novamente: "
ip_producao_sem_mascara="${ip_producao%/*}"
ssh ansible@$ip_producao_sem_mascara sudo mokutil --import /opt/ds_agent/*.der

# atualiza /etc/hosts
sudo cp -f /etc/hosts /etc/hosts.bkp
novo_hostname_entry="$ip_producao_sem_mascara\t$novo_hostname"
#sudo sed -i "/$novo_hostname/d" /etc/hosts
sudo bash -c "echo -e \"$novo_hostname_entry\" >> /etc/hosts"

# atualiza arquivo de invantario Ansible
bash -c "echo -e \"$novo_hostname\" >> $ansible/linux-inventory.ini"

# Informacoes gerais
echo ""
echo "--- OBSERVAÇÕES IMPORTANTES ---"
echo "- Abra um chamado via servicenow para YDUQS com as informações abaixo-"
echo "- Hostname: " $novo_hostname
echo "- IP de producao: " $ip_producao
echo "- Tipo de Dispositivo: Servidor"
echo "- Modelo: VM"
echo "- Fabricante: Cirion"
echo "- Conectividade (ssl22 Rdp 3389 etc): SSH"
echo "- Domínio (se houver): "
echo "- Sistema Operacional: $tipo_so"
echo "- Site/localidade: VMWARE-RJ" 
echo "- Dono do serviço e a qual equipe pertence: " $responsaveis
echo "- Usuario do cofre: " $usuario_cofre
echo "- Senha padrao do usuario do cofre: Mudar@123"
echo "- Precisa ter acesso ao X11 via cofre?" $is_graph
echo ""
echo "Outras atividades de finalização do servidor:"
echo "- Faça o cadastro da nova máquina no CMDB"
echo "- Adicione a VM no DR"
echo "- Atualize a VM na planilha de controle de maquinas"
echo "- Configure manualmente os discos e a memoria SWAP"
echo "- Abra um chamado para o Rodrigo adicionar a nova maquina no monitoramento da Cirion"
echo "- Adicione a nova maquina no cofre de senhas da Cirion"
echo "--- IP de gerencia:  $ip_gerencia "
echo "- Adicione a nova maquina no Zabbix da Certsys"
echo "- Altere a VLAN de producao da VM para a VLAN correta"
echo ""
echo "Configuração concluída!"
echo "Reinicie a máquina e acesse a maquina via terminal do vmware para aplicar as configuracoes da chave da TrendMicro"
echo ""

# Fim da contagem de tempo
end_time=$(date +%s)

# Cálculo do tempo de execução em segundos
execution_time=$((end_time - start_time))

# Imprimir o tempo de execução
echo "Tempo total da execucao do script: $execution_time segundos"

#EOF
